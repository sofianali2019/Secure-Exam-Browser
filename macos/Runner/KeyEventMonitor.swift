import Cocoa
import Carbon

class KeyEventMonitor {
    private var monitors: [Any] = []

    func start(handler: @escaping (NSEvent) -> NSEvent?) {
        let local = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            return handler(event)
        }
        let global = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            _ = handler(event)
        }
        monitors = [local as Any, global as Any]
    }

    func stop() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors = []
    }

    deinit {
        stop()
    }
}
