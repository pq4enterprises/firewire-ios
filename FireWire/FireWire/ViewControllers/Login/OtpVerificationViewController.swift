//
//  OtpVerificationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class OtpVerificationViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var value1Text: UITextField!
    @IBOutlet weak var value2Text: UITextField!
    @IBOutlet weak var value3Text: UITextField!
    @IBOutlet weak var value4Text: UITextField!
    @IBOutlet weak var value5Text: UITextField!
    @IBOutlet weak var value6Text: UITextField!

    var otpTextFields: [UITextField] = []
    var coordinator: LoginCoordinator?

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
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> OtpVerificationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "OtpVerificationViewController") as! OtpVerificationViewController
        return viewController
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
                coordinator?.navigateToResetPassword()
            }
        }else if string.isEmpty, textField.text?.count == 1 {
            if currentIndex > 0 {
                otpTextFields[currentIndex - 1].becomeFirstResponder()
            }
        }

        textField.text = string
        return false
    }
}
