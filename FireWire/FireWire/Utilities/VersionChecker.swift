//
//  VersionChecker.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 01/07/25.
//

import Foundation

class VersionChecker {
    static let minimumSupportedVersion = "12.0"

    static func isUpdateRequired() -> Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return isVersion(currentVersion, lessThan: minimumSupportedVersion)
    }

    private static func isVersion(_ current: String, lessThan required: String) -> Bool {
        let c = current.split(separator: ".").compactMap { Int($0) }
        let r = required.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(c.count, r.count) {
            let cv = i < c.count ? c[i] : 0
            let rv = i < r.count ? r[i] : 0
            if cv < rv { return true }
            if cv > rv { return false }
        }
        return false
    }
}
