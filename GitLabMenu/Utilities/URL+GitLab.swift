import Foundation

extension URL {
    /// Construct a GitLab pipeline URL
    static func gitlabPipeline(baseURL: String, projectPath: String, pipelineId: Int) -> URL? {
        URL(string: "\(baseURL)/\(projectPath)/-/pipelines/\(pipelineId)")
    }

    /// Construct a GitLab job URL
    static func gitlabJob(baseURL: String, projectPath: String, jobId: Int) -> URL? {
        URL(string: "\(baseURL)/\(projectPath)/-/jobs/\(jobId)")
    }

    /// Construct a GitLab project URL
    static func gitlabProject(baseURL: String, projectPath: String) -> URL? {
        URL(string: "\(baseURL)/\(projectPath)")
    }
}
