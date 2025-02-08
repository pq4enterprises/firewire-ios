//
//  OtpVerificationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class OtpVerificationViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var value1Text: UITextField!
    @IBOutlet var value2Text: UITextField!
    @IBOutlet var value3Text: UITextField!
    @IBOutlet var value4Text: UITextField!
    @IBOutlet var value5Text: UITextField!
    @IBOutlet var value6Text: UITextField!
    @IBOutlet var verifyOtpInfo: UILabel!

    var otpTextFields: [UITextField] = []
    var coordinator: LoginCoordinator?
    var email: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        otpTextFields = [value1Text, value2Text, value3Text, value4Text, value5Text, value6Text]
        otpTextFields.forEach { $0.delegate = self }
        otpTextFields.forEach { $0.keyboardType = .numberPad }

        value1Text.becomeFirstResponder()

        if let email {
            let maskedEmail = email.maskEmail
            verifyOtpInfo.text = String(format: .VerifyOtp.info, maskedEmail)
        }
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    @IBAction func resentOTPTap(_ sender: UIButton) {
        requestOtp()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var boolSubmitOtp = false
        guard string.count <= 1 else {
            return false
        }

        guard let currentIndex = otpTextFields.firstIndex(of: textField) else {
            return true
        }

        if string.count > 0, textField.text?.count == 0 {
            if currentIndex < otpTextFields.count - 1 {
                otpTextFields[currentIndex + 1].becomeFirstResponder()
            } else {
                otpTextFields[currentIndex].resignFirstResponder()
                boolSubmitOtp = true
            }
        } else if string.isEmpty, textField.text?.count == 1 {
            if currentIndex > 0 {
                otpTextFields[currentIndex - 1].becomeFirstResponder()
            }
        }

        textField.text = string
        if boolSubmitOtp { submitOtp() }
        return false
    }

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> OtpVerificationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "OtpVerificationViewController") as! OtpVerificationViewController
        return viewController
    }
}

// MARK: - API calls

extension OtpVerificationViewController {
    func submitOtp() {
        showLoader()

        guard let email = email else { return }

        let otp = otpTextFields.compactMap { $0.text }.joined()
        if otp.count == otpTextFields.count {
            APIRequest().callApi(
                apiEndPoint: APIEndpoints.verifyOtp,
                payload: APIPayload.verifyOtp(email: email, otp: otp).toDictionary(),
                expect: VerifyOtpResponseModel.self
            ) { [weak self] response, _, _ in
                self?.hideLoader()

                guard let apiResponse = response as? VerifyOtpResponseModel else {
                    let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                    self?.showAlertMessage(errorMessage)
                    return
                }

                if apiResponse.code != "success" {
                    self?.showAlertMessage(apiResponse.message)
                    return
                }

                if let otpData = apiResponse.data  {
                    self?.coordinator?.navigateToResetPassword(token: otpData.resetToken)
                }else{
                    self?.showAlertMessage("Technical error, please try again!")
                }
            }
        }
    }

    func requestOtp() {
        showLoader()

        guard let email = email else { return }

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.forgotPassword,
            payload: APIPayload.forgotPassword(email: email).toDictionary(),
            expect: ForgotPasswordResponseModel.self
        ) { [weak self] response, _, _ in

            self?.hideLoader()
            guard let apiResponse = response else {
                self?.showAlertMessage("Technical error, please try again!")
                return
            }

            if let response = apiResponse as? ForgotPasswordResponseModel {
                if response.code.lowercased() != "success" {
                    self?.showAlertMessage(response.message)
                }
            }
        }
    }
}
