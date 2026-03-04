import Foundation
import Security

enum KeychainService {
    private static let service = "com.gitlab-menu"
    private static let tokenAccount = "gitlab-token"
    private static let urlAccount = "gitlab-url"

    // MARK: - Token

    static func saveToken(_ token: String) throws {
        try save(account: tokenAccount, data: Data(token.utf8))
    }

    static func loadToken() -> String? {
        guard let data = load(account: tokenAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() {
        delete(account: tokenAccount)
    }

    // MARK: - URL

    static func saveURL(_ url: String) throws {
        try save(account: urlAccount, data: Data(url.utf8))
    }

    static func loadURL() -> String? {
        guard let data = load(account: urlAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteURL() {
        delete(account: urlAccount)
    }

    // MARK: - Generic Keychain Operations

    private static func save(account: String, data: Data) throws {
        // Delete existing item first
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private static func load(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed with status: \(status)"
        }
    }
}
