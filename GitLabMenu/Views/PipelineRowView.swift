import SwiftUI

struct PipelineRowView: View {
    @Environment(AppState.self) private var appState
    let pipeline: EnrichedPipeline

    private var isWatched: Bool {
        appState.isWatched(pipelineId: pipeline.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top line: project name + actions
            HStack(alignment: .center, spacing: 6) {
                StatusBadgeView(status: pipeline.pipeline.status)

                Text(pipeline.project.pathWithNamespace)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // Branch tag
                Text(pipeline.pipeline.ref)
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .lineLimit(1)

                // Watch toggle (only for non-terminal pipelines)
                if !pipeline.pipeline.status.isTerminal {
                    Button {
                        appState.toggleWatch(pipelineId: pipeline.id)
                    } label: {
                        Image(systemName: isWatched ? "bell.fill" : "bell")
                            .font(.caption)
                            .foregroundStyle(isWatched ? .yellow : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(isWatched ? "Stop watching" : "Notify when finished")
                }

                // Open in browser
                Button {
                    if let url = URL(string: pipeline.pipeline.webUrl) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Open in GitLab")
            }

            // Bottom line: progress bar + stage name
            HStack(spacing: 6) {
                ProgressBarView(
                    completed: pipeline.completedStageCount,
                    total: pipeline.totalStageCount,
                    status: pipeline.pipeline.status
                )
                .frame(height: 4)

                if let stageName = pipeline.currentStageName {
                    Text(stageName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else if pipeline.pipeline.status == .success {
                    Text("done")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.clear)
        .contentShape(Rectangle())
    }
}
