//
//  FWUserDefaults.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/03/25.
//

import Foundation

enum UserDefaultKeys: String {
    case userTokenKey = "userToken"
    case refreshTokenKey = "refreshToken"
    case userIDKey = "userID"
    case userEmailKey = "userEmail"
    case userNameKey = "userName"
    case userRoleKey = "userRole"
    case userImageKey = "userImage"
}

public struct FWUserDefaults {
    private let defaults = UserDefaults.standard

    static func setObjectForKey(key: UserDefaultKeys, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func setStringForKey(key: UserDefaultKeys, value: String?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func setBoolForKey(key: UserDefaultKeys, value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func removeObjectForKey(key: UserDefaultKeys){
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }

    var userToken: String? {
        get {
            return stringForKey(key: UserDefaultKeys.userTokenKey.rawValue)
        }
    }

    var refreshToken: String? {
        get {
            return stringForKey(key: UserDefaultKeys.refreshTokenKey.rawValue)
        }
    }

    var userID: String? {
        get {
            return stringForKey(key: UserDefaultKeys.userIDKey.rawValue)
        }
    }

    var userEmail: String? {
        get {
            return stringForKey(key: UserDefaultKeys.userEmailKey.rawValue)
        }
    }

    var userName: String? {
        get {
            return stringForKey(key: UserDefaultKeys.userNameKey.rawValue)
        }
    }

    var userRole: String? {
        get {
            return stringForKey(key: UserDefaultKeys.userRoleKey.rawValue)
        }
    }

    var userImage: String? {
        get {
            return stringForKey(key: UserDefaultKeys.userImageKey.rawValue)
        }
    }

    func stringForKey(key: String) -> String? {
        return defaults.object(forKey: key) as? String
    }

    func intForKey(key: String) -> Int? {
        return defaults.object(forKey: key) as? Int
    }

    func boolForKey(key: String) -> Bool {
        return defaults.bool(forKey: key)
    }

    func objectForKey(key: String) -> [String:Any]? {
        return defaults.object(forKey: key) as? [String:Any]
    }

    func isAdminUser() -> Bool {
        let adminRoles = ["admin", "sub_admin", "super"]
        return adminRoles.contains(userRole ?? "")
    }
}
