import Foundation
import Security

public final class KeychainSecretStore {
    private let service = "app.r2desk.client"

    public init() {}

    public func secret(for bucketID: UUID) throws -> String? {
        var query = baseQuery(bucketID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unhandledStatus(status)
        }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ secret: String, for bucketID: UUID) throws {
        let data = Data(secret.utf8)
        var query = baseQuery(bucketID)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(baseQuery(bucketID) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledStatus(updateStatus)
            }
            return
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    public func deleteSecret(for bucketID: UUID) throws {
        let status = SecItemDelete(baseQuery(bucketID) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    private func baseQuery(_ bucketID: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: bucketID.uuidString
        ]
    }
}

public enum KeychainError: Error, LocalizedError {
    case unhandledStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .unhandledStatus(status):
            return "Keychain returned status \(status)."
        }
    }
}
