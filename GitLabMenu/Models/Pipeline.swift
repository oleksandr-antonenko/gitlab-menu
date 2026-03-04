import Foundation

struct GitLabPipeline: Codable, Identifiable, Sendable {
    let id: Int
    let status: PipelineStatus
    let ref: String
    let webUrl: String
    let updatedAt: Date
    let source: String?
}

enum PipelineStatus: String, Codable, Sendable, CaseIterable {
    case created
    case waitingForResource = "waiting_for_resource"
    case preparing
    case pending
    case running
    case success
    case failed
    case canceled
    case skipped
    case manual
    case scheduled

    var isTerminal: Bool {
        switch self {
        case .success, .failed, .canceled, .skipped:
            return true
        default:
            return false
        }
    }

    var isActive: Bool {
        switch self {
        case .running, .pending, .preparing, .waitingForResource, .created:
            return true
        default:
            return false
        }
    }

    /// Higher number = worse status (for determining menu bar icon)
    var severity: Int {
        switch self {
        case .success: return 0
        case .skipped: return 1
        case .canceled: return 2
        case .manual: return 3
        case .scheduled: return 4
        case .created: return 5
        case .waitingForResource: return 6
        case .preparing: return 7
        case .pending: return 8
        case .running: return 9
        case .failed: return 10
        }
    }
}

struct EnrichedPipeline: Identifiable, Sendable {
    let id: Int
    let project: GitLabProject
    let pipeline: GitLabPipeline
    var jobs: [GitLabJob]

    var stages: [String] {
        // Preserve order from pipeline definition by using job ordering
        var seen = Set<String>()
        var ordered: [String] = []
        for job in jobs {
            if !seen.contains(job.stage) {
                seen.insert(job.stage)
                ordered.append(job.stage)
            }
        }
        return ordered
    }

    var completedStageCount: Int {
        stages.filter { stage in
            let stageJobs = jobs.filter { $0.stage == stage }
            return !stageJobs.isEmpty && stageJobs.allSatisfy { $0.status.isTerminal }
        }.count
    }

    var totalStageCount: Int {
        stages.count
    }

    var currentStageName: String? {
        stages.first { stage in
            let stageJobs = jobs.filter { $0.stage == stage }
            return stageJobs.contains { !$0.status.isTerminal }
        }
    }

    var progress: Double {
        guard totalStageCount > 0 else { return 0 }
        return Double(completedStageCount) / Double(totalStageCount)
    }
}
