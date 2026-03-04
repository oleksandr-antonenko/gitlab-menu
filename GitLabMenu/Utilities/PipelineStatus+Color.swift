import SwiftUI

extension PipelineStatus {
    var color: Color {
        switch self {
        case .success:
            return .green
        case .failed:
            return .red
        case .running:
            return .blue
        case .pending, .waitingForResource, .preparing:
            return .orange
        case .canceled:
            return .gray
        case .skipped:
            return .secondary
        case .manual:
            return .purple
        case .scheduled:
            return .teal
        case .created:
            return .mint
        }
    }

    var sfSymbol: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .running:
            return "play.circle.fill"
        case .pending, .waitingForResource, .preparing:
            return "clock.fill"
        case .canceled:
            return "minus.circle.fill"
        case .skipped:
            return "forward.fill"
        case .manual:
            return "hand.raised.fill"
        case .scheduled:
            return "calendar.circle.fill"
        case .created:
            return "plus.circle.fill"
        }
    }

    /// Compact symbol for menu bar icon
    var menuBarSymbol: String {
        switch self {
        case .success:
            return "checkmark.diamond.fill"
        case .failed:
            return "xmark.diamond.fill"
        case .running:
            return "play.diamond.fill"
        case .pending, .waitingForResource, .preparing, .created:
            return "clock.diamond.fill"
        case .canceled, .skipped:
            return "minus.diamond.fill"
        case .manual:
            return "hand.raised.diamond.fill"
        case .scheduled:
            return "calendar.diamond.fill"
        }
    }

    var displayName: String {
        switch self {
        case .waitingForResource:
            return "waiting"
        default:
            return rawValue
        }
    }
}
