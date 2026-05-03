import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    private let service = "com.wealthflow.app"
    private let account = "authToken"
    private let simulatorFallbackKey = "com.wealthflow.simulator.authToken"

    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    func saveToken(_ token: String) -> Bool {
        if isSimulator {
            UserDefaults.standard.set(token, forKey: simulatorFallbackKey)
            print("[Keychain] Simulator: saved token to UserDefaults")
            return true
        }

        guard let data = token.data(using: .utf8) else {
            print("[Keychain] Failed to encode token as UTF-8")
            return false
        }

        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let deleteStatus = SecItemDelete(searchQuery as CFDictionary)
        print("[Keychain] Delete prior token status: \(deleteStatus)")

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        print("[Keychain] Add token status: \(addStatus) (success=\(addStatus == errSecSuccess))")
        return addStatus == errSecSuccess
    }

    func getToken() -> String? {
        if isSimulator {
            let token = UserDefaults.standard.string(forKey: simulatorFallbackKey)
            print("[Keychain] Simulator: read token from UserDefaults (found: \(token != nil))")
            return token
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        print("[Keychain] Get token status: \(status)")
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            print("[Keychain] Get token failed or empty")
            return nil
        }
        print("[Keychain] Got token (length: \(token.count))")
        return token
    }

    func deleteToken() -> Bool {
        if isSimulator {
            UserDefaults.standard.removeObject(forKey: simulatorFallbackKey)
            print("[Keychain] Simulator: removed token from UserDefaults")
            return true
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        print("[Keychain] Delete token status: \(status)")
        return status == errSecSuccess
    }
}
