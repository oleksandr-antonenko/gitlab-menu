# GitLab Menu

A native macOS menu bar app that shows your most recent GitLab CI/CD pipelines. Built with SwiftUI, no external dependencies beyond the system frameworks.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange)

## Features

- **Pipeline overview** — shows the 10 most recently updated pipelines across all your GitLab projects
- **Stage progress** — progress bars showing completed vs total stages, with current stage name
- **Job drill-down** — click a pipeline to see its jobs grouped by stage, with durations and status
- **Watch pipelines** — bell icon to subscribe to a running pipeline; get a macOS notification when it finishes
- **Failure alerts** — automatic notifications when a pipeline fails, red menu bar icon until you check it
- **15-second auto-refresh** — plus immediate refresh on system wake
- **Keychain storage** — GitLab URL and access token stored securely in macOS Keychain
- **No Dock icon** — runs purely in the menu bar

## Requirements

- macOS 14 (Sonoma) or later
- A GitLab instance (self-hosted or gitlab.com) with a personal access token (`read_api` scope)

## Install

1. Clone the repo and open in Xcode:
   ```
   git clone https://github.com/oleksandr-antonenko/gitlab-menu.git
   open gitlab-menu/GitLabMenu.xcodeproj
   ```
2. Build and run (Cmd+R)
3. Click the diamond icon in the menu bar → open Settings
4. Enter your GitLab URL and personal access token, click **Test Connection**, then **Save**

## GitLab Token

Generate a token at `https://your-gitlab.com/-/user_settings/personal_access_tokens` with the `read_api` scope.

## Architecture

```
GitLabMenu/
├── GitLabMenuApp.swift          — MenuBarExtra + Settings scenes
├── Models/
│   ├── Project.swift            — GitLab project model
│   ├── Pipeline.swift           — Pipeline, PipelineStatus, EnrichedPipeline
│   └── Job.swift                — Job model
├── Services/
│   ├── GitLabAPIClient.swift    — async/await API actor (projects, pipelines, jobs)
│   ├── KeychainService.swift    — secure credential storage
│   └── PipelinePoller.swift     — 15s polling actor with concurrent fetching
├── ViewModels/
│   └── AppState.swift           — @Observable single source of truth
├── Views/
│   ├── MenuBarContentView.swift — router: unconfigured → list → job drill-down
│   ├── PipelineListView.swift   — pipeline list with refresh and footer
│   ├── PipelineRowView.swift    — status, project, branch, progress, watch bell
│   ├── JobListView.swift        — jobs grouped by stage with back navigation
│   ├── JobRowView.swift         — job name, status, duration, browser link
│   ├── SettingsView.swift       — URL + token form with test connection
│   ├── MenuBarIcon.swift        — dynamic icon based on pipeline status
│   ├── StatusBadgeView.swift    — colored SF Symbol per status
│   ├── ProgressBarView.swift    — stage completion bar
│   └── ErrorBannerView.swift    — inline error display
└── Utilities/
    ├── PipelineStatus+Color.swift — status → color/symbol mapping
    ├── TimeFormatting.swift       — duration formatting (2m 34s)
    └── URL+GitLab.swift           — URL construction helpers
```

## License

MIT
