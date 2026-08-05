//
//  ProfileViewController.swift
//  FireWire
//
//  2026 redesign (programmatic UIKit, FireWireTheme) — merged "My Account"
//  profile screen with the subscription paywall folded in. Replaces both the
//  old MyAccountViewController and the standalone SubscriptionInfoViewController:
//  every premium gate now routes here (pushed from the menu, or presented
//  modally as the paywall).
//
//  The StoreKit purchase / restore / receipt-submission flow is reused
//  verbatim from the old screens: SubscriptionManager.fetchProducts /
//  purchaseMyProduct / restorePurchases and MyAccountViewModel.submitPayment
//  (api/app/payment) + getUserProfile role refresh.
//

import StoreKit
import UIKit
import FirebaseAnalytics

class ProfileViewController: UIViewController, SubscriptionManagerDelegate, MyAccountViewDelegate {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    /// True when presented modally as the paywall gate (the paths that used to
    /// present the old SubscriptionInfoViewController).
    var isModalPaywall = false

    var viewModel: MyAccountViewModel?

    // MARK: Gold card palette (fixed in both light and dark, per mockup)

    private enum Gold {
        static let top = UIColor(rgb: 0xF7D97A)
        static let bottom = UIColor(rgb: 0xF2C64B)
        static let ink = UIColor(rgb: 0x1A1206)
        static let mutedInk = UIColor(rgb: 0x5B4A12)
        static let dash = UIColor(red: 120 / 255, green: 80 / 255, blue: 10 / 255, alpha: 0.45)
        static let separator = UIColor(red: 120 / 255, green: 80 / 255, blue: 10 / 255, alpha: 0.28)
    }

    // MARK: Views

    private let headerBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let avatarCircle = UIView()
    private let avatarImageView = FWRoundedImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()

    private let premiumCard = FWGoldCardView()
    private let premiumStack = UIStackView()

    /// Card-styled views whose CGColor borders need refreshing on theme change.
    private var borderedViews: [UIView] = []
    private var rowActions: [() -> Void] = []

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()

        Task {
            await SubscriptionManager.shared.fetchProducts()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUserInfo()
        updatePremiumInfo()

        showLoader()
        viewModel = MyAccountViewModel()
        viewModel?.delegate = self
        viewModel?.getUserProfile(forSubscription: false)

        SubscriptionManager.shared.delegate = self
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
        buildProfileHeader()
        buildPremiumCard()
        buildAccountRows()
    }

    private func buildHeaderBar() {
        headerBar.backgroundColor = .clear
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        let backButton = UIButton(type: .system)
        if isModalPaywall {
            backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            backButton.setTitle(" CLOSE", for: .normal)
        } else {
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            backButton.setTitle(" BACK", for: .normal)
        }
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.tintColor = FireWireTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "MY ACCOUNT"
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 52),

            backButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
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

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    // MARK: Profile header (avatar / name / email / UPDATE PROFILE)

    private func buildProfileHeader() {
        let headerRow = UIView()

        avatarCircle.backgroundColor = FireWireTheme.redTint
        avatarCircle.layer.cornerRadius = 35
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

        nameLabel.font = .systemFont(ofSize: 21, weight: .bold)
        nameLabel.textColor = FireWireTheme.text

        emailLabel.font = .systemFont(ofSize: 13, weight: .medium)
        emailLabel.textColor = FireWireTheme.muted

        let updateProfileButton = UIButton(type: .system)
        updateProfileButton.setTitle("UPDATE PROFILE", for: .normal)
        updateProfileButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        updateProfileButton.tintColor = FireWireTheme.red
        updateProfileButton.contentHorizontalAlignment = .leading
        updateProfileButton.addTarget(self, action: #selector(updateProfileTap), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel, updateProfileButton])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5
        textStack.translatesAutoresizingMaskIntoConstraints = false

        headerRow.addSubview(avatarCircle)
        headerRow.addSubview(textStack)

        NSLayoutConstraint.activate([
            avatarCircle.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor, constant: 4),
            avatarCircle.topAnchor.constraint(equalTo: headerRow.topAnchor, constant: 12),
            avatarCircle.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: -20),
            avatarCircle.widthAnchor.constraint(equalToConstant: 70),
            avatarCircle.heightAnchor.constraint(equalToConstant: 70),

            avatarIcon.centerXAnchor.constraint(equalTo: avatarCircle.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarCircle.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 40),
            avatarIcon.heightAnchor.constraint(equalToConstant: 40),

            avatarImageView.topAnchor.constraint(equalTo: avatarCircle.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarCircle.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarCircle.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarCircle.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatarCircle.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: headerRow.trailingAnchor, constant: -4),
            textStack.centerYAnchor.constraint(equalTo: avatarCircle.centerYAnchor),
        ])

        contentStack.addArrangedSubview(headerRow)
    }

    // MARK: Premium card (merged subscription paywall)

    private func buildPremiumCard() {
        premiumStack.axis = .vertical
        premiumStack.spacing = 0
        premiumStack.translatesAutoresizingMaskIntoConstraints = false
        premiumCard.addSubview(premiumStack)

        NSLayoutConstraint.activate([
            premiumStack.topAnchor.constraint(equalTo: premiumCard.topAnchor, constant: 24),
            premiumStack.leadingAnchor.constraint(equalTo: premiumCard.leadingAnchor, constant: 20),
            premiumStack.trailingAnchor.constraint(equalTo: premiumCard.trailingAnchor, constant: -20),
            premiumStack.bottomAnchor.constraint(equalTo: premiumCard.bottomAnchor, constant: -24),
        ])

        contentStack.addArrangedSubview(premiumCard)
        contentStack.setCustomSpacing(20, after: premiumCard)
    }

    /// Same role check the rest of the app uses (FWUserDefaults userRole).
    private var isBasicUser: Bool {
        FWUserDefaults().userRole == "basic_user"
    }

    func updatePremiumInfo() {
        premiumStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if isBasicUser {
            renderUnsubscribedCard()
        } else {
            renderSubscribedCard()
        }
    }

    private func renderUnsubscribedCard() {
        let priceLabel = UILabel()
        priceLabel.text = SubscriptionManager.shared.monthlyDisplayPrice ?? "$5.99"
        priceLabel.font = .systemFont(ofSize: 46, weight: .heavy)
        priceLabel.textColor = FireWireTheme.darkRed
        priceLabel.textAlignment = .center
        premiumStack.addArrangedSubview(priceLabel)
        premiumStack.setCustomSpacing(2, after: priceLabel)

        let perMonthLabel = UILabel()
        perMonthLabel.attributedText = NSAttributedString(
            string: "PER MONTH",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .kern: 1.0,
                .foregroundColor: Gold.mutedInk,
            ])
        perMonthLabel.textAlignment = .center
        premiumStack.addArrangedSubview(perMonthLabel)
        premiumStack.setCustomSpacing(20, after: perMonthLabel)

        let pitchLabel = UILabel()
        pitchLabel.text = "GET FULL ACCESS WITH A PREMIUM ACCOUNT"
        pitchLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        pitchLabel.textColor = Gold.ink
        pitchLabel.textAlignment = .center
        pitchLabel.numberOfLines = 0
        premiumStack.addArrangedSubview(pitchLabel)
        premiumStack.setCustomSpacing(18, after: pitchLabel)

        appendBenefits()

        let getNowButton = UIButton(type: .system)
        getNowButton.setTitle("GET NOW", for: .normal)
        getNowButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .heavy)
        getNowButton.tintColor = .white
        getNowButton.backgroundColor = FireWireTheme.darkRed
        getNowButton.layer.cornerRadius = 14
        getNowButton.heightAnchor.constraint(equalToConstant: 58).isActive = true
        getNowButton.addTarget(self, action: #selector(getNowTap), for: .touchUpInside)
        premiumStack.addArrangedSubview(getNowButton)
        premiumStack.setCustomSpacing(6, after: getNowButton)

        let restoreButton = UIButton(type: .system)
        restoreButton.setTitle("RESTORE PURCHASES", for: .normal)
        restoreButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        restoreButton.tintColor = Gold.mutedInk
        restoreButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        restoreButton.addTarget(self, action: #selector(restorePurchasesTap), for: .touchUpInside)
        premiumStack.addArrangedSubview(restoreButton)
    }

    private func renderSubscribedCard() {
        // ACTIVE status pill
        let pill = UIView()
        pill.backgroundColor = FireWireTheme.success
        pill.layer.cornerRadius = 13
        pill.translatesAutoresizingMaskIntoConstraints = false

        let dot = UIView()
        dot.backgroundColor = .white
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(dot)

        let pillLabel = UILabel()
        pillLabel.attributedText = NSAttributedString(
            string: "ACTIVE",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
                .kern: 1.0,
                .foregroundColor: UIColor.white,
            ])
        pillLabel.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(pillLabel)

        let pillWrapper = UIView()
        pillWrapper.addSubview(pill)

        NSLayoutConstraint.activate([
            pill.topAnchor.constraint(equalTo: pillWrapper.topAnchor),
            pill.bottomAnchor.constraint(equalTo: pillWrapper.bottomAnchor),
            pill.centerXAnchor.constraint(equalTo: pillWrapper.centerXAnchor),
            pill.heightAnchor.constraint(equalToConstant: 26),

            dot.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 15),
            dot.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),

            pillLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 8),
            pillLabel.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -15),
            pillLabel.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
        ])

        premiumStack.addArrangedSubview(pillWrapper)
        premiumStack.setCustomSpacing(14, after: pillWrapper)

        let titleLabel = UILabel()
        titleLabel.text = "PREMIUM ACCOUNT"
        titleLabel.font = .systemFont(ofSize: 30, weight: .heavy)
        titleLabel.textColor = Gold.ink
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        premiumStack.addArrangedSubview(titleLabel)
        premiumStack.setCustomSpacing(10, after: titleLabel)

        let accessLabel = UILabel()
        accessLabel.attributedText = NSAttributedString(
            string: "YOU HAVE ACCESS TO",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .kern: 0.5,
                .foregroundColor: Gold.mutedInk,
            ])
        accessLabel.textAlignment = .center
        premiumStack.addArrangedSubview(accessLabel)
        premiumStack.setCustomSpacing(18, after: accessLabel)

        appendBenefits()

        let manageButton = UIButton(type: .system)
        manageButton.setTitle("MANAGE SUBSCRIPTION", for: .normal)
        manageButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        manageButton.tintColor = FireWireTheme.darkRed
        manageButton.backgroundColor = .clear
        manageButton.layer.cornerRadius = 14
        manageButton.layer.borderWidth = 2
        manageButton.layer.borderColor = FireWireTheme.darkRed.cgColor
        manageButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        manageButton.addTarget(self, action: #selector(manageSubscriptionTap), for: .touchUpInside)
        premiumStack.addArrangedSubview(manageButton)
    }

    private let benefits = [
        "LIVE SCANNER FEEDS",
        "AD-FREE APP EXPERIENCE",
        "CUSTOM NOTIFICATIONS — UNITS, BOROS & INCIDENT TYPES",
    ]

    private func appendBenefits() {
        for (index, benefit) in benefits.enumerated() {
            let row = UIView()

            let separator = UIView()
            separator.backgroundColor = Gold.separator
            separator.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(separator)

            let check = UIImageView(image: UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .heavy)))
            check.tintColor = FireWireTheme.darkRed
            check.contentMode = .scaleAspectFit
            check.setContentHuggingPriority(.required, for: .horizontal)
            check.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(check)

            let label = UILabel()
            label.text = benefit
            label.font = .systemFont(ofSize: 14, weight: .bold)
            label.textColor = Gold.ink
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(label)

            NSLayoutConstraint.activate([
                separator.topAnchor.constraint(equalTo: row.topAnchor),
                separator.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1),

                check.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                check.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                check.widthAnchor.constraint(equalToConstant: 22),

                label.leadingAnchor.constraint(equalTo: check.trailingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                label.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
                label.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -14),
            ])

            premiumStack.addArrangedSubview(row)
            if index == benefits.count - 1 {
                premiumStack.setCustomSpacing(18, after: row)
            }
        }
    }

    // MARK: Account rows

    private func buildAccountRows() {
        let rows: [(title: String, systemImage: String, action: () -> Void)] = [
            ("EDIT PROFILE", "person", { [weak self] in self?.updateProfileTap() }),
            ("AREAS & ALERTS", "bell", { [weak self] in self?.areasAlertsTap() }),
            ("TERMS OF SERVICE", "doc.text", { [weak self] in
                self?.coordinator?.openURL(APIEndpoints.termsAndConditionUrl)
            }),
            ("PRIVACY POLICY", "doc.text", { [weak self] in
                self?.coordinator?.openURL(APIEndpoints.privacyPolicyUrl)
            }),
            ("SIGN OUT", "rectangle.portrait.and.arrow.right", { [weak self] in self?.signOutTap() }),
        ]

        for (index, row) in rows.enumerated() {
            let card = UIView()
            FireWireTheme.cardStyle(card)
            card.layer.cornerRadius = 14
            borderedViews.append(card)

            let icon = UIImageView(image: UIImage(
                systemName: row.systemImage,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
            icon.tintColor = FireWireTheme.muted
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(icon)

            let label = UILabel()
            label.text = row.title
            label.font = .systemFont(ofSize: 15, weight: .bold)
            label.textColor = FireWireTheme.text
            label.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(label)

            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = FireWireTheme.muted
            chevron.contentMode = .scaleAspectFit
            chevron.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(chevron)

            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(equalToConstant: 60),

                icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 24),

                label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
                label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

                chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            ])

            card.tag = index
            rowActions.append(row.action)
            card.isUserInteractionEnabled = true
            card.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(accountRowTap(_:))))

            contentStack.addArrangedSubview(card)
            contentStack.setCustomSpacing(10, after: card)
        }
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
            avatarImageView.loadImage(from: imageUrl)
        }
    }

    // MARK: Actions

    @objc private func backButtonTap() {
        if isModalPaywall {
            dismiss(animated: true)
        } else {
            coordinator?.popView()
        }
    }

    @objc private func accountRowTap(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, rowActions.indices.contains(index) else { return }
        rowActions[index]()
    }

    @objc private func updateProfileTap() {
        if isModalPaywall {
            dismiss(animated: true) { [weak self] in
                self?.coordinator?.navigateToUpdateProfile()
            }
        } else {
            coordinator?.navigateToUpdateProfile()
        }
    }

    private func areasAlertsTap() {
        if isModalPaywall {
            dismiss(animated: true) { [weak self] in
                self?.coordinator?.navigateToAreasAlerts()
            }
        } else {
            coordinator?.navigateToAreasAlerts()
        }
    }

    private func signOutTap() {
        showAlert(title: "Sign Out", message: "Are you sure you want to sign out?", actions: [UIAlertAction(title: "Sign Out", style: .default, handler: { _ in
            self.clearUserDefaults()
            if self.isModalPaywall {
                self.dismiss(animated: false) {
                    self.appCoordinator?.backToParentCoordinator()
                }
            } else {
                self.appCoordinator?.backToParentCoordinator()
            }
        })], cancel: true)
    }

    // MARK: Subscription (exact same purchase path as the old paywall)

    @objc private func getNowTap() {
        Analytics.logEvent("subscribe_button_tapped", parameters: [
            AnalyticsParameterScreenName: "ios_my_account"
        ])

        Task {
            await SubscriptionManager.shared.purchaseMyProduct()
        }
    }

    @objc private func restorePurchasesTap() {
        Task {
            await SubscriptionManager.shared.restorePurchases()
        }
    }

    @objc private func manageSubscriptionTap() {
        // No in-app management flow existed before; deep-link to the App
        // Store's native subscription management sheet.
        guard let windowScene = view.window?.windowScene else { return }
        Task {
            try? await AppStore.showManageSubscriptions(in: windowScene)
        }
    }

    func purchaseTransactionCompleted(success: Bool, transaction: Transaction?, failureMessage: String?) {
        DispatchQueue.main.async {
            if success {
                self.showLoader()
                self.viewModel?.submitPayment(transaction: transaction)
            } else {
                self.hideLoader()
                // nil message means nothing alert-worthy happened (user cancelled)
                if let failureMessage {
                    self.showAlert(title: "", message: failureMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                }
            }
        }
    }

    func dataLoaded(status: Bool, message: String) {
        hideLoader()
        if status {
            updateUserInfo()
            updatePremiumInfo()
        }

        if !message.isEmpty {
            showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }
    }

    func clearUserDefaults() {
        FWUserDefaults.removeObjectForKey(key: .userIDKey)
        FWUserDefaults.removeObjectForKey(key: .userNameKey)
        FWUserDefaults.removeObjectForKey(key: .userEmailKey)
        FWUserDefaults.removeObjectForKey(key: .userTokenKey)
        // The refresh token was left behind by every sign-out path, so a signed-out
        // device kept a credential that could still mint new access tokens.
        FWUserDefaults.removeObjectForKey(key: .refreshTokenKey)
        FWUserDefaults.removeObjectForKey(key: .userImageKey)
        FWUserDefaults.removeObjectForKey(key: .userRoleKey)
    }

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> ProfileViewController {
        return ProfileViewController()
    }
}

// MARK: - FWGoldCardView

/// Gold gradient card with a dashed border — the premium subscription block.
/// Colors are fixed (not adaptive) to match the mockup in both themes.
private final class FWGoldCardView: UIView {
    private let dashedBorder = CAShapeLayer()

    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let gradient = layer as! CAGradientLayer
        gradient.colors = [
            UIColor(rgb: 0xF7D97A).cgColor,
            UIColor(rgb: 0xF2C64B).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0.2, y: 0)
        gradient.endPoint = CGPoint(x: 0.8, y: 1)
        layer.cornerRadius = 18

        dashedBorder.fillColor = nil
        dashedBorder.strokeColor = UIColor(
            red: 120 / 255, green: 80 / 255, blue: 10 / 255, alpha: 0.45).cgColor
        dashedBorder.lineWidth = 2
        dashedBorder.lineDashPattern = [6, 4]
        layer.addSublayer(dashedBorder)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorder.frame = bounds
        dashedBorder.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 1, dy: 1),
            cornerRadius: 17).cgPath
    }
}
