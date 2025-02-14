//
//  Strings.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/11/24.
//

public extension String {
    struct Login {
        public static let registerText = "Don’t have an Account? Register"
        public static let register = "Register"
        public static let termsAndConditionsText = "By register or logging into an account you are agreeing with our Terms and Conditions"
        public static let termsAndConditions = "Terms and Conditions"
    }

    struct Register {
        public static let signInText = "Already have an Account? Sign In"
        public static let signIn = "Sign In"
    }

    struct VerifyOtp {
        public static let info = "Verification code has been sent to you registered email id %@"
    }

    struct CommonError {
        public static let techError = "Technical error at our end please try again."
    }
}

public extension String {

    var maskEmail: String {
        let email = self
        let components = email.components(separatedBy: "@")
        var maskEmail = ""
        if let first = components.first {
            maskEmail = String(first.enumerated().map { index, char in
                return [0, 1, first.count - 1, first.count - 2].contains(index) ?
                char : "*"
            })
        }
        if let last = components.last {
            maskEmail = maskEmail + "@" + last
        }
        return maskEmail
    }
}
