//
//  TakePictureViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/01/25.
//

import Photos
import UIKit

class TakePictureViewController: UIViewController {
    @IBOutlet var takePhotoView: FWView!
    @IBOutlet var galleryView: FWView!

    var coordinator: HomeCoordinator?
    var selectedIncidentID: String?

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
            showAlert(title: "", message: "Photo Gallery is not available.", actions: [UIAlertAction(title: "Ok", style: .cancel)])
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
            showAlert(title: "", message: "Camera is not available on this device.", actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }
    }

    @IBAction func cancelButtonTap(_ sender: UIButton) {
        dismiss(animated: true)
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
        if let selectedImage = info[.originalImage] as? UIImage, let incidentId = selectedIncidentID {
            // Do something with the selected image, e.g., display it in an ImageView
            // requestImageUpload(selectedImage)

            picker.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }

                self.dismiss(animated: true) {
                    self.coordinator?.navigateToIncidentComments(incidentId, [selectedImage])
                }
            }
        } else {
            picker.dismiss(animated: true, completion: nil)
        }
    }

    // Delegate method if the user cancels the picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    //TODO: Upload image is happening along with comment, this can be removed after testing
    func requestImageUpload(_ image: UIImage) {
        showLoader()
        APIRequest().uploadImage(
            apiEndPoint: APIEndpoints.uploadImage,
            image: image,
            expect: UploadImageResponseModel.self
        ) { [weak self] response, _, _ in
            guard let apiResponse = response else {
                self?.hideLoader()
                return
            }

            if let response = apiResponse as? UploadImageResponseModel {
                if response.code.lowercased() == "success" {
                    self?.hideLoader()
                    DispatchQueue.main.async {
                        if let imageUrl = response.data?.url, let incidentId = self?.selectedIncidentID {
                            self?.dismiss(animated: true, completion: {
                                // self?.coordinator?.navigateToIncidentComments(incidentId, imageUrl)
                            })
                        } else {
                            self?.showAlert(title: "", message: "Upload image failed", actions: [UIAlertAction(title: "Ok", style: .cancel)])
                        }
                    }
                } else {
                    self?.showAlert(title: "", message: response.message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                }
            }
        }
    }
}
