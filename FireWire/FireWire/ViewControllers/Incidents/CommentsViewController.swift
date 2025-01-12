//
//  CommentsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import UIKit

protocol CommentsListViewDelegate: AnyObject {
    func dataReceived()
    func noCommentsForIncident()
    func commentAdded()
}

class CommentsViewController: UIViewController, CommentsListViewDelegate, UITextFieldDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var commentsListCount: UILabel!
    @IBOutlet weak var noCommentsLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var addCommentTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var coordinator: IncidentsCoordinator?
    var viewModel: CommentsListViewModel!
    private var selectedIncidentID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        addCommentTextField.delegate = self
        setupActions()
        setupKeyboardActions()
        setupTableView()
    }

    func setSelectedIncidentID(_ id: String) {
        selectedIncidentID = id
        viewModel = CommentsListViewModel()
        viewModel?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showActivityIndicator(true)
        if let selectedIncidentID {
            viewModel?.getCommentsList(for: selectedIncidentID)
        }
    }

    func setupActions() {
        hideKeyboardWhenTappedAround()
    }

    func dataReceived() {
        showActivityIndicator(false)
        tableView.isHidden = false
        commentsListCount.isHidden = false
        noCommentsLabel.isHidden = true

        commentsListCount.text = "\(viewModel.commentsList.count) Comments"
        tableView.reloadData()
    }

    func noCommentsForIncident() {
        showActivityIndicator(false)
        tableView.isHidden = true
        commentsListCount.isHidden = true
        noCommentsLabel.isHidden = false
    }

    func commentAdded() {
        if let selectedIncidentID {
            viewModel?.getCommentsList(for: selectedIncidentID)
        }
    }

    func showActivityIndicator(_ value: Bool) {
        if value {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(CommentsListViewCell.nib(), forCellReuseIdentifier: CommentsListViewCell.identifier)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let requestModel = AddCommentRequestModel(
            userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
            incidentId: selectedIncidentID ?? "",
            type: "comment",
            comment: textField.text ?? "",
            url: ""
        )

        viewModel.addComment(requestModel)
        textField.text = ""
        textField.resignFirstResponder()
        return true
    }

    // TODO: Handle in common place
    func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    
    @IBAction func cameraButtonTap(_ sender: UIButton) {
        self.dismiss(animated: true)
        coordinator?.navigateToTakePicture()
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

    static func instantiate() -> CommentsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        return viewController
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.commentsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentsListViewCell.identifier, for: indexPath) as! CommentsListViewCell
        cell.setupView(viewModel.commentsList[indexPath.row])
        return cell
    }
}
