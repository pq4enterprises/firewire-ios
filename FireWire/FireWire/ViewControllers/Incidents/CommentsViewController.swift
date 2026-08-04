//
//  CommentsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//  Redesigned comments screen (2026 design system) — programmatic layout.
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

    // MARK: UI

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout())
    private let noCommentsLabel = UILabel()

    private let previewImageCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout())
    private var collectionViewHeightConstraint: NSLayoutConstraint!

    private let composerView = UIView()
    private let cameraButton = UIButton(type: .system)
    private let inputContainer = UIView()
    private let addCommentTextView = UITextView()
    private let sendButton = UIButton(type: .system)

    /// Uppercase placeholder shown in the composer (design system is
    /// all-uppercase; the legacy sentence-case copy lives in String.Comments).
    private static let placeholderText = String.Comments.addAComment.uppercased()

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
        buildLayout()
        addCommentTextView.delegate = self
        setupView()
        setupActions()
        setupCollectionView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Layout (2026 design system)

    private func buildLayout() {
        view.backgroundColor = FireWireTheme.background

        // Header bar
        headerView.backgroundColor = FireWireTheme.surface
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let headerHairline = UIView()
        headerHairline.backgroundColor = FireWireTheme.hairline
        headerHairline.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerHairline)

        var backConfig = UIButton.Configuration.plain()
        backConfig.image = UIImage(
            systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
        backConfig.attributedTitle = AttributedString(
            "BACK",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .kern: 0.3,
            ]))
        backConfig.imagePadding = 3
        backConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 8)
        backButton.configuration = backConfig
        backButton.tintColor = FireWireTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)

        titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.textAlignment = .center
        titleLabel.attributedText = Self.kerned("COMMENTS", kern: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Comments list
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        noCommentsLabel.font = FireWireTheme.sectionTitleFont()
        noCommentsLabel.textColor = FireWireTheme.muted
        noCommentsLabel.textAlignment = .center
        noCommentsLabel.attributedText = Self.kerned("NO COMMENTS FOUND", kern: 0.5)
        noCommentsLabel.isHidden = true
        noCommentsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noCommentsLabel)

        // Composer
        composerView.backgroundColor = FireWireTheme.surface
        composerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composerView)

        let composerHairline = UIView()
        composerHairline.backgroundColor = FireWireTheme.hairline
        composerHairline.translatesAutoresizingMaskIntoConstraints = false
        composerView.addSubview(composerHairline)

        // Attached-image preview strip (sits above the composer controls)
        previewImageCollectionView.backgroundColor = .clear
        previewImageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        composerView.addSubview(previewImageCollectionView)
        collectionViewHeightConstraint = previewImageCollectionView.heightAnchor.constraint(equalToConstant: 0)
        collectionViewHeightConstraint.isActive = true

        cameraButton.setImage(
            UIImage(systemName: "camera",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)),
            for: .normal)
        cameraButton.tintColor = FireWireTheme.text
        cameraButton.layer.borderWidth = 1
        cameraButton.layer.borderColor = FireWireTheme.hairline.cgColor
        cameraButton.layer.cornerRadius = 12
        cameraButton.addTarget(self, action: #selector(cameraButtonTap), for: .touchUpInside)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        composerView.addSubview(cameraButton)

        inputContainer.backgroundColor = FireWireTheme.surface2
        inputContainer.layer.cornerRadius = 23
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        composerView.addSubview(inputContainer)

        addCommentTextView.backgroundColor = .clear
        addCommentTextView.font = .systemFont(ofSize: 14, weight: .medium)
        addCommentTextView.text = Self.placeholderText
        addCommentTextView.textColor = FireWireTheme.muted
        addCommentTextView.textContainerInset = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
        addCommentTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(addCommentTextView)

        sendButton.setImage(
            UIImage(systemName: "paperplane.fill",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)),
            for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = FireWireTheme.red
        sendButton.layer.cornerRadius = 23
        sendButton.addTarget(self, action: #selector(sendButtonTap), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        composerView.addSubview(sendButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 54),

            headerHairline.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerHairline.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerHairline.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerHairline.heightAnchor.constraint(equalToConstant: 1),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 4),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: composerView.topAnchor),

            noCommentsLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            noCommentsLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),

            // The composer tracks the keyboard so insets/scroll stay correct.
            composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            composerHairline.leadingAnchor.constraint(equalTo: composerView.leadingAnchor),
            composerHairline.trailingAnchor.constraint(equalTo: composerView.trailingAnchor),
            composerHairline.topAnchor.constraint(equalTo: composerView.topAnchor),
            composerHairline.heightAnchor.constraint(equalToConstant: 1),

            previewImageCollectionView.topAnchor.constraint(equalTo: composerView.topAnchor, constant: 8),
            previewImageCollectionView.leadingAnchor.constraint(equalTo: composerView.leadingAnchor, constant: 12),
            previewImageCollectionView.trailingAnchor.constraint(equalTo: composerView.trailingAnchor, constant: -12),

            cameraButton.leadingAnchor.constraint(equalTo: composerView.leadingAnchor, constant: 12),
            cameraButton.topAnchor.constraint(equalTo: previewImageCollectionView.bottomAnchor, constant: 8),
            cameraButton.bottomAnchor.constraint(equalTo: composerView.bottomAnchor, constant: -10),
            cameraButton.widthAnchor.constraint(equalToConstant: 46),
            cameraButton.heightAnchor.constraint(equalToConstant: 46),

            inputContainer.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 10),
            inputContainer.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 46),

            addCommentTextView.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            addCommentTextView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            addCommentTextView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 6),
            addCommentTextView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -6),

            sendButton.leadingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: composerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 46),
            sendButton.heightAnchor.constraint(equalToConstant: 46),
        ])
    }

    static func kerned(_ text: String, kern: CGFloat) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.kern: kern])
    }

    @objc private func backButtonTap() {
        dismiss(animated: true)
    }

    func setupView() {
        previewImageCollectionView.register(CommentsImageViewItem.nib(), forCellWithReuseIdentifier: CommentsImageViewItem.identifier)

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

        collectionView.bounces = false

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
        collectionView.isHidden = false
        noCommentsLabel.isHidden = true

        // To update notification count in incident detail screen after adding a comment
        postNotification()

        let countText = "\(viewModel.totalPages) \(viewModel.totalPages == 1 ? "Comment" : "Comments")"
        titleLabel.attributedText = Self.kerned(countText.uppercased(), kern: 1)
        applySnapshot(with: viewModel.items)
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

        collectionView.isHidden = true
        titleLabel.attributedText = Self.kerned("COMMENTS", kern: 1)
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
        var layoutConfig = UICollectionLayoutListConfiguration(appearance: .plain)
        layoutConfig.showsSeparators = false
        layoutConfig.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: layoutConfig)

        collectionView.collectionViewLayout = layout
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self

        collectionView.register(FWCommentCell.self, forCellWithReuseIdentifier: FWCommentCell.identifier)

        dataSource = UICollectionViewDiffableDataSource<Section, CommentsData>(collectionView: collectionView) { collectionView, indexPath, item in

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FWCommentCell.identifier,
                for: indexPath
            ) as! FWCommentCell
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
            .foregroundColor: FireWireTheme.text,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == Self.placeholderText {
            textView.text = ""
            textView.textColor = FireWireTheme.text
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = Self.placeholderText
            textView.textColor = FireWireTheme.muted

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
            textView.text = Self.placeholderText
            textView.textColor = FireWireTheme.muted
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
        if commentMessage == Self.placeholderText {
            commentMessage = ""
        }

        let isCommentEmpty = commentMessage == nil || commentMessage == Self.placeholderText || commentMessage!.isEmpty
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
        addCommentTextView.text = Self.placeholderText
        addCommentTextView.textColor = FireWireTheme.muted
        addCommentTextView.resignFirstResponder()
        attachedImages.removeAll()
        collectionViewHeightConstraint.constant = 0
    }

    @objc func cameraButtonTap() {
        dismiss(animated: true)

        let selectedComments = SelectedIncidentCommentsModel(
            incidentID: selectedIncidentID ?? "",
            commentParentID: selectedParentID,
            mentionsUserID: mentionsUserID,
            mentionsUserName: mentionsUserName
        )

        coordinator?.navigateToTakePicture(forIncidentComments: selectedComments)
    }

    @objc func sendButtonTap() {
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

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> CommentsViewController {
        return CommentsViewController()
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

    func showFullscreenImage(_ imageUrl: String) {
        let previewVC = ImagePreviewViewController()
        previewVC.imageUrl = imageUrl
        previewVC.modalPresentationStyle = .overFullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        present(previewVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == self.collectionView,
              let comment = dataSource.itemIdentifier(for: indexPath) else { return }

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

        let isOwnComment = commentsDetail.userID?.id == FWUserDefaults().userID

        // Reporting your own comment is not a thing (matches Android)
        if !isOwnComment {
            let report = UIAlertAction(title: "Report Comment", style: .default) { _ in
                self.showLoader()
                self.viewModel.reportComment(commentID: commentsDetail.id)
            }
            actionSheetController.addAction(report)
        }

        // Moderators delete any comment; authors can delete their own
        if FWUserDefaults().isAdminUser() || isOwnComment {
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

// MARK: - Comment row cell (2026 design system, programmatic)

final class FWCommentCell: UICollectionViewCell {
    static let identifier = "FWCommentCell"

    private let avatarView = FWRoundedImageView()
    private let nameLabel = UILabel()
    private let dateTimeLabel = UILabel()
    private let overflowButton = UIButton(type: .system)
    private let bodyLabel = UILabel()
    private let imagesStack = UIStackView()
    private let replyButton = UIButton(type: .system)
    private let repliesView = UIStackView()
    private let repliesIcon = UIImageView()
    private let repliesCountLabel = UILabel()
    private let separator = UIView()

    private var leadingConstraint: NSLayoutConstraint!
    private var imagesHeightConstraint: NSLayoutConstraint!

    private var model: CommentsData!
    var commentsAction: ((CommentsData) -> Void)?
    var imageTapHandler: ((String) -> Void)?
    var replyAction: ((CommentsData) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarView)

        nameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        nameLabel.textColor = FireWireTheme.text
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        dateTimeLabel.font = .monospacedSystemFont(ofSize: 10.5, weight: .semibold)
        dateTimeLabel.textColor = FireWireTheme.muted
        dateTimeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateTimeLabel)

        overflowButton.setImage(
            UIImage(systemName: "ellipsis",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)),
            for: .normal)
        overflowButton.tintColor = FireWireTheme.red
        overflowButton.transform = CGAffineTransform(rotationAngle: .pi / 2)
        overflowButton.addTarget(self, action: #selector(commentsActionTap), for: .touchUpInside)
        overflowButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overflowButton)

        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyLabel)

        imagesStack.axis = .horizontal
        imagesStack.spacing = 8
        imagesStack.alignment = .leading
        imagesStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imagesStack)

        replyButton.setAttributedTitle(
            NSAttributedString(string: "REPLY", attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: FireWireTheme.muted,
                .kern: 0.3,
            ]), for: .normal)
        replyButton.addTarget(self, action: #selector(replyActionTap), for: .touchUpInside)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(replyButton)

        repliesIcon.image = UIImage(
            systemName: "bubble.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        repliesIcon.tintColor = FireWireTheme.muted

        repliesCountLabel.font = .systemFont(ofSize: 12, weight: .bold)
        repliesCountLabel.textColor = FireWireTheme.muted

        repliesView.axis = .horizontal
        repliesView.spacing = 7
        repliesView.alignment = .center
        repliesView.addArrangedSubview(repliesIcon)
        repliesView.addArrangedSubview(repliesCountLabel)
        repliesView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(repliesView)

        separator.backgroundColor = FireWireTheme.hairline
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        leadingConstraint = avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14)
        imagesHeightConstraint = imagesStack.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            leadingConstraint,
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 42),
            avatarView.heightAnchor.constraint(equalToConstant: 42),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 11),
            nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            dateTimeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            dateTimeLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            overflowButton.leadingAnchor.constraint(equalTo: dateTimeLabel.trailingAnchor, constant: 4),
            overflowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            overflowButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            overflowButton.widthAnchor.constraint(equalToConstant: 32),
            overflowButton.heightAnchor.constraint(equalToConstant: 32),

            bodyLabel.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            bodyLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 11),

            imagesStack.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            imagesStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -14),
            imagesStack.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            imagesHeightConstraint,

            replyButton.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            replyButton.topAnchor.constraint(equalTo: imagesStack.bottomAnchor, constant: 4),
            replyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            replyButton.heightAnchor.constraint(equalToConstant: 32),

            repliesView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            repliesView.centerYAnchor.constraint(equalTo: replyButton.centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    func setupView(_ model: CommentsData) {
        self.model = model

        leadingConstraint.constant = 14 + CGFloat(model.depth * 20)

        let userName = "\(model.userID?.firstName ?? "") \(model.userID?.lastName ?? "")"
        nameLabel.text = userName.uppercased()

        if let profileImage = model.userID?.img, let imageUrl = URL(string: profileImage) {
            avatarView.image = nil
            avatarView.backgroundColor = FireWireTheme.surface2
            avatarView.contentMode = .scaleAspectFill
            avatarView.tintColor = nil
            avatarView.loadImage(from: imageUrl)
        } else {
            avatarView.backgroundColor = FireWireTheme.redTint
            avatarView.contentMode = .center
            avatarView.tintColor = FireWireTheme.red
            avatarView.image = UIImage(
                systemName: "person.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        }

        bodyLabel.attributedText = styledComment(model.comment.uppercased())

        imagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let imageUrls = (model.img ?? []).filter { !$0.isEmpty }
        if imageUrls.isEmpty {
            imagesHeightConstraint.constant = 0
            imagesStack.isHidden = true
        } else {
            imagesHeightConstraint.constant = 80
            imagesStack.isHidden = false
            for url in imageUrls {
                let imageView = UIImageView()
                imageView.backgroundColor = FireWireTheme.surface2
                imageView.contentMode = .scaleAspectFill
                imageView.layer.cornerRadius = 12
                imageView.clipsToBounds = true
                imageView.isUserInteractionEnabled = true
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
                if let imageUrl = URL(string: url) {
                    imageView.loadImage(from: imageUrl)
                }
                let tap = FWCommentImageTap(target: self, action: #selector(imageTapped(_:)))
                tap.imageUrl = url
                imageView.addGestureRecognizer(tap)
                imagesStack.addArrangedSubview(imageView)
            }
        }

        if let formattedDate = FWDateFormatter().formatDateString(model.createdAt) {
            dateTimeLabel.text = formattedDate.uppercased()
        } else {
            dateTimeLabel.text = nil
        }

        if model.depth == 0 {
            let count = model.replies?.count ?? 0
            repliesCountLabel.attributedText = CommentsViewController.kerned(
                "\(count) \(count == 1 ? "REPLY" : "REPLIES")", kern: 0.3)
            repliesView.isHidden = false
        } else {
            repliesView.isHidden = true
        }
    }

    @objc private func replyActionTap() {
        replyAction?(model)
    }

    @objc private func commentsActionTap() {
        commentsAction?(model)
    }

    @objc private func imageTapped(_ gesture: FWCommentImageTap) {
        if let url = gesture.imageUrl {
            imageTapHandler?(url)
        }
    }

    func styledComment(_ text: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3

        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: FireWireTheme.text,
            .paragraphStyle: paragraph,
        ])

        // Regex to find mentions (words starting with @)
        let regex = try! NSRegularExpression(pattern: "@\\w+", options: [])

        let range = NSRange(location: 0, length: (text as NSString).length)
        let matches = regex.matches(in: text, options: [], range: range)

        for match in matches {
            attributed.addAttributes([
                .foregroundColor: UIColor.systemBlue,
                .font: UIFont.boldSystemFont(ofSize: 14)
            ], range: match.range)
        }

        return attributed
    }
}

/// Tap recognizer carrying the tapped comment-image URL.
private final class FWCommentImageTap: UITapGestureRecognizer {
    var imageUrl: String?
}
