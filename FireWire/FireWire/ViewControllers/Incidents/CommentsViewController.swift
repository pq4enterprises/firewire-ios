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
    func showMessage(message: String)
}

enum Section {
    case main
}

class CommentsViewController: UIViewController, CommentsListViewDelegate, UITextViewDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var commentsListCount: UILabel!
    @IBOutlet var noCommentsLabel: UILabel!
    // @IBOutlet var tableView: UITableView!
    @IBOutlet var addCommentTextField: UITextField!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var previewImageCollectionView: UICollectionView!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var commentsView: FWView!
    @IBOutlet var addCommentTextView: UITextView!
    @IBOutlet var collectionView: UICollectionView!

    private var dataSource: UICollectionViewDiffableDataSource<Section, CommentsData>!

    var coordinator: HomeCoordinator?
    var viewModel: CommentsListViewModel!
    var attachedImages: [UIImage] = []
    var paginationHandler: PaginationHandler<CommentsListViewModel>!

    private var selectedIncidentID: String?
    private var selectedParentID: String?
    private var mentionsUserID: String?
    private var mentionsUserName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // addCommentTextField.delegate = self
        addCommentTextView.delegate = self
        setupView()
        setupActions()
        setupKeyboardActions()
        // setupTableView()
        setupCollectionView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func setupView() {
        previewImageCollectionView.register(CommentsImageViewItem.nib(), forCellWithReuseIdentifier: CommentsImageViewItem.identifier)

        commentsView.setTopShadow()

        addCommentTextView.layer.cornerRadius = 5
        addCommentTextView.layer.masksToBounds = true

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

        scrollView.bounces = false
        collectionView.bounces = false
        // tableView.bounces = false

        if let mentionsUserName {
            setMention(for: mentionsUserName)
        }

    }

    func setSelectedIncidentID(_ incidentComments: SelectedIncidentCommentsModel) {
        selectedIncidentID = incidentComments.incidentID

        // Already reply section has been selected so set the selected id from model
        selectedParentID = incidentComments.commentParentID
        mentionsUserID = incidentComments.mentionsUserID
        mentionsUserName = incidentComments.mentionsUserName

        viewModel = CommentsListViewModel()
        viewModel?.delegate = self

        paginationHandler = PaginationHandler(viewModel: viewModel)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showLoader()
        if let selectedIncidentID {
            viewModel?.getCommentsList(for: selectedIncidentID)
        }
    }

    func setupActions() {
        hideKeyboardWhenTappedAround()
    }

    func dataReceived() {
        hideLoader()
        // tableView.isHidden = false
        collectionView.isHidden = false
        commentsListCount.isHidden = false
        noCommentsLabel.isHidden = true

        // To update notification count in incident detail screen after adding a comment
        postNotification()

        commentsListCount.text = "\(viewModel.totalPages) \(viewModel.totalPages == 1 ? "Comment" : "Comments")"
        // tableView.reloadData()
        applySnapshot(with: viewModel.items)
        collectionView.reloadData()
    }

    private func applySnapshot(with comments: [CommentsData]) {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<CommentsData>()

        func addComments(_ comments: [CommentsData], parent: CommentsData? = nil, depth: Int = 0) {
            for var comment in comments {
                comment.depth = depth
                sectionSnapshot.append([comment], to: parent)
                //sectionSnapshot.expand([comment])

                if let replies = comment.replies {
                    addComments(replies, parent: comment, depth: depth + 1)
                }
            }
        }

        let hierarchy = buildCommentHierarchy(from: comments)
        addComments(hierarchy)

        if let parentId = selectedParentID,
           let parentComment = comments.first(where: { $0.id == parentId }) {
            sectionSnapshot.expand([parentComment])

            // Scroll to New reply comment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let replies = parentComment.replies, let lastReply = replies.last,
                   let indexPath = self.dataSource.indexPath(for: lastReply) {
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            }
        }else{
            // Scroll to New top-level comment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.collectionView.numberOfItems(inSection: 0) > 0 {
                    let topIndexPath = IndexPath(item: 0, section: 0)
                    self.collectionView.scrollToItem(at: topIndexPath, at: .top, animated: true)
                }
            }
        }

        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true)
    }

    func buildCommentHierarchy(from allComments: [CommentsData]) -> [CommentsData] {
        var commentMap = [String: CommentsData]()

        // Step A: put everything in a dictionary
        for comment in allComments {
            commentMap[comment.id] = comment
        }

        // Step B: attach replies based on parentId
        var rootComments: [CommentsData] = []

        for comment in allComments {
            if let parentId = comment.parentId, var parent = commentMap[parentId] {
                if parent.replies == nil {
                    parent.replies = []
                }
                parent.replies?.append(comment)
            } else {
                // no parentId → this is a top-level comment
                rootComments.append(comment)
            }
        }

        return rootComments
    }

    @objc func postNotification() {
        NotificationCenter.default.post(name: .newCommentAdded, object: nil, userInfo: nil)
    }

    func noCommentsForIncident() {
        hideLoader()

        // To update notification count in incident detail screen after removing last comment
        postNotification()

        // tableView.isHidden = true
        collectionView.isHidden = true
        commentsListCount.isHidden = true
        noCommentsLabel.isHidden = false
    }

    func commentAdded() {
        hideLoader()
    }

    func showMessage(message: String) {
        hideLoader()
        showAlert(title: message, message: "", actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    func setupCollectionView() {
        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: layoutConfig)

        collectionView.collectionViewLayout = layout
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self

        collectionView.register(CommentsCell.nib(), forCellWithReuseIdentifier: CommentsCell.identifier)

        dataSource = UICollectionViewDiffableDataSource<Section, CommentsData>(collectionView: collectionView) { collectionView, indexPath, item in

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CommentsCell.identifier,
                for: indexPath
            ) as! CommentsCell
            cell.setupView(item)

            cell.replyAction = { commentsDetail in
                if let userName = commentsDetail.userID?.firstName {
                    self.setMention(for: userName)
                    if let _parentId = commentsDetail.parentId {
                        self.selectedParentID = _parentId
                    } else {
                        self.selectedParentID = commentsDetail.id // for first comment
                    }

                    self.mentionsUserID = commentsDetail.userID?.id
                    self.mentionsUserName = userName
                    self.addCommentTextView.becomeFirstResponder()
                }
            }

            cell.commentsAction = { commentsDetail in
                self.showActionSheet(commentsDetail)
            }

            cell.imageTapHandler = { [weak self] image in
                self?.showFullscreenImage(image)
            }

            return cell
        }
    }

    func setMention(for userName: String) {
        let mention = "@\(userName) "
        let attributedText = NSMutableAttributedString(string: mention)

        attributedText.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: mention.count))
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: NSRange(location: 0, length: mention.count))

        addCommentTextView.attributedText = attributedText
        addCommentTextView.selectedRange = NSMakeRange(attributedText.length, 0)

        // Reset attributes
        addCommentTextView.typingAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 14)
        ]
    }

//    func setupTableView() {
//        tableView.delegate = self
//        tableView.dataSource = self
//
//        tableView.showsHorizontalScrollIndicator = false
//        tableView.showsVerticalScrollIndicator = false
//
//        tableView.register(CommentsListViewCell.nib(), forCellReuseIdentifier: CommentsListViewCell.identifier)
//    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == .Comments.addAComment {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = .Comments.addAComment
            textView.textColor = .lightGray

            // reset the selected reply IDs
            selectedParentID = nil
            mentionsUserID = nil
            mentionsUserName = nil
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" { // Detect Return Key
            postComment()
            textView.resignFirstResponder() // Dismiss keyboard
            textView.text = .Comments.addAComment
            textView.textColor = .lightGray
            return false // Prevent adding a new line
        }

        // Limit characters to 100
        let currentText = textView.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)

        return newText.count <= 100
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
        var commentMessage = addCommentTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if commentMessage == .Comments.addAComment {
            commentMessage = ""
        }

        let isCommentEmpty = commentMessage == nil || commentMessage == .Comments.addAComment || commentMessage!.isEmpty
        let isImageEmpty = urlString == nil

        if isCommentEmpty && isImageEmpty {
            showAlert(title: "", message: .Comments.commentsAndImageEmptyMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        showLoader()
        var requestModel = AddCommentRequestModel(
            userId: FWUserDefaults().userID ?? "",
            incidentId: selectedIncidentID ?? "",
            parentId: selectedParentID,
            type: "comment",
            comment: commentMessage ?? "",
            img: urlString ?? ""
        )

        if let mentions = mentionsUserID{
            requestModel.mentions = [mentions]
        }

        viewModel.addComment(requestModel)

        // Clear text, hide keyboard, and reset UI
        addCommentTextView.text = .Comments.addAComment
        addCommentTextView.textColor = .lightGray
        addCommentTextView.resignFirstResponder()
        attachedImages.removeAll()
        collectionViewHeightConstraint.constant = 0
    }

    // TODO: Handle in common place
    func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @IBAction func cameraButtonTap(_ sender: UIButton) {
        dismiss(animated: true)

        let selectedComments = SelectedIncidentCommentsModel(
            incidentID: selectedIncidentID ?? "",
            commentParentID: selectedParentID,
            mentionsUserID: mentionsUserID,
            mentionsUserName: mentionsUserName
        )

        coordinator?.navigateToTakePicture(forIncidentComments: selectedComments)
        //coordinator?.navigateToTakePicture(forIncident: selectedIncidentID ?? "")
    }

    @IBAction func sendButtonTap(_ sender: UIButton) {
        postComment()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        if contentHeight - scrollOffset <= screenHeight {
            paginationHandler.loadNextPage()
        }
    }

    static func instantiate() -> CommentsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        return viewController
    }
}

//extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        viewModel.items.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: CommentsListViewCell.identifier, for: indexPath) as! CommentsListViewCell
//        cell.setupView(viewModel.items[indexPath.row])
//        cell.commentsAction = { commentsDetail in
//            self.showActionSheet(commentsDetail)
//        }
//        cell.imageTapHandler = { [weak self] image in
//            self?.showFullscreenImage(image)
//        }
//        return cell
//    }
//}

extension CommentsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentsImageViewItem.identifier, for: indexPath) as! CommentsImageViewItem
        cell.configure(with: attachedImages[indexPath.row])

        return cell
    }

    func showFullscreenImage(_ imageUrl: String) {
        let previewVC = ImagePreviewViewController()
        previewVC.imageUrl = imageUrl
        previewVC.modalPresentationStyle = .overFullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        present(previewVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let comment = dataSource.itemIdentifier(for: indexPath) else { return }

        var sectionSnapshot = dataSource.snapshot(for: .main)

        if sectionSnapshot.isExpanded(comment) {
            sectionSnapshot.collapse([comment])
        } else {
            sectionSnapshot.expand([comment])
        }

        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true)
    }
}

extension CommentsViewController {
    func showActionSheet(_ commentsDetail: CommentsData) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let report = UIAlertAction(title: "Report Comment", style: .default) { _ in
            self.showLoader()
            self.viewModel.reportComment(commentID: commentsDetail.id)
        }
        actionSheetController.addAction(report)

        if FWUserDefaults().isAdminUser() {
            let delete = UIAlertAction(title: "Delete Comment", style: .default) { _ in
                self.showLoader()
                self.viewModel.deleteComment(commentID: commentsDetail.id)
            }
            actionSheetController.addAction(delete)
        }

        if FWUserDefaults().isAdminUser() {
            if let commentImg = commentsDetail.img, commentImg.count > 0, !commentImg[0].isEmpty, let selectedIncidentID {
                if commentsDetail.featuredImage {
                    let featureImageAction: UIAlertAction = .init(title: "Remove Featured Image", style: .default) { _ in
                        self.showLoader()
                        self.viewModel.setAndRemoveFeatureImage(imageUrl: commentImg[0], commentID: commentsDetail.id, incidentID: selectedIncidentID, set: false)
                    }
                    actionSheetController.addAction(featureImageAction)
                } else {
                    let featureImageAction: UIAlertAction = .init(title: "Set Featured Image", style: .default) { _ in
                        self.showLoader()
                        self.viewModel.setAndRemoveFeatureImage(imageUrl: commentImg[0], commentID: commentsDetail.id, incidentID: selectedIncidentID, set: true)
                    }
                    actionSheetController.addAction(featureImageAction)
                }
            }
        }

        let cancel = UIAlertAction(title: "Cancel", style: .destructive) { _ in }
        actionSheetController.addAction(cancel)

        present(actionSheetController, animated: true)
    }
}

extension CommentsViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height

        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardHeight
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset

        if let textView = commentsView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let textViewFrame = textView.convert(textView.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(textViewFrame, animated: true)

                if self.collectionView.numberOfSections > 0 {
                    let lastSection = max(self.collectionView.numberOfSections - 1, 0)
                    let lastRow = self.collectionView.numberOfItems(inSection: lastSection) - 1

                    if lastRow > 0 {
                        let indexPath = IndexPath(row: lastRow, section: lastSection)
                        self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
}
