//
//  EditProfileViewController.swift
//  FireWire
//
//  2026 redesign (programmatic UIKit, FireWireTheme) — replaces the old
//  storyboard UpdateProfileViewController. All profile-update / image-upload /
//  validation logic is reused verbatim via UpdateProfileViewModel.
//

import UIKit

class EditProfileViewController: UIViewController, UpdateProfileViewDelegate {
    var coordinator: HomeCoordinator?
    var viewModel: UpdateProfileViewModel?
    var uploadedImageUrl: String?

    // MARK: Views

    private let headerBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bottomBar = UIView()

    private let avatarCircle = UIView()
    private let avatarImageView = FWRoundedImageView()

    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()
    private let emailTextField = UITextField()
    private let phoneNumberTextField = UITextField()
    private let positionTextField = UITextField()

    private let saveButton = UIButton(type: .system)
    private let changePasswordButton = UIButton(type: .system)

    /// Card-styled views whose CGColor borders need refreshing on theme change.
    private var borderedViews: [UIView] = []

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        hideKeyboardWhenTappedAround()
        setupKeyboardActions()

        viewModel = UpdateProfileViewModel()
        viewModel?.delegate = self
        viewModel?.getUserProfile()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CGColor-based borders don't auto-update with dark mode
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            borderedViews.forEach {
                $0.layer.borderColor = FireWireTheme.hairline.cgColor
            }
        }
    }

    // MARK: UI construction

    private func buildUI() {
        view.backgroundColor = FireWireTheme.background
        buildHeaderBar()
        buildBottomBar()
        buildScrollContent()
        buildAvatarBlock()
        buildFieldsCard()
    }

    private func buildHeaderBar() {
        headerBar.backgroundColor = FireWireTheme.surface
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(hairline)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" BACK", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.tintColor = FireWireTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "EDIT PROFILE"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),

            hairline.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            backButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: -14),
        ])
    }

    private func buildBottomBar() {
        bottomBar.backgroundColor = FireWireTheme.surface
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(hairline)

        saveButton.setTitle("SAVE AND UPDATE", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .heavy)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = FireWireTheme.red
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveButtonTap), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(saveButton)

        changePasswordButton.setTitle("CHANGE PASSWORD?", for: .normal)
        changePasswordButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        changePasswordButton.tintColor = FireWireTheme.red
        changePasswordButton.isHidden = true
        changePasswordButton.addTarget(self, action: #selector(changePasswordButtonTap), for: .touchUpInside)
        changePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(changePasswordButton)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hairline.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            hairline.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 54),

            changePasswordButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 4),
            changePasswordButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            changePasswordButton.heightAnchor.constraint(equalToConstant: 36),
            changePasswordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
        ])
    }

    private func buildScrollContent() {
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func buildAvatarBlock() {
        let block = UIView()

        avatarCircle.backgroundColor = FireWireTheme.redTint
        avatarCircle.layer.cornerRadius = 43
        avatarCircle.clipsToBounds = true
        avatarCircle.translatesAutoresizingMaskIntoConstraints = false

        let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        avatarIcon.tintColor = FireWireTheme.red
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarCircle.addSubview(avatarIcon)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarCircle.addSubview(avatarImageView)

        // Camera badge overlapping the avatar's bottom-right corner
        let badge = UIView()
        badge.backgroundColor = FireWireTheme.red
        badge.layer.cornerRadius = 15
        badge.layer.borderWidth = 3
        badge.layer.borderColor = FireWireTheme.background.cgColor
        badge.translatesAutoresizingMaskIntoConstraints = false

        let cameraIcon = UIImageView(image: UIImage(
            systemName: "camera.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)))
        cameraIcon.tintColor = .white
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(cameraIcon)

        let changePhotoButton = UIButton(type: .system)
        changePhotoButton.setTitle("CHANGE PHOTO", for: .normal)
        changePhotoButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        changePhotoButton.tintColor = FireWireTheme.red
        changePhotoButton.addTarget(self, action: #selector(changePhotoTap), for: .touchUpInside)
        changePhotoButton.translatesAutoresizingMaskIntoConstraints = false

        block.addSubview(avatarCircle)
        block.addSubview(badge)
        block.addSubview(changePhotoButton)

        NSLayoutConstraint.activate([
            avatarCircle.topAnchor.constraint(equalTo: block.topAnchor),
            avatarCircle.centerXAnchor.constraint(equalTo: block.centerXAnchor),
            avatarCircle.widthAnchor.constraint(equalToConstant: 86),
            avatarCircle.heightAnchor.constraint(equalToConstant: 86),

            avatarIcon.centerXAnchor.constraint(equalTo: avatarCircle.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarCircle.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 48),
            avatarIcon.heightAnchor.constraint(equalToConstant: 48),

            avatarImageView.topAnchor.constraint(equalTo: avatarCircle.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarCircle.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarCircle.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarCircle.bottomAnchor),

            badge.trailingAnchor.constraint(equalTo: avatarCircle.trailingAnchor, constant: 2),
            badge.bottomAnchor.constraint(equalTo: avatarCircle.bottomAnchor, constant: 2),
            badge.widthAnchor.constraint(equalToConstant: 30),
            badge.heightAnchor.constraint(equalToConstant: 30),

            cameraIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor),

            changePhotoButton.topAnchor.constraint(equalTo: avatarCircle.bottomAnchor, constant: 6),
            changePhotoButton.centerXAnchor.constraint(equalTo: block.centerXAnchor),
            changePhotoButton.bottomAnchor.constraint(equalTo: block.bottomAnchor),
        ])

        // The whole avatar block opens the photo picker, matching the mockup
        block.isUserInteractionEnabled = true
        block.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(changePhotoTap)))

        contentStack.addArrangedSubview(block)
        contentStack.setCustomSpacing(18, after: block)
    }

    private func buildFieldsCard() {
        let card = UIView()
        FireWireTheme.cardStyle(card)
        borderedViews.append(card)

        let fieldsStack = UIStackView()
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 14
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fieldsStack)

        NSLayoutConstraint.activate([
            fieldsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            fieldsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            fieldsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            fieldsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        let nameRow = UIStackView(arrangedSubviews: [
            fieldBlock(caption: "FIRST NAME", textField: firstNameTextField),
            fieldBlock(caption: "LAST NAME", textField: lastNameTextField),
        ])
        nameRow.axis = .horizontal
        nameRow.distribution = .fillEqually
        nameRow.spacing = 12
        fieldsStack.addArrangedSubview(nameRow)

        fieldsStack.addArrangedSubview(
            fieldBlock(caption: "EMAIL ADDRESS", textField: emailTextField))

        let detailRow = UIStackView(arrangedSubviews: [
            fieldBlock(caption: "PHONE", textField: phoneNumberTextField),
            fieldBlock(caption: "TITLE / POSITION", textField: positionTextField),
        ])
        detailRow.axis = .horizontal
        detailRow.distribution = .fillEqually
        detailRow.spacing = 12
        fieldsStack.addArrangedSubview(detailRow)

        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        phoneNumberTextField.keyboardType = .numberPad

        contentStack.addArrangedSubview(card)
    }

    private func fieldBlock(caption: String, textField: UITextField) -> UIView {
        let captionLabel = UILabel()
        captionLabel.attributedText = NSAttributedString(
            string: caption,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
                .kern: 1.0,
                .foregroundColor: FireWireTheme.muted,
            ])

        textField.font = .systemFont(ofSize: 15, weight: .semibold)
        textField.textColor = FireWireTheme.text
        textField.backgroundColor = FireWireTheme.surface2
        textField.layer.cornerRadius = 12
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 50))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 50))
        textField.rightViewMode = .always
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let block = UIStackView(arrangedSubviews: [captionLabel, textField])
        block.axis = .vertical
        block.spacing = 7
        return block
    }

    // MARK: UpdateProfileViewDelegate

    func dataLoaded(_ model: UserProfileData) {
        firstNameTextField.text = model.firstName
        lastNameTextField.text = model.lastName
        emailTextField.text = model.email
        phoneNumberTextField.text = model.mobile
        positionTextField.text = model.title

        if let profileImage = model.img, let imageUrl = URL(string: profileImage) {
            avatarImageView.loadImage(from: imageUrl)
            uploadedImageUrl = model.img
        }

        changePasswordButton.isHidden = model.type != "Email"
    }

    func error(message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    func profileUpdated(_ message: String) {
        hideLoader()
        showToast(message: message)
    }

    func profileImageUpdated(_ url: String) {
        uploadedImageUrl = url
        hideLoader()
    }

    // MARK: Actions

    @objc private func backButtonTap() {
        coordinator?.popView()
    }

    @objc private func changePhotoTap() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            present(picker, animated: true, completion: nil)
        } else {
            print("Photo Library is not available.")
        }
    }

    @objc private func saveButtonTap() {
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
            showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
        default:
            return
        }
    }

    @objc private func changePasswordButtonTap() {
        coordinator?.navigateToChangePassword()
    }

    // MARK: Keyboard

    // TODO: Handle in common place
    func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardFrame.height
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> EditProfileViewController {
        return EditProfileViewController()
    }
}

extension EditProfileViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length

        if textField == phoneNumberTextField {
            // Allow only numbers (0-9) and prevent special characters
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)

            return allowedCharacters.isSuperset(of: characterSet) && newLength <= 15
        } else if textField == firstNameTextField || textField == lastNameTextField {
            return newLength <= 30
        }
        return true
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            avatarImageView.image = selectedImage
            showLoader()
            viewModel?.requestImageUpload(selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
