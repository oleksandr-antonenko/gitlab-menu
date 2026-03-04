import SwiftUI

struct JobRowView: View {
    let job: GitLabJob
    let projectPath: String
    let baseURL: String

    var body: some View {
        HStack(spacing: 6) {
            StatusBadgeView(status: job.status)
                .font(.caption)

            Text(job.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if let duration = job.duration {
                Text(TimeFormatting.formatDuration(duration))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            Button {
                if let url = URL(string: job.webUrl) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            .help("Open job in GitLab")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}
