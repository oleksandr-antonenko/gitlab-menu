import Foundation

struct GitLabProject: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let pathWithNamespace: String
    let webUrl: String
}
