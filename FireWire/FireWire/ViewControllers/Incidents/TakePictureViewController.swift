//
//  TakePictureViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/01/25.
//

import Photos
import UIKit

protocol TakePictureViewProtocol: AnyObject {
    func selectedImage(url: [String])
}

class TakePictureViewController: UIViewController {
    @IBOutlet var takePhotoView: FWView!
    @IBOutlet var galleryView: FWView!

    weak var delegate: TakePictureViewProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupActions()
    }

    func setupView() {
        takePhotoView.addRoundedBorder()
        galleryView.addRoundedBorder()
    }

    func setupActions() {
        let photoTapGesture = UITapGestureRecognizer(target: self, action: #selector(takePhotoAction))
        takePhotoView.addGestureRecognizer(photoTapGesture)

        let galleryTapGesture = UITapGestureRecognizer(target: self, action: #selector(galleryAction))
        galleryView.addGestureRecognizer(galleryTapGesture)
    }

    @objc func takePhotoAction() {
        openCamera()
    }

    @objc func galleryAction() {
        openPhotoGallery()
    }

    func openPhotoGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.allowsEditing = false
            present(imagePickerController, animated: true, completion: nil)
        } else {
            showAlertMessage("Photo Gallery is not available.")
        }
    }

    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            imagePickerController.allowsEditing = false
            present(imagePickerController, animated: true, completion: nil)
        } else {
            showAlertMessage("Camera is not available on this device.")
        }
    }

    @IBAction func cancelButtonTap(_ sender: UIButton) {
        dismiss(animated: true)
    }

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    static func instantiate() -> TakePictureViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "TakePictureViewController") as! TakePictureViewController
        return viewController
    }
}

extension TakePictureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Delegate method when image is picked
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            // Do something with the selected image, e.g., display it in an ImageView
            // imageView.image = selectedImage
            requestImageUpload(selectedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // Delegate method if the user cancels the picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func requestImageUpload(_ image: UIImage) {
        APIRequest().uploadImage(
            apiEndPoint: APIEndpoints.uploadImage,
            image: image,
            expect: UploadImageResponseModel.self
        ) { [weak self] response, _, _ in
            guard let apiResponse = response else {
                return
            }

            if let response = apiResponse as? UploadImageResponseModel {
                if response.code.lowercased() == "success" {
                    DispatchQueue.main.async {
                        if let imageLink = response.data?.link {
                            self?.delegate?.selectedImage(url: imageLink)
                            self?.dismiss(animated: true)
                        } else {
                            self?.showAlertMessage("Upload image failed")
                        }
                    }
                } else {
                    self?.showAlertMessage(response.message)
                }
            }
        }
    }
}
