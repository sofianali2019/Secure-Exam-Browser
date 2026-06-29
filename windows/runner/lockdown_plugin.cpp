#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <map>
#include <string>
#include <sstream>

// WDA_EXCLUDEFROMCAPTURE is available on Windows 10 2004+ (build 19041+)
// Define it manually for compatibility with older SDKs.
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodChannel;
using flutter::MethodResult;

class LockdownPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LockdownPlugin(flutter::PluginRegistrarWindows *registrar);
  virtual ~LockdownPlugin();

 private:
  void HandleMethodCall(const MethodCall<EncodableValue> &method_call,
                        std::unique_ptr<MethodResult<EncodableValue>> result);

  void StartLockdown(const EncodableMap &args);
  void StopLockdown();

  flutter::PluginRegistrarWindows *registrar_;
  HHOOK keyboard_hook_ = nullptr;
  HHOOK mouse_hook_ = nullptr;
  bool is_locked_ = false;
};

void LockdownPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<MethodChannel<EncodableValue>>(
      registrar->messenger(), "com.exambrowser/lockdown",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LockdownPlugin>(registrar);
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
}

LockdownPlugin::LockdownPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

LockdownPlugin::~LockdownPlugin() {
  StopLockdown();
}

static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION) {
    auto *kbd = reinterpret_cast<KBDLLHOOKSTRUCT *>(lParam);
    bool alt = (kbd->flags & LLKHF_ALTDOWN) != 0;
    bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;

    // Block Alt+F4, Alt+Tab, Alt+Esc
    if (alt && (kbd->vkCode == VK_F4 || kbd->vkCode == VK_TAB || kbd->vkCode == VK_ESCAPE))
      return 1;

    // Block Ctrl+Shift+Esc (Task Manager)
    if (ctrl && kbd->vkCode == VK_ESCAPE) return 1;

    // Block Windows key
    if (kbd->vkCode == VK_LWIN || kbd->vkCode == VK_RWIN) return 1;

    // Block Ctrl+Alt+Del
    if (ctrl && alt && kbd->vkCode == VK_DELETE) return 1;

    // Block Print Screen
    if (kbd->vkCode == VK_SNAPSHOT) return 1;

    // Block Alt+Enter (fullscreen toggle)
    if (alt && kbd->vkCode == VK_RETURN) return 1;

    // Block Ctrl+C, Ctrl+V, Ctrl+P, Ctrl+S, Ctrl+N
    if (ctrl) {
      switch (kbd->vkCode) {
        case 'C': case 'V': case 'P': case 'S': case 'N':
        case 'X': case 'A': case 'Z': case 'F':
          return 1;
      }
    }

    // Block F1-F12
    if (kbd->vkCode >= VK_F1 && kbd->vkCode <= VK_F12) return 1;
  }
  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION) {
    // Block right-click, middle-click, X-button (back/forward), and mouse wheel
    switch (wParam) {
      case WM_RBUTTONDOWN:
      case WM_RBUTTONUP:
      case WM_MBUTTONDOWN:
      case WM_MBUTTONUP:
      case WM_XBUTTONDOWN:
      case WM_XBUTTONUP:
      case WM_MOUSEWHEEL:
        return 1;
    }
  }
  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

void LockdownPlugin::StartLockdown(const EncodableMap &args) {
  HWND hwnd = GetActiveWindow();
  if (!hwnd) hwnd = GetForegroundWindow();
  if (!hwnd) return;

  is_locked_ = true;

  BOOL fullscreen = TRUE;
  auto it = args.find(EncodableValue("fullscreenOnly"));
  if (it != args.end() && std::holds_alternative<bool>(it->second)) {
    fullscreen = std::get<bool>(it->second) ? TRUE : FALSE;
  }

  if (fullscreen) {
    SetWindowLong(hwnd, GWL_STYLE,
                  GetWindowLong(hwnd, GWL_STYLE) & ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU));
    ShowWindow(hwnd, SW_MAXIMIZE);
    MONITORINFO mi = { sizeof(mi) };
    if (GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY), &mi)) {
      SetWindowPos(hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
                   mi.rcMonitor.right - mi.rcMonitor.left,
                   mi.rcMonitor.bottom - mi.rcMonitor.top,
                   SWP_NOZORDER | SWP_NOACTIVATE);
    }
  }

  BOOL block_screenshots = TRUE;
  auto sit = args.find(EncodableValue("blockScreenshots"));
  if (sit != args.end() && std::holds_alternative<bool>(sit->second)) {
    block_screenshots = std::get<bool>(sit->second) ? TRUE : FALSE;
  }
  if (block_screenshots) {
    // Try the stronger WDA_EXCLUDEFROMCAPTURE first (Win 10 2004+),
    // which prevents capture even at the monitor level. Fall back to
    // WDA_MONITOR on older systems.
    if (!SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)) {
      SetWindowDisplayAffinity(hwnd, WDA_MONITOR);
    }
  }

  keyboard_hook_ = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, GetModuleHandle(nullptr), 0);
  mouse_hook_ = SetWindowsHookEx(WH_MOUSE_LL, LowLevelMouseProc, GetModuleHandle(nullptr), 0);
}

void LockdownPlugin::StopLockdown() {
  is_locked_ = false;

  HWND hwnd = GetActiveWindow();
  if (hwnd) {
    SetWindowDisplayAffinity(hwnd, WDA_NONE);
    SetWindowLong(hwnd, GWL_STYLE,
                  GetWindowLong(hwnd, GWL_STYLE) |
                  WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    ShowWindow(hwnd, SW_RESTORE);
  }

  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
  if (mouse_hook_) {
    UnhookWindowsHookEx(mouse_hook_);
    mouse_hook_ = nullptr;
  }
}

void LockdownPlugin::HandleMethodCall(
    const MethodCall<EncodableValue> &method_call,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  const auto &method = method_call.method_name();

  if (method == "startLockdown") {
    const auto *args = std::get_if<EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Missing config");
      return;
    }
    try {
      StartLockdown(*args);
      is_locked_ = true;
      result->Success(EncodableValue(true));
    } catch (const std::exception &e) {
      is_locked_ = false;
      result->Error("LOCKDOWN_FAILED", e.what());
    }
  } else if (method == "stopLockdown") {
    try {
      StopLockdown();
    } catch (...) {
      // Best-effort cleanup
    }
    is_locked_ = false;
    result->Success(EncodableValue(true));
  } else if (method == "isInLockdown") {
    result->Success(EncodableValue(is_locked_));
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void LockdownPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  LockdownPlugin::RegisterWithRegistrar(
      new flutter::PluginRegistrarWindows(registrar));
}
