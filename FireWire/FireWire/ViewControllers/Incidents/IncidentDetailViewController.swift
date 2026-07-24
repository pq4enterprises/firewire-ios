//
//  IncidentDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//  Redesigned incident detail screen (2026 design system) — programmatic layout.
//

import GoogleMaps
import UIKit
import FirebaseAnalytics

protocol IncidentDetailViewDelegate: AnyObject {
    func dataReceived()
    func incidentFavourited(like: Bool)
    func error(message: String)
}

// MARK: - Design tokens

/// Shared design system — see FireWire/Theme/FireWireTheme.swift.
typealias IncidentTheme = FireWireTheme

// MARK: - Unit categorization (presentation only — API sends plain strings)

enum UnitCategory: CaseIterable {
    case engine
    case truckRescue
    case marine
    case chief
    case soc
    case other

    // NOTE: product wants these colors admin-configurable from the portal
    // eventually; until then the mapping is hardcoded here and must stay in
    // sync with the Android UnitCategory implementation.
    static func classify(_ unitName: String) -> UnitCategory {
        let name = unitName.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if name.hasPrefix("MARINE") {
            return .marine
        }

        let socPrefixes = ["SQUAD", "HAZMAT", "RAC", "SOC", "SATELLITE"]
        if socPrefixes.contains(where: { name.hasPrefix($0) }) {
            return .soc
        }

        // Ladders (L-2), tower ladders (TL-7), rescues (RESCUE 3 / RES-3)
        let truckPrefixes = ["L-", "TL-", "RESCUE", "RES-", "LADDER", "TOWER"]
        if truckPrefixes.contains(where: { name.hasPrefix($0) }) {
            return .truckRescue
        }
        if name.first == "L", name.dropFirst().first.map({ $0.isNumber }) == true {
            return .truckRescue
        }
        if name.hasPrefix("TL"), name.dropFirst(2).first.map({ $0.isNumber }) == true {
            return .truckRescue
        }

        let chiefPrefixes = ["BN", "DIV", "CAR"]
        if chiefPrefixes.contains(where: { name.hasPrefix($0) }) {
            return .chief
        }

        if name.hasPrefix("E-") || name.hasPrefix("ENGINE") {
            return .engine
        }
        if name.first == "E", name.dropFirst().first.map({ $0.isNumber }) == true {
            return .engine
        }

        return .other
    }

    var chipBackground: UIColor {
        switch self {
        case .engine: return FireWireTheme.unitEngineBackground
        case .truckRescue: return FireWireTheme.unitTruckRescueBackground
        case .marine: return FireWireTheme.unitMarineBackground
        case .chief: return FireWireTheme.unitChiefBackground
        case .soc: return FireWireTheme.unitSOCBackground
        case .other: return FireWireTheme.unitOtherBackground
        }
    }

    var chipText: UIColor {
        switch self {
        case .engine: return FireWireTheme.unitEngineText
        case .truckRescue: return FireWireTheme.unitTruckRescueText
        case .marine: return FireWireTheme.unitMarineText
        case .chief: return FireWireTheme.unitChiefText
        case .soc: return FireWireTheme.unitSOCText
        case .other: return FireWireTheme.unitOtherText
        }
    }

    var legendColor: UIColor {
        switch self {
        case .engine: return FireWireTheme.unitEngineBackground
        case .truckRescue: return FireWireTheme.unitTruckRescueBackground
        case .marine: return FireWireTheme.unitMarineBackground
        case .chief: return FireWireTheme.unitChiefBackground
        case .soc: return FireWireTheme.unitSOCLegend
        case .other: return FireWireTheme.unitOtherText
        }
    }

    var legendTitle: String {
        switch self {
        case .engine: return "ENGINE"
        case .truckRescue: return "TRUCK/RES"
        case .marine: return "MARINE"
        case .chief: return "CHIEF"
        case .soc: return "SOC"
        case .other: return "OTHER"
        }
    }
}

// MARK: - Small layout helpers

// PaddedLabel now lives in FireWire/Theme/FireWireTheme.swift as FWPaddedLabel
// (typealias PaddedLabel preserved there).

/// Lays out chip views left-to-right, wrapping to new rows as needed.
final class ChipFlowView: UIView {
    var spacing: CGFloat = 5

    private var lastLaidOutWidth: CGFloat = 0
    private var computedHeight: CGFloat = 0

    func setChips(_ views: [UIView]) {
        subviews.forEach { $0.removeFromSuperview() }
        views.forEach { addSubview($0) }
        lastLaidOutWidth = 0
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for chip in subviews {
            let size = chip.intrinsicContentSize
            if x > 0, x + size.width > bounds.width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            chip.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        let newHeight = subviews.isEmpty ? 0 : y + rowHeight
        if newHeight != computedHeight || lastLaidOutWidth != bounds.width {
            computedHeight = newHeight
            lastLaidOutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: computedHeight)
    }
}

/// The Hybrid / Street / Satellite pill control overlaid on the map card.
final class MapTypeSelector: UIView {
    var onSelectionChanged: ((Int) -> Void)?

    private var buttons: [UIButton] = []
    private(set) var selectedIndex = 0

    init(titles: [String]) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        layer.cornerRadius = 9
        layer.masksToBounds = true

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
        ])

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            button.layer.cornerRadius = 7
            button.layer.masksToBounds = true
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
        updateSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setSelectedIndex(_ index: Int) {
        selectedIndex = index
        updateSelection()
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        updateSelection()
        onSelectionChanged?(selectedIndex)
    }

    private func updateSelection() {
        for button in buttons {
            let isSelected = button.tag == selectedIndex
            button.backgroundColor = isSelected ? .white : .clear
            button.setTitleColor(isSelected ? UIColor(rgb: 0x15161B) : .white, for: .normal)
        }
    }
}

// MARK: - View controller

class IncidentDetailViewController: UIViewController, IncidentDetailViewDelegate {
    var coordinator: HomeCoordinator?
    var viewModel: IncidentDetailViewModel?

    private var selectedIncidentID: String?
    private var openCommentsSection: Bool = false
    private var isLabelExpanded = false
    private var mapView: GMSMapView!
    // sub-locality from the feed list response; the deployed by-ID API doesn't
    // return the name yet (only the raw id), so the feed passes it through
    private var feedSubLocalityName: String?

    // MARK: Views

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let levelBadge = PaddedLabel()
    private let signalChip = PaddedLabel()
    private let subLocalityLabel = UILabel()
    private let incidentDateTime = UILabel()
    private let incidentAddressTitle = UILabel()
    private let incidentSubTitle = UILabel()
    private let incidentDesc = UILabel()
    private let incidentImageView = UIImageView()

    private let mapCard = UIView()
    private let mapContainer = UIView()
    private let mapAddressChip = UIView()
    private let mapAddressLabel = UILabel()
    private let mapTypeSelector = MapTypeSelector(titles: ["HYBRID", "STREET", "SATELLITE"])

    private let unitsCard = UIView()
    private let unitsCountBadge = PaddedLabel()
    private let unitsLegendStack = UIStackView()
    private let unitsChipsView = ChipFlowView()
    private let unitsEmptyLabel = UILabel()

    private let favouriteButton = UIButton(type: .system)
    private let incidentFavourites = UILabel()
    private let commentButton = UIButton(type: .system)
    private let incidentComments = UILabel()
    private let shareBarButton = UIButton(type: .system)

    // MARK: Lifecycle

    func setSelectedIncidentID(_ id: String, _ openComments: Bool, subLocalityName: String? = nil) {
        selectedIncidentID = id
        openCommentsSection = openComments
        feedSubLocalityName = subLocalityName
        viewModel = IncidentDetailViewModel()
        viewModel?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        FWLoaderView.shared.showLoader(on: view)

        NotificationCenter.default.addObserver(self, selector: #selector(newCommentAdded(_:)), name: .newCommentAdded, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .newCommentAdded, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_incident_details"
        ])

        if let selectedIncidentID {
            viewModel?.getIncidentDetail(for: selectedIncidentID)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CGColor-based borders don't auto-update with dark mode
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            [summaryCard, mapCard, unitsCard].forEach {
                $0.layer.borderColor = IncidentTheme.hairline.cgColor
            }
        }
    }

    @objc func newCommentAdded(_ notification: Notification) {
        if let selectedIncidentID {
            viewModel?.getIncidentDetail(for: selectedIncidentID)
        }
    }

    // MARK: UI construction

    private let summaryCard = UIView()

    private func buildUI() {
        view.backgroundColor = IncidentTheme.background

        buildHeaderBar()
        buildBottomBar()
        buildScrollContent()
        buildSummaryCard()
        buildMapCard()
        buildUnitsCard()
    }

    private var headerBar = UIView()
    private var bottomBar = UIView()

    private func buildHeaderBar() {
        headerBar.backgroundColor = IncidentTheme.surface
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        let hairline = UIView()
        hairline.backgroundColor = IncidentTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(hairline)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" BACK", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.tintColor = IncidentTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "INCIDENT"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = IncidentTheme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        let shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = IncidentTheme.text
        shareButton.addTarget(self, action: #selector(shareButtonTap), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(shareButton)

        let feedButton = UIButton(type: .system)
        // Canonical scanner glyph — identical to the home header's treatment.
        feedButton.setImage(
            UIImage(systemName: "radio",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)),
            for: .normal)
        feedButton.tintColor = IncidentTheme.text
        feedButton.addTarget(self, action: #selector(feedButtonTap), for: .touchUpInside)
        feedButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(feedButton)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),

            hairline.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            backButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: -14),

            feedButton.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -10),
            feedButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            feedButton.widthAnchor.constraint(equalToConstant: 44),
            feedButton.heightAnchor.constraint(equalToConstant: 44),

            shareButton.trailingAnchor.constraint(equalTo: feedButton.leadingAnchor),
            shareButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func buildBottomBar() {
        bottomBar.backgroundColor = IncidentTheme.surface
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let hairline = UIView()
        hairline.backgroundColor = IncidentTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(hairline)

        favouriteButton.setImage(FWImage.favIcon?.withRenderingMode(.alwaysTemplate), for: .normal)
        favouriteButton.tintColor = IncidentTheme.text
        favouriteButton.addTarget(self, action: #selector(likeButtonTap), for: .touchUpInside)

        incidentFavourites.font = .systemFont(ofSize: 13, weight: .bold)
        incidentFavourites.textColor = IncidentTheme.text
        incidentFavourites.text = "0"
        incidentFavourites.isUserInteractionEnabled = true
        incidentFavourites.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(likeButtonTap)))

        commentButton.setImage(UIImage(systemName: "bubble.left"), for: .normal)
        commentButton.tintColor = IncidentTheme.text
        commentButton.addTarget(self, action: #selector(commentButtonTap), for: .touchUpInside)

        incidentComments.font = .systemFont(ofSize: 13, weight: .bold)
        incidentComments.textColor = IncidentTheme.text
        incidentComments.text = "0"
        incidentComments.isUserInteractionEnabled = true
        incidentComments.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(commentButtonTap)))

        var shareConfig = UIButton.Configuration.filled()
        shareConfig.baseBackgroundColor = IncidentTheme.red
        shareConfig.baseForegroundColor = .white
        shareConfig.cornerStyle = .large
        shareConfig.image = UIImage(systemName: "square.and.arrow.up")
        shareConfig.imagePadding = 7
        shareConfig.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 18, bottom: 9, trailing: 18)
        shareConfig.attributedTitle = AttributedString(
            "SHARE",
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 15, weight: .heavy)]))
        shareBarButton.configuration = shareConfig
        shareBarButton.setContentHuggingPriority(.required, for: .horizontal)
        shareBarButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        shareBarButton.addTarget(self, action: #selector(shareButtonTap), for: .touchUpInside)

        let actionsRow = UIStackView(arrangedSubviews: [
            favouriteButton, incidentFavourites, commentButton, incidentComments, UIView(), shareBarButton,
        ])
        actionsRow.axis = .horizontal
        actionsRow.alignment = .center
        actionsRow.spacing = 7
        actionsRow.setCustomSpacing(22, after: incidentFavourites)
        actionsRow.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(actionsRow)

        let watermark = UILabel()
        watermark.text = "FIRE WIRE · @NYCFIREWIRE"
        watermark.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        watermark.textColor = IncidentTheme.muted
        watermark.textAlignment = .center
        watermark.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(watermark)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hairline.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            hairline.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            actionsRow.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            actionsRow.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 14),
            actionsRow.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -14),
            actionsRow.heightAnchor.constraint(equalToConstant: 40),

            watermark.topAnchor.constraint(equalTo: actionsRow.bottomAnchor, constant: 2),
            watermark.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            watermark.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
        ])

        favouriteButton.setContentHuggingPriority(.required, for: .horizontal)
        incidentFavourites.setContentHuggingPriority(.required, for: .horizontal)
        commentButton.setContentHuggingPriority(.required, for: .horizontal)
        incidentComments.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func buildScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24),
        ])
    }

    private func buildSummaryCard() {
        IncidentTheme.cardStyle(summaryCard)
        contentStack.addArrangedSubview(summaryCard)

        levelBadge.font = .systemFont(ofSize: 12, weight: .heavy)
        levelBadge.textColor = .white
        levelBadge.backgroundColor = IncidentTheme.red
        levelBadge.layer.cornerRadius = 8
        levelBadge.layer.masksToBounds = true
        levelBadge.insets = UIEdgeInsets(top: 6, left: 11, bottom: 6, right: 11)
        levelBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        signalChip.font = .systemFont(ofSize: 11, weight: .heavy)
        signalChip.textColor = IncidentTheme.red
        signalChip.backgroundColor = IncidentTheme.redTint
        signalChip.layer.cornerRadius = 8
        signalChip.layer.masksToBounds = true
        signalChip.insets = UIEdgeInsets(top: 6, left: 9, bottom: 6, right: 9)
        signalChip.isHidden = true
        signalChip.setContentCompressionResistancePriority(.required, for: .horizontal)

        subLocalityLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subLocalityLabel.textColor = IncidentTheme.text
        subLocalityLabel.numberOfLines = 1
        subLocalityLabel.adjustsFontSizeToFitWidth = true
        subLocalityLabel.minimumScaleFactor = 0.7
        subLocalityLabel.baselineAdjustment = .alignCenters
        subLocalityLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        subLocalityLabel.isHidden = true

        incidentDateTime.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        incidentDateTime.textColor = IncidentTheme.muted
        incidentDateTime.textAlignment = .right
        incidentDateTime.setContentCompressionResistancePriority(.required, for: .horizontal)

        let badgesRow = UIStackView(arrangedSubviews: [levelBadge, signalChip, subLocalityLabel, UIView(), incidentDateTime])
        badgesRow.axis = .horizontal
        badgesRow.alignment = .center
        badgesRow.spacing = 8

        incidentAddressTitle.font = .systemFont(ofSize: 22, weight: .heavy)
        incidentAddressTitle.textColor = IncidentTheme.text
        incidentAddressTitle.numberOfLines = 2
        incidentAddressTitle.adjustsFontSizeToFitWidth = true
        incidentAddressTitle.minimumScaleFactor = 0.7

        incidentSubTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        incidentSubTitle.textColor = IncidentTheme.muted
        incidentSubTitle.numberOfLines = 1
        incidentSubTitle.isHidden = true

        incidentDesc.font = .systemFont(ofSize: 13.5, weight: .semibold)
        incidentDesc.textColor = IncidentTheme.text
        incidentDesc.numberOfLines = 3
        incidentDesc.isUserInteractionEnabled = true
        incidentDesc.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleLabel)))

        let textStack = UIStackView(arrangedSubviews: [incidentAddressTitle, incidentSubTitle, incidentDesc])
        textStack.axis = .vertical
        textStack.spacing = 6

        incidentImageView.contentMode = .scaleAspectFill
        incidentImageView.layer.cornerRadius = 12
        incidentImageView.layer.masksToBounds = true
        incidentImageView.backgroundColor = IncidentTheme.surface2
        incidentImageView.isHidden = true
        NSLayoutConstraint.activate([
            incidentImageView.widthAnchor.constraint(equalToConstant: 95),
            incidentImageView.heightAnchor.constraint(equalToConstant: 111),
        ])

        let bodyRow = UIStackView(arrangedSubviews: [textStack, incidentImageView])
        bodyRow.axis = .horizontal
        bodyRow.alignment = .top
        bodyRow.spacing = 12

        let cardStack = UIStackView(arrangedSubviews: [badgesRow, bodyRow])
        cardStack.axis = .vertical
        cardStack.spacing = 10
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 14),
            cardStack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -14),
            cardStack.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -14),
        ])
    }

    private func buildMapCard() {
        IncidentTheme.cardStyle(mapCard)
        mapCard.layer.masksToBounds = true
        mapCard.heightAnchor.constraint(equalToConstant: 166).isActive = true
        contentStack.addArrangedSubview(mapCard)

        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        mapCard.addSubview(mapContainer)

        mapAddressChip.backgroundColor = UIColor(white: 0, alpha: 0.55)
        mapAddressChip.layer.cornerRadius = 8
        mapAddressChip.layer.masksToBounds = true
        mapAddressChip.translatesAutoresizingMaskIntoConstraints = false
        mapCard.addSubview(mapAddressChip)

        let pinIcon = UIImageView(image: UIImage(systemName: "mappin"))
        pinIcon.tintColor = .white
        pinIcon.contentMode = .scaleAspectFit
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        mapAddressChip.addSubview(pinIcon)

        mapAddressLabel.font = .systemFont(ofSize: 12, weight: .bold)
        mapAddressLabel.textColor = .white
        mapAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        mapAddressChip.addSubview(mapAddressLabel)

        mapTypeSelector.translatesAutoresizingMaskIntoConstraints = false
        mapTypeSelector.onSelectionChanged = { [weak self] index in
            self?.mapTypeChanged(to: index)
        }
        mapCard.addSubview(mapTypeSelector)

        NSLayoutConstraint.activate([
            mapContainer.topAnchor.constraint(equalTo: mapCard.topAnchor),
            mapContainer.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor),
            mapContainer.bottomAnchor.constraint(equalTo: mapCard.bottomAnchor),

            mapAddressChip.topAnchor.constraint(equalTo: mapCard.topAnchor, constant: 10),
            mapAddressChip.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor, constant: 10),
            mapAddressChip.trailingAnchor.constraint(lessThanOrEqualTo: mapCard.trailingAnchor, constant: -10),

            pinIcon.leadingAnchor.constraint(equalTo: mapAddressChip.leadingAnchor, constant: 8),
            pinIcon.centerYAnchor.constraint(equalTo: mapAddressChip.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 12),
            pinIcon.heightAnchor.constraint(equalToConstant: 14),

            mapAddressLabel.leadingAnchor.constraint(equalTo: pinIcon.trailingAnchor, constant: 5),
            mapAddressLabel.trailingAnchor.constraint(equalTo: mapAddressChip.trailingAnchor, constant: -9),
            mapAddressLabel.topAnchor.constraint(equalTo: mapAddressChip.topAnchor, constant: 5),
            mapAddressLabel.bottomAnchor.constraint(equalTo: mapAddressChip.bottomAnchor, constant: -5),

            mapTypeSelector.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor, constant: -8),
            mapTypeSelector.bottomAnchor.constraint(equalTo: mapCard.bottomAnchor, constant: -8),
        ])
    }

    private func buildUnitsCard() {
        IncidentTheme.cardStyle(unitsCard)
        contentStack.addArrangedSubview(unitsCard)

        let unitsTitle = UILabel()
        unitsTitle.text = "UNITS"
        unitsTitle.font = .systemFont(ofSize: 15, weight: .heavy)
        unitsTitle.textColor = IncidentTheme.text

        unitsCountBadge.font = .systemFont(ofSize: 12, weight: .heavy)
        unitsCountBadge.textColor = .white
        unitsCountBadge.backgroundColor = IncidentTheme.red
        unitsCountBadge.layer.cornerRadius = 6
        unitsCountBadge.layer.masksToBounds = true
        unitsCountBadge.insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        unitsCountBadge.isHidden = true
        unitsCountBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        unitsCountBadge.setContentHuggingPriority(.required, for: .horizontal)

        unitsTitle.setContentCompressionResistancePriority(.required, for: .horizontal)

        unitsLegendStack.axis = .horizontal
        unitsLegendStack.spacing = 10
        unitsLegendStack.alignment = .center
        for category in [UnitCategory.engine, .truckRescue, .marine, .chief, .soc] {
            unitsLegendStack.addArrangedSubview(makeLegendItem(category))
        }
        unitsLegendStack.addArrangedSubview(UIView())

        let headerRow = UIStackView(arrangedSubviews: [unitsTitle, unitsCountBadge, UIView()])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8

        unitsEmptyLabel.text = "NO UNITS LISTED"
        unitsEmptyLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        unitsEmptyLabel.textColor = IncidentTheme.muted
        unitsEmptyLabel.isHidden = true

        let cardStack = UIStackView(arrangedSubviews: [headerRow, unitsLegendStack, unitsChipsView, unitsEmptyLabel])
        cardStack.axis = .vertical
        cardStack.spacing = 9
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        unitsCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: unitsCard.topAnchor, constant: 12),
            cardStack.leadingAnchor.constraint(equalTo: unitsCard.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: unitsCard.trailingAnchor, constant: -14),
            cardStack.bottomAnchor.constraint(equalTo: unitsCard.bottomAnchor, constant: -13),
        ])
    }

    private func makeLegendItem(_ category: UnitCategory) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = category.legendColor
        swatch.layer.cornerRadius = 2
        NSLayoutConstraint.activate([
            swatch.widthAnchor.constraint(equalToConstant: 8),
            swatch.heightAnchor.constraint(equalToConstant: 8),
        ])

        let label = UILabel()
        label.text = category.legendTitle
        label.font = .systemFont(ofSize: 9.5, weight: .bold)
        label.textColor = IncidentTheme.muted

        let stack = UIStackView(arrangedSubviews: [swatch, label])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }

    private func makeUnitChip(_ unitName: String) -> UIView {
        let category = UnitCategory.classify(unitName)
        let chip = PaddedLabel()
        chip.text = unitName
        chip.font = .systemFont(ofSize: 12, weight: .bold)
        chip.textColor = category.chipText
        chip.backgroundColor = category.chipBackground
        chip.layer.cornerRadius = 7
        chip.layer.masksToBounds = true
        chip.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return chip
    }

    // MARK: Data binding

    func updateUI() {
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }

        levelBadge.text = incidentDetail.field1Value?.uppercased() ?? ""

        let signal = incidentDetail.field4Value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        signalChip.text = signal.uppercased()
        signalChip.isHidden = signal.isEmpty

        let subLocality = (incidentDetail.subLocalityName ?? feedSubLocalityName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        subLocalityLabel.text = subLocality.uppercased()
        subLocalityLabel.isHidden = subLocality.isEmpty

        if let formattedDate = FWDateFormatter().formatDateString(incidentDetail.createdAt) {
            incidentDateTime.text = formattedDate.uppercased()
        }

        incidentAddressTitle.text = incidentDetail.address.uppercased()
        mapAddressLabel.text = incidentDetail.address.uppercased()

        let subtitle = incidentDetail.field3Value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        incidentSubTitle.text = subtitle.uppercased()
        incidentSubTitle.isHidden = subtitle.isEmpty

        incidentDesc.text = incidentDetail.field2Value?.uppercased() ?? ""

        incidentDetail.isLiked
            ? favouriteButton.setImage(FWImage.favIconSelected?.withRenderingMode(.alwaysOriginal), for: .normal)
            : favouriteButton.setImage(FWImage.favIcon?.withRenderingMode(.alwaysTemplate), for: .normal)

        if mapView == nil {
            let mapManager = MapManager()
            mapView = mapManager.setupMapView(frame: mapContainer.bounds)
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mapView.mapType = .hybrid
            mapTypeSelector.setSelectedIndex(0)
            mapManager.addMarkers(mapModel: viewModel?.markersList ?? [])
            mapContainer.addSubview(mapView)

            // focus on first marker (the incident itself)
            if let markers = viewModel?.markersList, !markers.isEmpty {
                let camera = GMSCameraPosition.camera(withTarget: markers[0].coordinates, zoom: 17.0)
                mapView.animate(to: camera)
            }
        }

        if let imageUrlString = incidentDetail.featuredImageUrl, let imageUrl = URL(string: imageUrlString) {
            incidentImageView.isHidden = false
            incidentImageView.loadImage(from: imageUrl)
        } else {
            incidentImageView.isHidden = true
        }

        incidentFavourites.text = "\(incidentDetail.likeCount)"
        incidentComments.text = "\(incidentDetail.commentCount)"

        let units = incidentDetail.respondingUnits?
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty } ?? []
        unitsCountBadge.text = "\(units.count)"
        unitsCountBadge.isHidden = units.isEmpty
        unitsEmptyLabel.isHidden = !units.isEmpty
        unitsLegendStack.isHidden = units.isEmpty
        unitsChipsView.setChips(units.map { makeUnitChip($0) })

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

        if openCommentsSection {
            openCommentsSection = false
            commentButtonTap()
        }
    }

    func fitMarkersToMap() {
        guard let viewModel, !viewModel.markersList.isEmpty else { return }

        var bounds = GMSCoordinateBounds()

        for item in viewModel.markersList {
            let position = CLLocationCoordinate2D(latitude: item.coordinates.latitude, longitude: item.coordinates.longitude)
            bounds = bounds.includingCoordinate(position)
        }

        // Update the camera position to fit the markers with a padding
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50.0)
        mapView.animate(with: update)
    }

    // MARK: Actions

    @objc func toggleLabel() {
        if isLabelExpanded {
            incidentDesc.numberOfLines = 3
        } else {
            incidentDesc.numberOfLines = 0
        }
        isLabelExpanded.toggle()
    }

    @objc func backButtonTap() {
        coordinator?.popView()
    }

    @objc func likeButtonTap() {
        showLoader()
        let value = viewModel?.incidentDetail?.isLiked == true ? true : false
        viewModel?.favouriteIncident(like: value)
    }

    @objc func commentButtonTap() {
        if let selectedIncidentID {
            let selectedIncidentComments = SelectedIncidentCommentsModel(incidentID: selectedIncidentID)
            coordinator?.navigateToIncidentComments(selectedIncidentComments)
        }
    }

    @objc func shareButtonTap() {
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }

        let shareContent = "\(incidentDetail.field1Value ?? "") \n\(incidentDetail.address)"
        shareContentToSocialMedia(text: shareContent)
    }

    func shareContentToSocialMedia(text: String, image: UIImage? = nil) {
        var items: [Any] = [text]

        if let imageToShare = image {
            items.append(imageToShare)
        }

        if let iosUrl = URL(string: String.appStoreUrl) {
            items.append("Download the app on iOS: \(iosUrl)")
        }

        if let androidUrl = URL(string: String.playStoreUrl) {
            items.append("Download the app on Android: \(androidUrl)")
        }

        // Create an instance of UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Exclude certain activity types if needed (optional)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact, .airDrop]

        present(activityViewController, animated: true)
    }

    func mapTypeChanged(to index: Int) {
        guard mapView != nil else { return }
        switch index {
        case 0:
            mapView.mapType = .hybrid
        case 1:
            mapView.mapType = .normal
        case 2:
            mapView.mapType = .satellite
        default:
            mapView.mapType = .normal
        }
    }

    @objc func feedButtonTap() {
        coordinator?.navigateToFeeds()
    }

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> IncidentDetailViewController {
        return IncidentDetailViewController()
    }
}

// MARK: View model delegates

extension IncidentDetailViewController {
    func dataReceived() {
        FWLoaderView.shared.hideLoader()
        updateUI()
        viewModel?.postIncidentDetailViewCount()
    }

    func incidentFavourited(like: Bool) {
        hideLoader()
        viewModel?.incidentDetail?.isLiked = like
        like
            ? favouriteButton.setImage(FWImage.favIconSelected?.withRenderingMode(.alwaysOriginal), for: .normal)
            : favouriteButton.setImage(FWImage.favIcon?.withRenderingMode(.alwaysTemplate), for: .normal)

        if let currentLikeCount = viewModel?.incidentDetail?.likeCount {
            viewModel?.incidentDetail?.likeCount = max(0, currentLikeCount + (like ? 1 : -1))
        }

        let likeCount = viewModel?.incidentDetail?.likeCount ?? 0
        incidentFavourites.text = "\(likeCount)"
    }

    func error(message: String) {
        FWLoaderView.shared.hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }
}
