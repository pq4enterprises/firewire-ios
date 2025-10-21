//
//  VersionChecker.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 01/07/25.
//

import Foundation
import FirebaseRemoteConfig

/// Note: Verifying only build number from firebase for force update logic.
class VersionChecker {
    static let minimumSupportedVersion = "12.0.2"
    //static let minimumSupportedBuild = "120205"

    private static let remoteConfig = RemoteConfig.remoteConfig()

    static func fetchRemoteConfig(completion: (() -> Void)? = nil) {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 43200 // 0 for dev, // 12 hours for prod
        remoteConfig.configSettings = settings

        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                debugPrint("Remote Config fetch failed: \(error.localizedDescription)")
                completion?()
                return
            }

            debugPrint("Remote Config fetched successfully: \(status.rawValue)")
            debugPrint("minimum_ios_build =", remoteConfig["minimum_ios_build"].stringValue)
            completion?()
        }
    }

    static var minimumSupportedBuild: String {
        remoteConfig["minimum_ios_build"].stringValue
    }

    static func isBuildUpdateRequired() -> Bool {
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return Int(currentBuild) ?? 0 < Int(minimumSupportedBuild) ?? 0
    }

    static func isUpdateRequired() -> Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        let maxComponents = maxDotCountVersionComponentCount(currentVersion, minimumSupportedVersion)
        let a = paddedVersion(currentVersion, maxComponents: maxComponents)
        let b = paddedVersion(minimumSupportedVersion, maxComponents: maxComponents)
        return a < b
    }

    static func isAnyUpdateRequired() -> Bool {
        return isUpdateRequired() || isBuildUpdateRequired()
    }

    static func maxDotCountVersionComponentCount(_ v1: String, _ v2: String) -> Int {
        let count1 = v1.split(separator: ".").count
        let count2 = v2.split(separator: ".").count
        return max(count1, count2)
    }

    static func paddedVersion(_ version: String, maxComponents: Int = 3, componentWidth: Int = 5) -> Int {
        let parts = version.split(separator: ".").map { String($0) }
        var paddedParts: [String] = []

        for i in 0..<maxComponents {
            let part = i < parts.count ? parts[i] : "0"
            paddedParts.append(part.leftPadded(toLength: componentWidth))
        }

        return Int(paddedParts.joined()) ?? 0
    }

    //Note: Not used as of now it is replaced with padded version remove this logic later
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
