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
    private var verificationType: OTPVerificationType!
    private var viewModel: OtpVerificationProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        otpTextFields = [value1Text, value2Text, value3Text, value4Text, value5Text, value6Text]
        otpTextFields.forEach { $0.delegate = self }
        otpTextFields.forEach { $0.keyboardType = .numberPad }

        value1Text.becomeFirstResponder()

        let maskedEmail = viewModel.email.maskEmail
        verifyOtpInfo.text = String(format: .VerifyOtp.info, maskedEmail)
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

    // A convenience method to instantiate from the storyboard
    static func instantiate(viewModel: OtpVerificationProtocol, verificationType: OTPVerificationType) -> OtpVerificationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "OtpVerificationViewController") as! OtpVerificationViewController
        viewController.viewModel = viewModel
        viewController.verificationType = verificationType
        return viewController
    }
}

// MARK: - API calls

extension OtpVerificationViewController {
    func submitOtp() {
        showLoader()

        let otp = otpTextFields.compactMap { $0.text }.joined()
        guard otp.count == otpTextFields.count else {
            hideLoader()
            showAlert(title: "", message: "Please enter valid OTP", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        viewModel.updateOtp(otp)
        viewModel.submitOtp()
    }

    func requestOtp() {
        showLoader()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.forgotPassword,
            payload: APIPayload.forgotPassword(email: viewModel.email).toDictionary(),
            expect: ForgotPasswordResponseModel.self
        ) { [weak self] response, _, error in

            self?.hideLoader()
            if let errorMessage = error {
                self?.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            guard let apiResponse = response else {
                self?.showAlert(title: "", message: "Technical error, please try again!", actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            if let response = apiResponse as? ForgotPasswordResponseModel {
                if response.code.lowercased() != "success" {
                    self?.showAlert(title: "", message: response.message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                }
            }
        }
    }
}

extension OtpVerificationViewController: OtpVerificationViewModelDelegate {
    func otpVerificationSuccess(data: VerifyOtpResponseData?) {
        DispatchQueue.main.async {
            self.hideLoader()
            if self.verificationType == .forgotPassword {
                self.coordinator?.navigateToResetPassword(token: data?.resetToken ?? "")
            } else {
                self.showAlert(title: "", message: "OTP verified successfully", actions: [UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.coordinator?.navigateToSelectArea()
                })])
            }
        }
    }

    func otpVerificationFailure(errorMessage: String) {
        DispatchQueue.main.async {
            self.hideLoader()
            self.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel) { _ in
                self.otpTextFields.forEach { $0.text = "" }
                self.value1Text.becomeFirstResponder()
            }])
        }
    }
}
