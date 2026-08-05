//
//  FWSessionExpiry.swift
//  FireWire
//
//  Single, app-wide signal for "the session is genuinely dead and the user has to
//  sign in again". Everything else — an access token that merely aged out — is
//  renewed silently by APIRequest and never reaches this file.
//

import Foundation

extension Notification.Name {
    /// Posted once when a refresh token is expired, revoked, or belongs to a deleted
    /// account. Observed by SceneDelegate, which routes to the login screen.
    static let fwSessionExpired = Notification.Name("fwSessionExpired")
}

/// The outcome of a token refresh attempt.
///
/// The distinction between `unauthorized` and `transientFailure` matters: signing a
/// user out because their train went into a tunnel is exactly the forced-logout
/// behaviour we are trying to eliminate. Only `unauthorized` ends the session.
enum RefreshOutcome {
    /// New tokens issued and stored. Retry the original request.
    case success
    /// The server refused the refresh token. Re-authentication is unavoidable.
    case unauthorized
    /// Network error, timeout, or server fault. Keep the session and surface the error.
    case transientFailure
}

enum FWSessionExpiry {

    /// Guards against a burst of concurrent 401s each posting its own notification and
    /// stacking several login screens. Reset once the user is back on the login screen.
    private static var isBroadcasting = false
    private static let lock = NSLock()

    static func broadcast() {
        lock.lock()
        if isBroadcasting {
            lock.unlock()
            return
        }
        isBroadcasting = true
        lock.unlock()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .fwSessionExpired, object: nil)
        }
    }

    /// Called by the router once it has finished presenting the login screen.
    static func reset() {
        lock.lock()
        isBroadcasting = false
        lock.unlock()
    }
}
