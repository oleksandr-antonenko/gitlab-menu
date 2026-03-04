import SwiftUI

struct StatusBadgeView: View {
    let status: PipelineStatus

    var body: some View {
        Image(systemName: status.sfSymbol)
            .foregroundStyle(status.color)
            .font(.caption)
    }
}
