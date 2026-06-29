import Flutter
import UIKit

public class LockdownPlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?
    private var screenCaptureObserver: NSObjectProtocol?
    private var isLocked = false
    private var secureTextField: UITextField?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.exambrowser/lockdown", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.exambrowser/lockdown_events", binaryMessenger: registrar.messenger())
        let instance = LockdownPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        instance.setupScreenCaptureDetection()
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
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else { return }
        UIApplication.shared.isIdleTimerDisabled = true

        if args["fullscreenOnly"] as? Bool ?? true {
            window.overrideUserInterfaceStyle = .dark
        }

        if args["blockNotifications"] as? Bool ?? true {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        if args["blockScreenshots"] as? Bool ?? true {
            let textField = UITextField()
            textField.isSecureTextEntry = true
            textField.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(textField)
            textField.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
            textField.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
            textField.isHidden = true
            secureTextField = textField
        }

        // Enable Guided Access (iOS kiosk mode) — prevents exiting the app
        // This must be enabled in Settings > Accessibility > Guided Access first.
        UIAccessibility.requestGuidedAccessSession(enabled: true) { [weak self] didSucceed in
            if !didSucceed {
                // Guided Access not enabled in Settings or not available on this device
                self?.eventSink?(["type": "guided_access_error", "detail": "Guided Access is not enabled. Please enable it in Settings > Accessibility > Guided Access."])
            }
        }
    }

    private func removeLockdown() {
        // Disable Guided Access
        UIAccessibility.requestGuidedAccessSession(enabled: false) { _ in }

        UIApplication.shared.isIdleTimerDisabled = false
        secureTextField?.removeFromSuperview()
        secureTextField = nil
    }

    private func setupScreenCaptureDetection() {
        screenCaptureObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if UIScreen.main.isCaptured {
                self?.eventSink?(["type": "screenshot", "detail": "Screen recording detected"])
            }
        }
    }

    deinit {
        if let observer = screenCaptureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        secureTextField?.removeFromSuperview()
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
