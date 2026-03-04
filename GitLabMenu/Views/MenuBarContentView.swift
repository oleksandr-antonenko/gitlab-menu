import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            if !appState.isConfigured {
                UnconfiguredView()
            } else if let selected = appState.selectedPipeline {
                JobListView(pipeline: selected)
            } else {
                PipelineListView()
            }
        }
        .frame(width: 380)
    }
}

private struct UnconfiguredView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("GitLab Menu")
                .font(.headline)

            Text("Configure your GitLab instance to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SettingsLink {
                Text("Open Settings…")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
