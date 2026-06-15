import Foundation
import IOKit.ps

@MainActor
final class PowerMonitor {
    var onUpdate: ((PowerState) -> Void)?

    private(set) var currentState = PowerState.unknown
    private var notificationSource: CFRunLoopSource?

    func start() -> PowerState {
        currentState = readPowerState()

        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource(Self.callback, context)?
            .takeRetainedValue()
        else {
            return currentState
        }

        notificationSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        return currentState
    }

    private func refresh() {
        let newState = readPowerState()
        guard newState != currentState else { return }

        currentState = newState
        onUpdate?(newState)
    }

    private func readPowerState() -> PowerState {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return .unknown
        }

        let source = IOPSGetProvidingPowerSourceType(snapshot).takeUnretainedValue() as String

        switch source {
        case kIOPMACPowerKey:
            return .mains
        case kIOPMUPSPowerKey:
            return .ups
        case kIOPMBatteryPowerKey:
            return .battery
        default:
            return .unknown
        }
    }

    private nonisolated(unsafe) static let callback: IOPowerSourceCallbackType = { context in
        guard let context else { return }

        let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
        // The source is installed on the main run loop
        MainActor.assumeIsolated {
            monitor.refresh()
        }
    }
}
