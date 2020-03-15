//
//  Credential.swift
//  Cookbook
//
//  Created by David Klopp on 04.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

extension UserDefaults.Key {
    static let server: UserDefaults.Key = "SERVER"
    static let user: UserDefaults.Key = "USER"
    static let password: UserDefaults.Key = "PASSWORD"
}

enum KeychainError: Error {
    case noUser
    case noServer
    case noPassword
    case unhandledError(status: OSStatus)
}

class Credentials {
    var server: String? {
        didSet { self.needsUpdate = true }
    }
    var username: String? {
        didSet { self.needsUpdate = true }
    }
    var password: String? {
        didSet { self.needsUpdate = true }
    }

    private var needsUpdate: Bool = false

    static func setDefaultInformation() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [.server: "", .user: "", .password: ""])
        defaults.synchronize()
    }

    // Load the currently stored credentials.
    static func loadStoredCredentials() -> Credentials {
        let credentials = Credentials()

        // Try to load the stored information from the User Defaults
        let defaults = UserDefaults.standard
        credentials.server = defaults.string(forKey: .server)
        credentials.username = defaults.string(forKey: .user)

        // Try to load the keychain information
        if let server = credentials.server, let user = credentials.username {
            let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                        kSecAttrAccount as String: user,
                                        kSecAttrServer as String: server,
                                        kSecMatchLimit as String: kSecMatchLimitOne,
                                        kSecReturnAttributes as String: true,
                                        kSecReturnData as String: true]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            //print(SecCopyErrorMessageString(status, nil))
            if status != errSecItemNotFound, let existingItem = item as? [String: Any],
                let passwordData = existingItem[kSecValueData as String] as? Data,
                let password = String(data: passwordData, encoding: String.Encoding.utf8) {
                credentials.password = password
            }
        }

        return credentials
    }

    /// Return true if the credentials are set, false otherwise.
    func informationIsSet() -> Bool {
        if let server = self.server, let user = self.username, let passwd = self.password {
            return !server.isEmpty && !user.isEmpty && !passwd.isEmpty
        }
        return false
    }

    /// Read the current information from the UserDefaults and delete it.
    private func deleteStoredInformation() throws {
        guard let user = UserDefaults.standard.string(forKey: .user)?.data(using: .utf8) else {
            throw KeychainError.noUser
        }
        guard let server = UserDefaults.standard.string(forKey: .server)?.data(using: .utf8) else {
            throw KeychainError.noServer
        }

        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: user,
                                    kSecAttrServer as String: server]
        //print("delete: ", UserDefaults.standard.string(forKey: .server), UserDefaults.standard.string(forKey: .user))
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }

    /**
     Update the stored server, username and password based on the current variable state.
     The UserDefaults as well as the secure keychain entry will be updated.
     */
    func updateStoredInformation() throws {
        guard self.needsUpdate else { return }
        guard let passwd = self.password?.data(using: .utf8) else { throw KeychainError.noPassword }
        guard let user = self.username?.data(using: .utf8) else { throw KeychainError.noUser }
        guard let server = self.server?.data(using: .utf8) else { throw KeychainError.noServer }

        // Save server and username to UserDefaults.
        let defaults = UserDefaults.standard

        // Delete the old information and ignore possible errors (notFound for example).
        try? self.deleteStoredInformation()

        defaults.set(self.server, forKey: .server)
        defaults.set(self.username, forKey: .user)
        // Add dummy data for the password
        defaults.set("12345678", forKey: .password)
        defaults.synchronize()

        //print("Store: ", self.server, self.username)

        // Store the password inside the keychain.
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: user,
                                    kSecAttrServer as String: server,
                                    kSecValueData as String: passwd]
        var status = SecItemAdd(query as CFDictionary, nil)
        //print(SecCopyErrorMessageString(status, nil))
        // update the item if it already exists
        if status == errSecDuplicateItem {
            let searchQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                              kSecAttrAccount as String: user,
                                              kSecAttrServer as String: server,
                                              kSecMatchLimit as String: kSecMatchLimitOne]
            let itemsToUpdate: [String: Any] = [kSecValueData as String: passwd]
            status = SecItemUpdate(searchQuery as CFDictionary, itemsToUpdate as CFDictionary)
        }
        //print(SecCopyErrorMessageString(status, nil))
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        // Changes were sucessfully written
        self.needsUpdate = false
    }
}

/// Load the globally accessible login credentials when the application launches.
let loginCredentials: Credentials = Credentials.loadStoredCredentials()
