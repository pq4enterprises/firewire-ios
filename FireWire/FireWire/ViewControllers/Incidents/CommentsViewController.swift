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
    func error(message: String)
}

class CommentsViewController: UIViewController, CommentsListViewDelegate, UITextFieldDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var commentsListCount: UILabel!
    @IBOutlet var noCommentsLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addCommentTextField: UITextField!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var previewImageCollectionView: UICollectionView!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var commentsView: FWView!

    var coordinator: HomeCoordinator?
    var viewModel: CommentsListViewModel!
    var attachedImages: [UIImage] = []
    var paginationHandler: PaginationHandler<CommentsListViewModel>!

    private var selectedIncidentID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        addCommentTextField.delegate = self
        setupView()
        setupActions()
        setupKeyboardActions()
        setupTableView()
    }

    func setupView() {
        previewImageCollectionView.register(CommentsImageViewItem.nib(), forCellWithReuseIdentifier: CommentsImageViewItem.identifier)

        commentsView.setTopShadow()

        if attachedImages.count > 0 {
            collectionViewHeightConstraint.constant = 100.0
            previewImageCollectionView.dataSource = self
            previewImageCollectionView.delegate = self
            previewImageCollectionView.isHidden = false

            if let layout = previewImageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = .horizontal
                layout.itemSize = CGSize(width: 80, height: 80) // Set item size
            }
            previewImageCollectionView.reloadData()
        } else {
            collectionViewHeightConstraint.constant = 0
            previewImageCollectionView.isHidden = true
        }
    }

    func setSelectedIncidentID(_ id: String) {
        selectedIncidentID = id
        viewModel = CommentsListViewModel()
        viewModel?.delegate = self

        paginationHandler = PaginationHandler(viewModel: viewModel)
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

        commentsListCount.text = "\(viewModel.totalPages) Comments"
        tableView.reloadData()
    }

    func noCommentsForIncident() {
        showActivityIndicator(false)
        tableView.isHidden = true
        commentsListCount.isHidden = true
        noCommentsLabel.isHidden = false
    }

    func commentAdded() {
        hideLoader()
    }

    func error(message: String) {
        showAlertMessage(message)
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
        postComment()
        return true
    }

    func postComment() {
        if let image = attachedImages.count > 0 ? attachedImages[0] : nil {
            showLoader()
            viewModel.requestImageUpload(image) { imageUrl in
                self.hideLoader()
                self.comment(withImage: imageUrl)
            }
        } else {
            comment(withImage: nil)
        }
    }

    func comment(withImage urlString: String?) {
        guard let commentMessage = addCommentTextField.text, !commentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlertMessage("Comments cannot be empty")
            return
        }

        showLoader()
        let requestModel = AddCommentRequestModel(
            userId: FWUserDefaults().userID ?? "",
            incidentId: selectedIncidentID ?? "",
            type: "comment",
            comment: commentMessage,
            img: urlString ?? ""
        )

        viewModel.addComment(requestModel)

        // Clear text, hide keyboard, and reset UI
        addCommentTextField.text = ""
        addCommentTextField.resignFirstResponder()
        attachedImages.removeAll()
        collectionViewHeightConstraint.constant = 0
    }

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    // TODO: Handle in common place
    func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @IBAction func cameraButtonTap(_ sender: UIButton) {
        dismiss(animated: true)
        coordinator?.navigateToTakePicture(forIncident: selectedIncidentID ?? "")
    }

    @IBAction func sendButtonTap(_ sender: UIButton) {
        postComment()
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        if contentHeight - scrollOffset <= screenHeight {
            // Load the next page when the user scrolls to the bottom
            paginationHandler.loadNextPage()
        }
    }

    static func instantiate() -> CommentsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        return viewController
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentsListViewCell.identifier, for: indexPath) as! CommentsListViewCell
        cell.setupView(viewModel.items[indexPath.row])
        return cell
    }
}

extension CommentsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentsImageViewItem.identifier, for: indexPath) as! CommentsImageViewItem
        cell.configure(with: attachedImages[indexPath.row])

        return cell
    }
}
