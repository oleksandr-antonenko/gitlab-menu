import SwiftUI

struct ProgressBarView: View {
    let completed: Int
    let total: Int
    let status: PipelineStatus

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(.quaternary)

                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(status.color)
                    .frame(width: max(0, geometry.size.width * progress))
            }
        }
    }
}
