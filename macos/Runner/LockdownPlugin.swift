import Flutter
import Cocoa
import Carbon

public class LockdownPlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?
    private var isLocked = false
    private var eventMonitor: Any?
    private var localMonitor: Any?
    private var screenshotObserver: Any?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.exambrowser/lockdown", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "com.exambrowser/lockdown_events", binaryMessenger: registrar.messenger)
        let instance = LockdownPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startLockdown":
            startLockdown(call: call, result: result)
        case "stopLockdown":
            stopLockdown(result: result)
        case "isInLockdown":
            result(isLocked)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startLockdown(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing config", details: nil))
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(FlutterError(code: "NO_PLUGIN", message: "Plugin deallocated", details: nil))
                return
            }
            self.applyLockdown(args: args)
            self.isLocked = true
            result(true)
        }
    }

    private func stopLockdown(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(true)
                return
            }
            self.removeLockdown()
            self.isLocked = false
            result(true)
        }
    }

    private func applyLockdown(args: [String: Any]) {
        guard let window = NSApplication.shared.mainWindow ?? NSApplication.shared.windows.first else { return }

        if args["fullscreenOnly"] as? Bool ?? true {
            NSApplication.shared.presentationOptions = [
                .autoHideMenuBar,
                .autoHideDock,
                .disableForceQuit,
                .disableMenuBarTransparency,
                .fullScreen,
                .hideDock,
                .hideMenuBar,
            ]
            window.toggleFullScreen(nil)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            return self?.handleKeyEvent(event) ?? event
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            _ = self?.handleKeyEvent(event)
        }

        if args["blockScreenshots"] as? Bool ?? true {
            NSSound.systemVolumeFactor = 0

            // Observe screenshot/screen-recording notifications via distributed notification center.
            // macOS posts com.apple.screenshot when Cmd+Shift+3/4/5 is used.
            screenshotObserver = DistributedNotificationCenter.default().addObserver(
                forName: NSNotification.Name("com.apple.screenshot"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.eventSink?(["type": "screenshot", "detail": "Screenshot detected"])
            }
        }
    }

    private func removeLockdown() {
        NSApplication.shared.presentationOptions = []

        if let observer = screenshotObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            screenshotObserver = nil
        }

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        guard let window = NSApplication.shared.mainWindow ?? NSApplication.shared.windows.first else { return }
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        if !isLocked { return event }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let cmd = flags.contains(.command)
        let option = flags.contains(.option)
        let control = flags.contains(.control)

        switch Int(event.keyCode) {
        case kVK_Tab where control:
            eventSink?(["type": "shortcut", "detail": "Control+Tab blocked"])
            return nil

        case kVK_ANSI_Q where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+Q blocked"])
            return nil

        case kVK_ANSI_H where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+H blocked"])
            return nil

        case kVK_ANSI_W where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+W blocked"])
            return nil

        case kVK_ANSI_C where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+C blocked"])
            return nil

        case kVK_ANSI_V where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+V blocked"])
            return nil

        case kVK_ANSI_P where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+P blocked"])
            return nil

        case kVK_ANSI_N where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+N blocked"])
            return nil

        case kVK_ANSI_S where cmd:
            eventSink?(["type": "shortcut", "detail": "Cmd+S blocked"])
            return nil

        case kVK_F1...kVK_F12:
            eventSink?(["type": "shortcut", "detail": "Function key blocked"])
            return nil

        default:
            break
        }

        if cmd && option {
            eventSink?(["type": "shortcut", "detail": "Cmd+Option blocked"])
            return nil
        }

        if event.type == .keyDown {
            if flags.contains(.command) {
                eventSink?(["type": "shortcut", "detail": "Cmd shortcut blocked"])
                return nil
            }
            if flags.rawValue & UInt(NX_DEVICELCMDKEYMASK) != 0 || flags.rawValue & UInt(NX_DEVICERCMDKEYMASK) != 0 {
                eventSink?(["type": "shortcut", "detail": "Command key blocked"])
                return nil
            }
        }

        return event
    }
}

extension LockdownPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
