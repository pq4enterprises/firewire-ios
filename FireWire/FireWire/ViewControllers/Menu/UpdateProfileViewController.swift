//
//  UpdateProfileViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

protocol UpdateProfileViewDelegate: AnyObject {
    func error(message: String)
    func dataLoaded(_ model: UserProfileData)
    func profileUpdated(_ message: String)
    func profileImageUpdated(_ url: String)
}

class UpdateProfileViewController: UIViewController, UpdateProfileViewDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var profileImageView: FWRoundedImageView!
    @IBOutlet var firstNameTextField: FWTextField!
    @IBOutlet var lastNameTextField: FWTextField!
    @IBOutlet var emailTextField: FWTextField!
    @IBOutlet var phoneNumberTextField: FWTextField!
    @IBOutlet var positionTextField: FWTextField!
    @IBOutlet weak var changePasswordButton: UIButton!
    
    var coordinator: HomeCoordinator?
    var viewModel: UpdateProfileViewModel?
    var uploadedImageUrl: String?

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

    func dataLoaded(_ model: UserProfileData) {
        firstNameTextField.text = model.firstName
        lastNameTextField.text = model.lastName
        emailTextField.text = model.email
        phoneNumberTextField.text = model.mobile
        positionTextField.text = model.role

        if let profileImage = model.img, let imageUrl = URL(string: profileImage) {
            profileImageView.loadImage(from: imageUrl)
            uploadedImageUrl = model.img
        }

        changePasswordButton.isHidden = model.type != "Email"
    }

    func error(message: String) {
        hideLoader()
        showAlertMessage(message)
    }

    func profileUpdated(_ message: String) {
        hideLoader()
        showToast(message: message)
    }

    func profileImageUpdated(_ url: String){
        self.uploadedImageUrl = url
        hideLoader()
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
            title: positionTextField.text ?? "",
            img: uploadedImageUrl ?? ""
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
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Okay"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    @IBAction func changePasswordButtonTap(_ sender: UIButton) {
        coordinator?.navigateToChangePassword()
    }


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
            self.showLoader()
            self.viewModel?.requestImageUpload(selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
