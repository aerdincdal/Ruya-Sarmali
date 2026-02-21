import Foundation
import Security

struct KeychainStore {
    func setInt(_ value: Int, forKey key: String) {
        var mutableValue = value
        let data = Data(bytes: &mutableValue, count: MemoryLayout<Int>.size)
        set(data, forKey: key)
    }

    func int(forKey key: String) -> Int? {
        guard let data = data(forKey: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    func set(_ data: Data, forKey key: String) {
        delete(key: key)
        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

