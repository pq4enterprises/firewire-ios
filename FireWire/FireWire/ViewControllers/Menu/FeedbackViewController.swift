//
//  FeedbackViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 31/01/25.
//

import UIKit

class FeedbackViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var feedbackView: FWView!
    @IBOutlet weak var feedBackTextView: UITextView!

    private let maxCharacterCount = 100
    var submitFeedback: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardActions()
    }

    func setupUI(){
        feedbackView.setCornerRadius()

        feedBackTextView.layer.borderWidth = 1
        feedBackTextView.layer.borderColor = FWColor.textFieldGrey.cgColor
        feedBackTextView.layer.cornerRadius = 5
        feedBackTextView.translatesAutoresizingMaskIntoConstraints = false
        feedBackTextView.delegate = self
    }

    @IBAction func closeButtonTap(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func submitButtonTap(_ sender: UIButton) {
        let feedbackText = feedBackTextView.text ?? ""
        if feedbackText.isEmpty {
            showToast(message: "Please enter your reason")
        }else{
            submitFeedback?(feedbackText)
            dismiss(animated: true, completion: nil)
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let newLength = currentText.count + text.count - range.length

        return newLength <= maxCharacterCount
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
    static func instantiate() -> FeedbackViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
        return viewController
    }

}
