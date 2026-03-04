import SwiftUI

struct JobListView: View {
    @Environment(AppState.self) private var appState
    let pipeline: EnrichedPipeline

    private var jobsByStage: [(stage: String, jobs: [GitLabJob])] {
        pipeline.stages.map { stage in
            (stage: stage, jobs: pipeline.jobs.filter { $0.stage == stage })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    appState.selectedPipeline = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.borderless)

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(pipeline.project.pathWithNamespace)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(pipeline.pipeline.ref)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    if let url = URL(string: pipeline.pipeline.webUrl) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
                .help("Open pipeline in GitLab")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Jobs grouped by stage
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(jobsByStage, id: \.stage) { stageGroup in
                        // Stage header
                        HStack(spacing: 4) {
                            Text(stageGroup.stage.uppercased())
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary.opacity(0.5))

                        // Jobs in stage
                        ForEach(stageGroup.jobs) { job in
                            JobRowView(
                                job: job,
                                projectPath: pipeline.project.pathWithNamespace,
                                baseURL: appState.gitlabURL
                            )
                        }
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }
}
