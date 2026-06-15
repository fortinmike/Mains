import SwiftUI

enum PowerState: String, Sendable {
    case mains
    case ups
    case battery
    case unknown

    var title: String {
        switch self {
        case .mains:
            "Running on Mains Power"
        case .ups:
            "Running on UPS"
        case .battery:
            "Running on Battery"
        case .unknown:
            "Power Status Unavailable"
        }
    }

    var systemImage: String {
        switch self {
        case .mains:
            "powerplug.fill"
        case .ups, .battery:
            "battery.25percent"
        case .unknown:
            "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .mains:
            .green
        case .ups, .battery:
            .red
        case .unknown:
            .secondary
        }
    }
}
