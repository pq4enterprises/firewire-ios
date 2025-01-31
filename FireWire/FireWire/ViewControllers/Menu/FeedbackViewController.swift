//
//  FeedbackViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 31/01/25.
//

import UIKit

class FeedbackViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var feedbackView: FWView!
    @IBOutlet weak var feedBackTextView: UITextView!

    private let maxCharacterCount = 100
    var submitFeedback: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        submitFeedback?(feedbackText)
        dismiss(animated: true, completion: nil)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let newLength = currentText.count + text.count - range.length

        return newLength <= maxCharacterCount
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> FeedbackViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
        return viewController
    }

}
