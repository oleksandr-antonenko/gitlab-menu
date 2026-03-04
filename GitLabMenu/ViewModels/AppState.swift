import Foundation
import SwiftUI
import UserNotifications

@Observable
@MainActor
final class AppState {
    // MARK: - Configuration
    var gitlabURL: String = ""
    var gitlabToken: String = ""
    var isConfigured: Bool { !gitlabURL.isEmpty && !gitlabToken.isEmpty }

    // MARK: - Pipeline Data
    var pipelines: [EnrichedPipeline] = []
    var lastRefresh: Date?
    var errorMessage: String?
    var isLoading = false

    // MARK: - Unseen Failures
    /// Pipeline IDs that failed and haven't been viewed yet
    var unseenFailedPipelineIds: Set<Int> = []
    var hasUnseenFailures: Bool { !unseenFailedPipelineIds.isEmpty }

    // MARK: - Watched Pipelines
    /// Pipeline IDs the user subscribed to — notify when they reach a terminal status
    var watchedPipelineIds: Set<Int> = []

    // MARK: - Navigation
    var selectedPipeline: EnrichedPipeline?

    // MARK: - Poller
    private var poller: PipelinePoller?
    private var wakeObserver: NSObjectProtocol?

    /// Track previously known pipeline statuses to detect new failures
    private var previousStatuses: [Int: PipelineStatus] = [:]

    // MARK: - Worst Status (for menu bar icon)
    var worstStatus: PipelineStatus? {
        pipelines.map(\.pipeline.status).max(by: { $0.severity < $1.severity })
    }

    init() {
        requestNotificationPermission()
        loadConfig()
    }

    // MARK: - Config Management

    func loadConfig() {
        gitlabURL = KeychainService.loadURL() ?? ""
        gitlabToken = KeychainService.loadToken() ?? ""

        if isConfigured {
            startPolling()
        }
    }

    func saveConfig() {
        do {
            try KeychainService.saveURL(gitlabURL)
            try KeychainService.saveToken(gitlabToken)
            startPolling()
        } catch {
            errorMessage = "Failed to save credentials: \(error.localizedDescription)"
        }
    }

    func clearConfig() {
        KeychainService.deleteURL()
        KeychainService.deleteToken()
        gitlabURL = ""
        gitlabToken = ""
        pipelines = []
        unseenFailedPipelineIds = []
        previousStatuses = [:]
        stopPolling()
    }

    // MARK: - Unseen Failures

    /// Mark all current failures as seen (called when user opens the menu)
    func markFailuresAsSeen() {
        unseenFailedPipelineIds = []
    }

    // MARK: - Watched Pipelines

    func toggleWatch(pipelineId: Int) {
        if watchedPipelineIds.contains(pipelineId) {
            watchedPipelineIds.remove(pipelineId)
        } else {
            watchedPipelineIds.insert(pipelineId)
        }
    }

    func isWatched(pipelineId: Int) -> Bool {
        watchedPipelineIds.contains(pipelineId)
    }

    private func checkWatchedPipelines(_ newPipelines: [EnrichedPipeline]) {
        for pipeline in newPipelines {
            guard watchedPipelineIds.contains(pipeline.id) else { continue }
            let previousStatus = previousStatuses[pipeline.id]
            // Notify when pipeline transitions to a terminal status
            if pipeline.pipeline.status.isTerminal && previousStatus != nil && !(previousStatus?.isTerminal ?? false) {
                sendWatchedNotification(pipeline: pipeline)
                watchedPipelineIds.remove(pipeline.id)
            }
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendWatchedNotification(pipeline: EnrichedPipeline) {
        let status = pipeline.pipeline.status
        let content = UNMutableNotificationContent()
        content.title = "Pipeline \(status.displayName.capitalized)"
        content.body = "\(pipeline.project.pathWithNamespace) (\(pipeline.pipeline.ref))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pipeline-watched-\(pipeline.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendFailureNotification(pipeline: EnrichedPipeline) {
        let content = UNMutableNotificationContent()
        content.title = "Pipeline Failed"
        content.body = "\(pipeline.project.pathWithNamespace) (\(pipeline.pipeline.ref))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pipeline-failed-\(pipeline.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()

        guard isConfigured else { return }

        let url = gitlabURL
        let token = gitlabToken

        let poller = PipelinePoller(
            onUpdate: { [weak self] pipelines in
                Task { @MainActor in
                    self?.handlePipelineUpdate(pipelines)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        )

        self.poller = poller
        isLoading = true

        Task {
            await poller.start(baseURL: url, token: token)
        }

        // Observe system wake to refresh
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshNow()
            }
        }
    }

    private func handlePipelineUpdate(_ newPipelines: [EnrichedPipeline]) {
        // Check watched pipelines for completion
        checkWatchedPipelines(newPipelines)

        // Detect newly failed pipelines
        for pipeline in newPipelines where pipeline.pipeline.status == .failed {
            let previousStatus = previousStatuses[pipeline.id]
            if previousStatus != .failed {
                // This pipeline just failed (or is new and failed)
                unseenFailedPipelineIds.insert(pipeline.id)

                // Only notify if we had previous data (skip first load)
                if !previousStatuses.isEmpty {
                    sendFailureNotification(pipeline: pipeline)
                }
            }
        }

        // Remove unseen IDs for pipelines that are no longer failed
        let currentFailedIds = Set(newPipelines.filter { $0.pipeline.status == .failed }.map(\.id))
        unseenFailedPipelineIds = unseenFailedPipelineIds.intersection(currentFailedIds)

        // Update previous statuses
        previousStatuses = Dictionary(
            uniqueKeysWithValues: newPipelines.map { ($0.id, $0.pipeline.status) }
        )

        pipelines = newPipelines
        lastRefresh = Date()
        isLoading = false
        errorMessage = nil
    }

    func stopPolling() {
        if let poller {
            Task { await poller.stop() }
        }
        poller = nil

        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        wakeObserver = nil
    }

    func refreshNow() {
        guard isConfigured, let poller else { return }
        isLoading = true
        let url = gitlabURL
        let token = gitlabToken
        Task {
            await poller.pollNow(baseURL: url, token: token)
        }
    }
}
