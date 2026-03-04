import Foundation

actor GitLabAPIClient {
    private let baseURL: String
    private let token: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String, token: String) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.token = token

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Projects

    /// Fetch all membership projects (paginated, up to 500)
    func fetchProjects() async throws -> [GitLabProject] {
        var allProjects: [GitLabProject] = []
        var page = 1
        let perPage = 100
        let maxPages = 5 // 500 projects max

        while page <= maxPages {
            let url = "\(baseURL)/api/v4/projects?membership=true&per_page=\(perPage)&order_by=last_activity_at&page=\(page)"
            let projects: [GitLabProject] = try await request(url: url)

            allProjects.append(contentsOf: projects)

            if projects.count < perPage {
                break // No more pages
            }
            page += 1
        }

        return allProjects
    }

    // MARK: - Pipelines

    /// Fetch the latest pipeline for a project
    func fetchLatestPipeline(projectId: Int) async throws -> GitLabPipeline? {
        let url = "\(baseURL)/api/v4/projects/\(projectId)/pipelines?per_page=1&order_by=updated_at&sort=desc"
        let pipelines: [GitLabPipeline] = try await request(url: url)
        return pipelines.first
    }

    // MARK: - Jobs

    /// Fetch jobs for a specific pipeline
    func fetchJobs(projectId: Int, pipelineId: Int) async throws -> [GitLabJob] {
        let url = "\(baseURL)/api/v4/projects/\(projectId)/pipelines/\(pipelineId)/jobs?per_page=100"
        return try await request(url: url)
    }

    // MARK: - Test Connection

    /// Test the connection by fetching the current user
    func testConnection() async throws -> String {
        let url = "\(baseURL)/api/v4/user"

        guard let requestURL = URL(string: url) else {
            throw GitLabAPIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.setValue(token, forHTTPHeaderField: "PRIVATE-TOKEN")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitLabAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GitLabAPIError.httpError(httpResponse.statusCode)
        }

        struct User: Codable {
            let username: String
        }

        let user = try decoder.decode(User.self, from: data)
        return user.username
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(url: String) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw GitLabAPIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.setValue(token, forHTTPHeaderField: "PRIVATE-TOKEN")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitLabAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GitLabAPIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }
}

enum GitLabAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GitLab URL"
        case .invalidResponse:
            return "Invalid response from GitLab"
        case .httpError(let code):
            switch code {
            case 401:
                return "Unauthorized — check your access token"
            case 403:
                return "Forbidden — insufficient permissions"
            case 404:
                return "Not found — check your GitLab URL"
            default:
                return "HTTP error \(code)"
            }
        }
    }
}
