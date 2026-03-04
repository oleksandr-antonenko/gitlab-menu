import Foundation

actor PipelinePoller {
    private var timer: Timer?
    private var isPolling = false
    private let interval: TimeInterval = 15

    private var onUpdate: @Sendable ([EnrichedPipeline]) -> Void
    private var onError: @Sendable (Error) -> Void

    init(
        onUpdate: @escaping @Sendable ([EnrichedPipeline]) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        self.onUpdate = onUpdate
        self.onError = onError
    }

    func start(baseURL: String, token: String) {
        stop()

        // Run immediately
        Task {
            await poll(baseURL: baseURL, token: token)
        }

        // Schedule recurring polls on the main run loop
        let interval = self.interval
        let pollFn: @Sendable (String, String) async -> Void = { [weak self] base, tok in
            await self?.poll(baseURL: base, token: tok)
        }
        Task { @MainActor [weak self] in
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task {
                    await pollFn(baseURL, token)
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            await self?.setTimer(timer)
        }
    }

    private func setTimer(_ timer: Timer) {
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pollNow(baseURL: String, token: String) async {
        await poll(baseURL: baseURL, token: token)
    }

    private func poll(baseURL: String, token: String) async {
        guard !isPolling else { return }
        isPolling = true
        defer { isPolling = false }

        let client = GitLabAPIClient(baseURL: baseURL, token: token)

        do {
            // Step 1: Fetch all projects
            let projects = try await client.fetchProjects()

            // Step 2: Fetch latest pipeline per project concurrently
            let projectPipelines: [(GitLabProject, GitLabPipeline)] = await withTaskGroup(
                of: (GitLabProject, GitLabPipeline)?.self
            ) { group in
                for project in projects {
                    group.addTask {
                        guard let pipeline = try? await client.fetchLatestPipeline(projectId: project.id) else {
                            return nil
                        }
                        return (project, pipeline)
                    }
                }

                var results: [(GitLabProject, GitLabPipeline)] = []
                for await result in group {
                    if let result {
                        results.append(result)
                    }
                }
                return results
            }

            // Step 3: Sort by updatedAt desc, take top 10
            let top10 = projectPipelines
                .sorted { $0.1.updatedAt > $1.1.updatedAt }
                .prefix(10)

            // Step 4: Fetch jobs for each of the top 10 concurrently
            let enrichedPipelines: [EnrichedPipeline] = await withTaskGroup(
                of: EnrichedPipeline?.self
            ) { group in
                for (project, pipeline) in top10 {
                    group.addTask {
                        let jobs = (try? await client.fetchJobs(projectId: project.id, pipelineId: pipeline.id)) ?? []
                        return EnrichedPipeline(
                            id: pipeline.id,
                            project: project,
                            pipeline: pipeline,
                            jobs: jobs
                        )
                    }
                }

                var results: [EnrichedPipeline] = []
                for await result in group {
                    if let result {
                        results.append(result)
                    }
                }
                return results
            }

            // Sort again after concurrent fetch
            let sorted = enrichedPipelines.sorted { $0.pipeline.updatedAt > $1.pipeline.updatedAt }
            onUpdate(sorted)

        } catch {
            onError(error)
        }
    }
}
