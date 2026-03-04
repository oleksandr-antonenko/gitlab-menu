import SwiftUI

struct PipelineListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Pipelines")
                    .font(.headline)
                Spacer()
                if appState.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Button {
                    appState.refreshNow()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(appState.isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Error banner
            if let error = appState.errorMessage {
                ErrorBannerView(message: error)
            }

            // Pipeline list
            if appState.pipelines.isEmpty && !appState.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No pipelines found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(appState.pipelines) { pipeline in
                            PipelineRowView(pipeline: pipeline)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    appState.selectedPipeline = pipeline
                                }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }

            Divider()

            // Footer
            HStack {
                if let lastRefresh = appState.lastRefresh {
                    Text("Updated \(TimeFormatting.relativeTime(from: lastRefresh))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()

                SettingsLink {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
