//
//  AppDelegate.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/11/24.
//

import FBSDKCoreKit
import GoogleMaps
import GoogleSignIn
import OneSignalFramework
import StoreKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    #if DEV
        static let oneSignalAppId = "0366eec4-c67f-472e-9a4f-8f73461f1353"
    #else
        static let oneSignalAppId = "8721de76-7494-4ec0-a4c1-a85f0c995cf5"
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // TODO: This is Dev key from Atom replace it from NYC
        GMSServices.provideAPIKey("AIzaSyALseex1HWFQ2XSxIk-uYwKegYzc5hgkPg")

        /// Facebook SDK initialisation
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        // In-App Purchase
        SubscriptionManager.shared.fetchProducts()

        // Remove this method to stop OneSignal Debugging
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(AppDelegate.oneSignalAppId, withLaunchOptions: launchOptions)

        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        var handled: Bool
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        return false
    }
}
