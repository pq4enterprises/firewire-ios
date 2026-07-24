//
//  MenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//  Redesigned to the 2026 design system (programmatic UIKit, FireWireTheme).
//

import UIKit
import FirebaseAnalytics

class MenuViewController: UIViewController {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    // MARK: Views

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let postButton = UIButton(type: .system)
    private let profileCard = UIView()
    private let profileImageView = FWRoundedImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()

    /// Card-styled views whose CGColor borders need refreshing on theme change.
    private var borderedViews: [UIView] = []

    // MARK: Shortcuts state

    /// One menu shortcut tile: static built-in or server-driven from the Link API.
    private struct ShortcutItem {
        let title: String
        let systemImage: String
        let imageUrl: String?
        let tint: UIColor
        let color: UIColor
        let action: () -> Void
    }

    /// Vertical container that holds the shortcut tile rows so they can be
    /// re-rendered when server links arrive without touching the rest of the menu.
    private let shortcutsStack = UIStackView()
    private var shortcutTileViews: [UIView] = []
    private var shortcutActions: [() -> Void] = []

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        fetchAppLinks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_main_menu"
        ])
        updateUserInfo()
        postButton.isHidden = !FWUserDefaults().isAdminUser()
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
        buildScrollContent()
        buildProfileCard()
        buildShortcuts()
        buildDeleteAccountButton()
    }

    private let headerBar = UIView()

    private func buildHeaderBar() {
        headerBar.backgroundColor = .clear
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        postButton.setTitle("POST", for: .normal)
        postButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        postButton.tintColor = FireWireTheme.text
        postButton.isHidden = true
        postButton.addTarget(self, action: #selector(postButtonTap), for: .touchUpInside)
        postButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(postButton)

        let flameView = UIImageView(image: UIImage(systemName: "flame.fill"))
        flameView.tintColor = FireWireTheme.red
        flameView.contentMode = .scaleAspectFit
        flameView.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(flameView)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.setTitle(" CLOSE", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        closeButton.tintColor = FireWireTheme.text
        closeButton.addTarget(self, action: #selector(closeButtonTap), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(closeButton)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 52),

            postButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 16),
            postButton.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            postButton.heightAnchor.constraint(equalToConstant: 44),

            flameView.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            flameView.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            flameView.widthAnchor.constraint(equalToConstant: 30),
            flameView.heightAnchor.constraint(equalToConstant: 30),

            closeButton.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func buildScrollContent() {
        scrollView.alwaysBounceVertical = true
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
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 6),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func buildProfileCard() {
        FireWireTheme.cardStyle(profileCard)
        borderedViews.append(profileCard)

        let avatarCircle = UIView()
        avatarCircle.backgroundColor = FireWireTheme.redTint
        avatarCircle.layer.cornerRadius = 27
        avatarCircle.clipsToBounds = true
        avatarCircle.translatesAutoresizingMaskIntoConstraints = false

        let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        avatarIcon.tintColor = FireWireTheme.red
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarCircle.addSubview(avatarIcon)

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarCircle.addSubview(profileImageView)

        nameLabel.font = .systemFont(ofSize: 17, weight: .bold)
        nameLabel.textColor = FireWireTheme.text

        emailLabel.font = .systemFont(ofSize: 12, weight: .medium)
        emailLabel.textColor = FireWireTheme.muted

        let myAccountLabel = UILabel()
        myAccountLabel.text = "MY ACCOUNT"
        myAccountLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        myAccountLabel.textColor = FireWireTheme.red

        let textStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel, myAccountLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = FireWireTheme.muted
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        profileCard.addSubview(avatarCircle)
        profileCard.addSubview(textStack)
        profileCard.addSubview(chevron)

        NSLayoutConstraint.activate([
            avatarCircle.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            avatarCircle.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            avatarCircle.widthAnchor.constraint(equalToConstant: 54),
            avatarCircle.heightAnchor.constraint(equalToConstant: 54),

            avatarIcon.centerXAnchor.constraint(equalTo: avatarCircle.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarCircle.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 30),
            avatarIcon.heightAnchor.constraint(equalToConstant: 30),

            profileImageView.topAnchor.constraint(equalTo: avatarCircle.topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: avatarCircle.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: avatarCircle.trailingAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: avatarCircle.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatarCircle.trailingAnchor, constant: 14),
            textStack.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -16),

            chevron.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 8),
            chevron.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
        ])

        profileCard.isUserInteractionEnabled = true
        profileCard.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(myAccountViewTap)))

        contentStack.addArrangedSubview(profileCard)
    }

    private func buildShortcuts() {
        let sectionLabel = UILabel()
        sectionLabel.attributedText = NSAttributedString(
            string: "SHORTCUTS",
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .bold),
                .kern: 1.5,
                .foregroundColor: FireWireTheme.muted,
            ])
        contentStack.setCustomSpacing(22, after: profileCard)
        contentStack.addArrangedSubview(sectionLabel)
        contentStack.setCustomSpacing(10, after: sectionLabel)

        shortcutsStack.axis = .vertical
        shortcutsStack.spacing = 12
        contentStack.addArrangedSubview(shortcutsStack)

        // Static tiles render immediately; the Link API response (if any)
        // re-renders the stack with server-driven tiles when it arrives.
        renderShortcuts(staticShortcutItems())
    }

    /// The five built-in tiles — the fallback whenever the Link API fails
    /// or returns no links. Matches the original hardcoded menu exactly.
    private func staticShortcutItems() -> [ShortcutItem] {
        [
            ShortcutItem(
                title: "SUBMIT A TIP", systemImage: "exclamationmark.triangle", imageUrl: nil,
                tint: FireWireTheme.orangeTint, color: FireWireTheme.orange,
                action: { [weak self] in self?.submitTipViewTap() }),
            ShortcutItem(
                title: "CHICAGO PODCAST", systemImage: "mic", imageUrl: nil,
                tint: FireWireTheme.surface2, color: FireWireTheme.text,
                action: { [weak self] in self?.podcastViewTap() }),
            ShortcutItem(
                title: "FIREWIRE WEBSITE", systemImage: "globe", imageUrl: nil,
                tint: FireWireTheme.redTint, color: FireWireTheme.red,
                action: { [weak self] in self?.fireWireViewTap() }),
            ShortcutItem(
                title: "CONTACT", systemImage: "envelope", imageUrl: nil,
                tint: FireWireTheme.infoTint, color: FireWireTheme.info,
                action: { [weak self] in self?.contactViewTap() }),
            areasAlertsShortcutItem(),
        ]
    }

    /// Built-in in-app tile — always kept, appended after any server links.
    private func areasAlertsShortcutItem() -> ShortcutItem {
        ShortcutItem(
            title: "AREAS & ALERTS", systemImage: "bell", imageUrl: nil,
            tint: FireWireTheme.successTint, color: FireWireTheme.success,
            action: { [weak self] in self?.areasAlertsViewTap() })
    }

    /// Maps portal-managed links to external-URL tiles, then appends the
    /// built-in Areas & Alerts tile. Links missing a name or url are skipped.
    private func serverShortcutItems(from links: [AppLinkData]) -> [ShortcutItem] {
        var items: [ShortcutItem] = links.compactMap { link in
            guard let name = link.name, !name.isEmpty,
                  let url = link.url, !url.isEmpty
            else { return nil }

            let imageUrl = (link.imageUrl?.isEmpty == false) ? link.imageUrl : nil
            return ShortcutItem(
                title: name.uppercased(), systemImage: "link", imageUrl: imageUrl,
                tint: FireWireTheme.surface2, color: FireWireTheme.text,
                action: { [weak self] in self?.coordinator?.openURL(url) })
        }

        guard !items.isEmpty else { return [] }
        items.append(areasAlertsShortcutItem())
        return items
    }

    /// Rebuilds the tile grid for an arbitrary item count: the first row holds
    /// up to two large tiles, every following row up to three small tiles
    /// (padded with invisible spacers so tile widths stay consistent).
    private func renderShortcuts(_ items: [ShortcutItem]) {
        guard !items.isEmpty else { return }

        borderedViews.removeAll { view in shortcutTileViews.contains(where: { $0 === view }) }
        shortcutTileViews.removeAll()
        shortcutActions = items.map { $0.action }
        shortcutsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Top row — up to two large tiles
        let topCount = min(2, items.count)
        var topTiles: [UIView] = []
        for index in 0 ..< topCount {
            topTiles.append(shortcutTile(
                item: items[index], index: index,
                circleSize: 56, titleSize: 14, padding: 22))
        }
        addShortcutRow(topTiles, columns: topCount)

        // Remaining rows — up to three small tiles each
        var rowTiles: [UIView] = []
        for index in topCount ..< items.count {
            rowTiles.append(shortcutTile(
                item: items[index], index: index,
                circleSize: 46, titleSize: 11.5, padding: 18))
            if rowTiles.count == 3 {
                addShortcutRow(rowTiles, columns: 3)
                rowTiles = []
            }
        }
        if !rowTiles.isEmpty {
            addShortcutRow(rowTiles, columns: 3)
        }
    }

    private func addShortcutRow(_ tiles: [UIView], columns: Int) {
        var views = tiles
        while views.count < columns {
            views.append(UIView()) // invisible spacer keeps tile widths equal
        }
        let row = UIStackView(arrangedSubviews: views)
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        shortcutsStack.addArrangedSubview(row)
    }

    private func shortcutTile(
        item: ShortcutItem, index: Int,
        circleSize: CGFloat, titleSize: CGFloat, padding: CGFloat
    ) -> UIView {
        let title = item.title
        let systemImage = item.systemImage
        let tint = item.tint
        let color = item.color

        let tile = UIView()
        FireWireTheme.cardStyle(tile)
        borderedViews.append(tile)
        shortcutTileViews.append(tile)

        let circle = UIView()
        circle.backgroundColor = tint
        circle.layer.cornerRadius = circleSize / 2
        circle.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: circleSize * 0.4, weight: .medium)))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(icon)

        // Server-provided icon fills the circle over the SF Symbol placeholder
        if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
            let circleImageView = UIImageView()
            circleImageView.contentMode = .scaleAspectFill
            circleImageView.clipsToBounds = true
            circleImageView.layer.cornerRadius = circleSize / 2
            circleImageView.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(circleImageView)

            NSLayoutConstraint.activate([
                circleImageView.topAnchor.constraint(equalTo: circle.topAnchor),
                circleImageView.leadingAnchor.constraint(equalTo: circle.leadingAnchor),
                circleImageView.trailingAnchor.constraint(equalTo: circle.trailingAnchor),
                circleImageView.bottomAnchor.constraint(equalTo: circle.bottomAnchor),
            ])

            circleImageView.loadImage(from: url)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: titleSize, weight: .bold)
        label.textColor = FireWireTheme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        tile.addSubview(circle)
        tile.addSubview(label)

        NSLayoutConstraint.activate([
            circle.topAnchor.constraint(equalTo: tile.topAnchor, constant: padding),
            circle.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            circle.widthAnchor.constraint(equalToConstant: circleSize),
            circle.heightAnchor.constraint(equalToConstant: circleSize),

            icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            label.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -padding * 0.8),
        ])

        tile.tag = index
        tile.isUserInteractionEnabled = true
        tile.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(shortcutTileTap(_:))))
        return tile
    }

    @objc private func shortcutTileTap(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, shortcutActions.indices.contains(index) else { return }
        shortcutActions[index]()
    }

    private func buildDeleteAccountButton() {
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("DELETE ACCOUNT", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        deleteButton.tintColor = FireWireTheme.red
        deleteButton.addTarget(self, action: #selector(deleteAccountTap), for: .touchUpInside)
        deleteButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        if let lastTile = contentStack.arrangedSubviews.last {
            contentStack.setCustomSpacing(24, after: lastTile)
        }
        contentStack.addArrangedSubview(deleteButton)
    }

    // MARK: Data

    private func updateUserInfo() {
        if let name = FWUserDefaults().userName, let email = FWUserDefaults().userEmail {
            nameLabel.text = name.uppercased()
            emailLabel.text = email
        }

        if let profileImage = FWUserDefaults().userImage,
           let imageUrl = URL(string: profileImage)
        {
            profileImageView.loadImage(from: imageUrl)
        }
    }

    // MARK: Actions

    @objc func myAccountViewTap() {
        coordinator?.navigateToMyAccount()
    }

    @objc func submitTipViewTap() {
        coordinator?.openURL(APIEndpoints.submitTipUrl)
    }

    @objc func podcastViewTap() {
        coordinator?.openURL(APIEndpoints.chicagoPodcastUrl)
    }

    @objc func fireWireViewTap() {
        coordinator?.openURL(APIEndpoints.fireWireUrl)
    }

    @objc func contactViewTap() {
        coordinator?.openURL(APIEndpoints.contactUrl)
    }

    @objc func areasAlertsViewTap() {
        coordinator?.navigateToAreasAlerts()
    }

    @objc func closeButtonTap() {
        coordinator?.navigateBackToHome(popViewToLeft: true)
    }

    @objc func deleteAccountTap() {
        let feedbackView = FeedbackViewController.instantiate()
        feedbackView.modalPresentationStyle = .overFullScreen
        feedbackView.submitFeedback = { feedback in
            self.submitFeedback(reason: feedback)
        }
        present(feedbackView, animated: true)
    }

    @objc func postButtonTap() {
        coordinator?.navigateToPostWebView()
    }

    func clearUserDefaults() {
        FWUserDefaults.removeObjectForKey(key: .userIDKey)
        FWUserDefaults.removeObjectForKey(key: .userNameKey)
        FWUserDefaults.removeObjectForKey(key: .userEmailKey)
        FWUserDefaults.removeObjectForKey(key: .userTokenKey)
        FWUserDefaults.removeObjectForKey(key: .userImageKey)
        FWUserDefaults.removeObjectForKey(key: .userRoleKey)
    }

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> MenuViewController {
        return MenuViewController()
    }
}

// MARK: - API Calls

extension MenuViewController {
    /// Fetches portal-managed shortcut links. Non-blocking: the static tiles
    /// are already on screen; a successful response with at least one valid
    /// link swaps them for server-driven tiles. Any failure or an empty list
    /// silently keeps the static fallback.
    func fetchAppLinks() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.appLinks,
            payload: ["show": "true"] as JSON,
            expect: LinkListResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, error in
            guard let self = self,
                  error == nil,
                  let linkResponse = response as? LinkListResponseModel,
                  let links = linkResponse.data?.data
            else { return }

            let items = self.serverShortcutItems(from: links)
            guard !items.isEmpty else { return }
            self.renderShortcuts(items)
        }
    }

    func submitFeedback(reason: String) {
        showLoader()
        let postFeedbackRequestModel = APIPayload.postReasonToAccountDelete(reason: reason).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            payload: postFeedbackRequestModel as JSON,
            expect: SuccessResponseModel.self,
            requestType: APIConstants.PUT
        ) { [weak self] response, _, _ in
            self?.hideLoader()
            if response is SuccessResponseModel {
                self?.deleteUser()
                self?.clearUserDefaults()
            }
        }
    }

    func deleteUser() {
        showLoader()
        let deleteRequestModel = APIPayload.deleteAccount.toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.deleteAccount,
            payload: deleteRequestModel as JSON,
            expect: SuccessResponseModel.self,
            requestType: APIConstants.PUT
        ) { [weak self] response, _, _ in
            self?.hideLoader()
            if response is SuccessResponseModel {
                self?.showAlert(title: "", message: "Thank you for the feedback. Your account is deleted successfully!", actions: [UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self?.clearUserDefaults()
                    self?.appCoordinator?.backToParentCoordinator()
                })])
            }
        }
    }
}
