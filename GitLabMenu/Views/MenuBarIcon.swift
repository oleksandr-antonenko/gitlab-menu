import SwiftUI

struct MenuBarIcon: View {
    let status: PipelineStatus?
    let hasUnseenFailures: Bool

    var body: some View {
        Image(systemName: symbolName)
    }

    private var symbolName: String {
        // Show red failure icon if there are unseen failures
        if hasUnseenFailures {
            return "xmark.diamond.fill"
        }

        guard let status else {
            return "cube"
        }

        switch status {
        case .success:
            return "checkmark.diamond.fill"
        case .failed:
            return "xmark.diamond.fill"
        case .running, .pending, .preparing, .waitingForResource, .created:
            return "play.diamond.fill"
        case .canceled, .skipped:
            return "minus.diamond.fill"
        case .manual:
            return "hand.raised.fill"
        case .scheduled:
            return "calendar"
        }
    }
}
