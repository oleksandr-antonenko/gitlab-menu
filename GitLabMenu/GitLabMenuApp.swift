import SwiftUI

@main
struct GitLabMenuApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(appState)
                .onAppear {
                    appState.markFailuresAsSeen()
                }
        } label: {
            MenuBarIcon(status: appState.worstStatus, hasUnseenFailures: appState.hasUnseenFailures)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
