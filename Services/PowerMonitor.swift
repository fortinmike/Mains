import Foundation
import IOKit.ps
import OSLog

private let logger = Logger(subsystem: "net.irradiated.Mains", category: "PowerMonitor")

@MainActor
final class PowerMonitor {
    var onUpdate: ((PowerState) -> Void)?

    private(set) var currentState = PowerState.unknown
    private var notificationSource: CFRunLoopSource?

    func start() -> PowerState {
        logger.info("Starting power state monitoring")

        currentState = readPowerState()
        logger.info("Initial power state: \(self.currentState.rawValue, privacy: .public)")

        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource(Self.callback, context)?
            .takeRetainedValue()
        else {
            logger.error("Failed to subscribe to IOKit power source notifications")
            return currentState
        }

        notificationSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        logger.info("Subscribed to IOKit power source notifications")
        return currentState
    }

    private func refresh() {
        let newState = readPowerState()
        guard newState != currentState else { return }

        let previousState = currentState
        currentState = newState
        logger.info(
            "Power state changed from \(previousState.rawValue, privacy: .public) to \(newState.rawValue, privacy: .public)"
        )
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
