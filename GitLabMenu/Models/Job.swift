import Foundation

struct GitLabJob: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let stage: String
    let status: PipelineStatus
    let webUrl: String
    let duration: Double?
    let startedAt: Date?
    let finishedAt: Date?
    let allowFailure: Bool?
}
