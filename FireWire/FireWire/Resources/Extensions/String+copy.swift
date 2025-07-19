//
//  Strings.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/11/24.
//

import Foundation

public extension String {
    static let appStoreUrl = "https://apps.apple.com/us/app/nyc-fire-wire/id980572369"

    enum Login {
        public static let registerText = "Don’t have an Account? Register"
        public static let register = "Register"
        public static let termsAndConditionsText = "By register or logging into an account you are agreeing with our Terms and Conditions"
        public static let termsAndConditions = "Terms and Conditions"
    }

    enum Register {
        public static let signInText = "Already have an Account? Sign In"
        public static let signIn = "Sign In"
    }

    enum VerifyOtp {
        public static let info = "Verification code has been sent to you registered email id %@"
    }

    enum CommonError {
        public static let techError = "Technical error at our end please try again."
    }

    enum PremiumDetails {
        static let title = "Get Full Access With A Premium Account"
        static let premiumAccount = "Premium Account"
    }

    enum Comments {
        static let addAComment = "Add a comment"
        static let commentsAndImageEmptyMessage = "Please enter a comment or upload an image"
    }
}

public extension String {
    var maskEmail: String {
        let email = self
        let components = email.components(separatedBy: "@")
        var maskEmail = ""
        if let first = components.first {
            maskEmail = String(first.enumerated().map { index, char in
                return [0, 1, first.count - 1].contains(index) ?
                char : "*"
            })
        }
        if let last = components.last {
            maskEmail = maskEmail + "@" + last
        }
        return maskEmail
    }

    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    func leftPadded(toLength length: Int, withPad character: Character = "0") -> String {
        let padding = String(repeating: character, count: max(0, length - self.count))
        return padding + self
    }

    var containsEmoji: Bool {
        return self.unicodeScalars.contains { $0.properties.isEmojiPresentation }
    }
}
