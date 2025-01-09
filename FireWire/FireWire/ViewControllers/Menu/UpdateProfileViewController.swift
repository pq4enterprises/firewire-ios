//
//  UpdateProfileViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

protocol UpdateProfileViewDelegate: AnyObject {
    func dataLoaded(_ model: LoginDataModel)
    func profileUpdated(_ message: String)
}

class UpdateProfileViewController: UIViewController, UpdateProfileViewDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var profileImageView: FWRoundedImageView!
    @IBOutlet var firstNameTextField: FWTextField!
    @IBOutlet var lastNameTextField: FWTextField!
    @IBOutlet var emailTextField: FWTextField!
    @IBOutlet var phoneNumberTextField: FWTextField!
    @IBOutlet var positionTextField: FWTextField!

    var coordinator: HomeCoordinator?
    var viewModel: UpdateProfileViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardActions()
        
        viewModel = UpdateProfileViewModel()
        viewModel?.delegate = self
        viewModel?.getUserProfile()
    }

    func setupUI() {
        firstNameTextField.backgroundColor = FWColor.textFieldBackgroundGrey
        lastNameTextField.backgroundColor = FWColor.textFieldBackgroundGrey
        emailTextField.backgroundColor = FWColor.textFieldBackgroundGrey
        phoneNumberTextField.backgroundColor = FWColor.textFieldBackgroundGrey
        positionTextField.backgroundColor = FWColor.textFieldBackgroundGrey

        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        phoneNumberTextField.delegate = self
        positionTextField.delegate = self
    }

    func dataLoaded(_ model: LoginDataModel) {
        firstNameTextField.text = model.firstName
        //lastNameTextField.text = model.lastName
        emailTextField.text = model.email
        phoneNumberTextField.text = model.mobile
        positionTextField.text = model.role
    }

    func profileUpdated(_ message: String) {
        hideLoader()
        showToast(message: message)
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    @IBAction func changeButtonTap(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false // Allow editing if needed
            present(picker, animated: true, completion: nil)
        } else {
            // Handle case where photo library isn't available (e.g., device doesn't support it)
            print("Photo Library is not available.")
        }
    }
    

    @IBAction func saveButtonTap(_ sender: UIButton) {
        showLoader()
        let requestModel = UpdateProfileRequestModel(
            firstName: firstNameTextField.text ?? "",
            lastName: lastNameTextField.text ?? "",
            email: emailTextField.text ?? "",
            mobile: phoneNumberTextField.text ?? "",
            title: positionTextField.text ?? ""
        )

        let validationResult = viewModel?.validate(requestModel)
        switch validationResult {
        case .success:
            viewModel?.updateUserProfile(requestModel)
        case .failure(let errorMessage):
            hideLoader()
            showAlertMessage(errorMessage)
        default:
            return
        }
    }

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "Warning",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Okay"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    @IBAction func changePasswordButtonTap(_ sender: UIButton) {}


    func setupActions() {
        hideKeyboardWhenTappedAround()
    }

    // TODO: Handle in common place
    func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        // Calculate the inset of the scroll view
        let keyboardHeight = keyboardFrame.height

        // Set the content inset for the scroll view
        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardHeight
        scrollView.contentInset = contentInset

        // Adjust the scroll indicator inset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // Reset the content inset when the keyboard hides
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset

        // Reset the scroll indicator inset
        scrollView.scrollIndicatorInsets = contentInset
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> UpdateProfileViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "UpdateProfileViewController") as! UpdateProfileViewController
        return viewController
    }
}

extension UpdateProfileViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.backgroundColor = .systemBackground
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.backgroundColor = FWColor.textFieldBackgroundGrey
    }
}

extension UpdateProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            self.profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
