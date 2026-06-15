//
//  KeychainStore.swift
//  LaSalleFoods
//
//  Almacenamiento mínimo en Keychain para los tokens de sesión
//  (access/refresh token). No usar UserDefaults para credenciales.
//

import Foundation
import Security

enum KeychainStore {
    enum Key: String {
        case accessToken = "mx.lasalle.lasallefoods.accessToken"
        case refreshToken = "mx.lasalle.lasallefoods.refreshToken"
    }

    static func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Guarda el valor o, si es `nil`, borra la entrada existente.
    static func save(_ key: Key, value: String?) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        guard let value, let data = value.data(using: .utf8) else {
            SecItemDelete(query as CFDictionary)
            return
        }

        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
}
