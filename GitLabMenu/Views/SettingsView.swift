import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var url: String = ""
    @State private var token: String = ""
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("GitLab Instance") {
                TextField("GitLab URL", text: $url, prompt: Text("https://gitlab.example.com"))
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                SecureField("Personal Access Token", text: $token, prompt: Text("glpat-xxxxxxxxxxxxxxxxxxxx"))
                    .textFieldStyle(.roundedBorder)
            }

            Section {
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(url.isEmpty || token.isEmpty || isTesting)

                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                    }

                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.starts(with: "Connected") ? .green : .red)
                    }
                }
            }

            Section {
                HStack {
                    Button("Save") {
                        appState.gitlabURL = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                        appState.gitlabToken = token
                        appState.saveConfig()
                    }
                    .disabled(url.isEmpty || token.isEmpty)
                    .buttonStyle(.borderedProminent)

                    Button("Clear Credentials") {
                        url = ""
                        token = ""
                        testResult = nil
                        appState.clearConfig()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 280)
        .onAppear {
            url = appState.gitlabURL
            token = appState.gitlabToken
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        let trimmedURL = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let client = GitLabAPIClient(baseURL: trimmedURL, token: token)

        Task {
            do {
                let username = try await client.testConnection()
                await MainActor.run {
                    testResult = "Connected as @\(username)"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = error.localizedDescription
                    isTesting = false
                }
            }
        }
    }
}
