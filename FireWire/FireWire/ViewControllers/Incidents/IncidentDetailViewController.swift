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

    /// Black or white by WCAG contrast against the chip background, resolved
    /// per appearance — never a fixed per-category color.
    var chipText: UIColor {
        FireWireTheme.contrastingText(on: chipBackground)
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

/// One legend entry (8pt swatch + label) with an explicit intrinsic size so it
/// can live inside a ChipFlowView and wrap with its siblings.
final class LegendItemView: UIView {
    private let swatch = UIView()
    private let label = UILabel()
    private let dot: CGFloat = 8
    private let gap: CGFloat = 4

    init(title: String, color: UIColor) {
        super.init(frame: .zero)
        swatch.backgroundColor = color
        swatch.layer.cornerRadius = 2
        label.text = title
        label.font = .systemFont(ofSize: 9.5, weight: .bold)
        label.textColor = IncidentTheme.muted
        addSubview(swatch)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        let l = label.intrinsicContentSize
        return CGSize(width: dot + gap + l.width, height: max(dot, l.height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let l = label.intrinsicContentSize
        swatch.frame = CGRect(x: 0, y: (bounds.height - dot) / 2, width: dot, height: dot)
        label.frame = CGRect(x: dot + gap, y: (bounds.height - l.height) / 2, width: l.width, height: l.height)
    }
}

/// The pill control overlaid on the hero map (top-left): the selectable map
/// types (HYBRID / STREET / SATELLITE) followed by locked premium teasers
/// (360 / 3D). Locked segments never take the selection; they only report the
/// tap. Fixed dark-glass styling in both appearances: it always sits on map
/// imagery, never on a themed surface.
final class MapTypeSelector: UIView {
    var onSelectionChanged: ((Int) -> Void)?
    /// Index into `lockedTitles` of the locked segment that was tapped.
    var onLockedSegmentTapped: ((Int) -> Void)?

    /// Font size / horizontal segment padding, roomiest first. `fit(toWidth:)`
    /// picks the first that keeps all segments on one line.
    private static let metricTiers: [(fontSize: CGFloat, padding: CGFloat)] = [(11, 9), (10.5, 6), (10.5, 4)]

    private let titles: [String]
    private let selectableCount: Int
    private var buttons: [UIButton] = []
    private var tier = 0
    private var fittedWidth: CGFloat = -1
    private(set) var selectedIndex = 0

    init(titles: [String], lockedTitles: [String] = []) {
        self.titles = titles + lockedTitles
        selectableCount = titles.count
        super.init(frame: .zero)
        backgroundColor = UIColor(rgb: 0x0F1115).withAlphaComponent(0.85)
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.14).cgColor
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

        for (index, title) in self.titles.enumerated() {
            let button = UIButton(type: .system)
            button.layer.masksToBounds = true
            button.tag = index
            if isLocked(index) {
                button.accessibilityLabel = "\(title), coming soon to Premium"
            }
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
        applyMetrics()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Capsule: the group and each segment are fully rounded.
        layer.cornerRadius = bounds.height / 2
        // (segments are inset 3pt; their own bounds may not be laid out yet)
        buttons.forEach { $0.layer.cornerRadius = max(0, bounds.height - 6) / 2 }
    }

    func setSelectedIndex(_ index: Int) {
        guard index < selectableCount else { return }
        selectedIndex = index
        updateSelection()
    }

    /// Shrinks type and padding (never below 10.5pt bold) until every segment
    /// fits on one line within `width`.
    func fit(toWidth width: CGFloat) {
        guard width > 0, width != fittedWidth else { return }
        fittedWidth = width
        for candidate in Self.metricTiers.indices {
            tier = candidate
            applyMetrics()
            if systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width <= width { break }
        }
    }

    private func isLocked(_ index: Int) -> Bool { index >= selectableCount }

    @objc private func buttonTapped(_ sender: UIButton) {
        if isLocked(sender.tag) {
            // Locked teaser: the current map type stays selected.
            onLockedSegmentTapped?(sender.tag - selectableCount)
            return
        }
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        updateSelection()
        onSelectionChanged?(selectedIndex)
    }

    private func applyMetrics() {
        let padding = Self.metricTiers[tier].padding
        buttons.forEach { $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: padding, bottom: 6, right: padding) }
        updateSelection()
        invalidateIntrinsicContentSize()
    }

    private func updateSelection() {
        let font = UIFont.systemFont(ofSize: Self.metricTiers[tier].fontSize, weight: .bold)
        for button in buttons {
            let index = button.tag
            let isSelected = index == selectedIndex
            button.backgroundColor = isSelected ? FireWireTheme.red : .clear

            let locked = isLocked(index)
            // Locked teasers read slightly muted next to the selectable types.
            let color: UIColor = isSelected ? .white : UIColor(white: 1, alpha: locked ? 0.55 : 0.78)
            let title = NSMutableAttributedString()
            if locked,
               let lock = UIImage(
                   systemName: "lock.fill",
                   withConfiguration: UIImage.SymbolConfiguration(pointSize: font.pointSize - 2.5, weight: .bold)) {
                title.append(NSAttributedString(attachment: NSTextAttachment(
                    image: lock.withTintColor(color, renderingMode: .alwaysOriginal))))
                title.append(NSAttributedString(string: "\u{2009}"))
            }
            title.append(NSAttributedString(string: titles[index]))
            title.addAttributes(
                [.font: font, .foregroundColor: color],
                range: NSRange(location: 0, length: title.length))
            button.setAttributedTitle(title, for: .normal)
        }
    }
}

// MARK: - View controller

class IncidentDetailViewController: UIViewController, IncidentDetailViewDelegate, UIScrollViewDelegate {
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

    /// Premium features teased as locked segments of the map pill. Tapping one
    /// only shows a "Coming soon" alert — nothing is loaded for them (no
    /// Street View is shipped on this screen).
    private enum PremiumTeaser: CaseIterable {
        case view360
        case scene3D

        var segmentTitle: String {
            switch self {
            case .view360: return "360"
            case .scene3D: return "3D"
            }
        }

        /// `feature` parameter of `incident_premium_teaser_tapped`.
        var analyticsValue: String {
            switch self {
            case .view360: return "360"
            case .scene3D: return "3d"
            }
        }

        var message: String {
            switch self {
            case .view360: return "360\u{00B0} street view is coming soon to Fire Wire Premium."
            case .scene3D: return "3D scene view is coming soon to Fire Wire Premium."
            }
        }
    }

    // Map hero: edge-to-edge under the header; the cards scroll over its
    // bottom edge and it collapses to a dimmed strip (never fully hidden).
    private enum Hero {
        /// Expanded map height (reduced on short screens, see `updateHeroMetrics`).
        static let maxHeight: CGFloat = 380
        /// Collapsed strip height.
        static let minHeight: CGFloat = 120
        /// How far the summary card overlaps the map's bottom edge, expanded.
        static let overlap: CGFloat = 56
        /// Same, once the map has collapsed to the strip.
        static let collapsedOverlap: CGFloat = 30
        /// Dim overlay alpha when fully collapsed.
        static let maxDim: CGFloat = 0.45
        /// Space kept clear at the top of the map for the overlay controls.
        static let controlsInset: CGFloat = 44
        /// Opening zoom: as close as possible while the nearest firehouse pin
        /// is still in view, within these limits (17 = the old fixed zoom).
        static let closestZoom: Float = 17
        static let widestZoom: Float = 14
    }

    private let mapContainer = UIView()
    private let mapDimView = UIView()
    private let mapBottomShade = UIView()
    private let mapBottomShadeLayer = CAGradientLayer()
    private let mapTypeSelector = MapTypeSelector(
        titles: ["HYBRID", "STREET", "SATELLITE"],
        lockedTitles: PremiumTeaser.allCases.map(\.segmentTitle))
    /// Clips the scrolling cards to the card column below the map's visible part.
    private let cardsClipView = UIView()
    private var mapHeightConstraint: NSLayoutConstraint!
    private var cardsClipTopConstraint: NSLayoutConstraint!
    private var expandedMapHeight: CGFloat = Hero.maxHeight
    private var mapManager: MapManager?

    private let progressionCard = UIView()
    private let progressionRows = UIStackView()

    private let unitsCard = UIView()
    private let unitsCountBadge = PaddedLabel()
    /// Wrapping legend (a locality may define more categories than fit one row).
    private let unitsLegendStack = ChipFlowView()
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
        NotificationCenter.default.addObserver(
            self, selector: #selector(mapTypePreferenceChanged),
            name: MapTypePreference.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: MapTypePreference.didChangeNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .newCommentAdded, object: nil)
    }

    /// The account-wide default changed (My Account → MAP TYPE). Re-sync this
    /// map and its pill; the pill itself remains a per-screen override.
    @objc private func mapTypePreferenceChanged() {
        applyPreferredMapType()
    }

    private func applyPreferredMapType() {
        guard mapView != nil else { return }
        let preference = MapTypePreference.current
        mapView.mapType = preference.gmsMapType
        mapTypeSelector.setSelectedIndex(preference.selectorIndex)
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
            [summaryCard, progressionCard, unitsCard].forEach {
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
        buildMapHero()
        buildScrollContent()
        buildSummaryCard()
        buildProgressionCard()
        buildUnitsCard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapBottomShadeLayer.frame = mapBottomShade.bounds
        // Keep all five pill segments on one line within the map's side margins.
        mapTypeSelector.fit(toWidth: mapContainer.bounds.width - 24)
        updateHeroMetrics()
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

        // Single-line brand footer, centered and bottom-aligned.
        let watermark = UILabel()
        watermark.numberOfLines = 1
        let watermarkParagraph = NSMutableParagraphStyle()
        watermarkParagraph.alignment = .center
        watermark.attributedText = NSAttributedString(
            string: "FIRE WIRE - THE BRAVEST NEWS NETWORK",
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .bold),
                .kern: 0.5,
                .foregroundColor: IncidentTheme.muted,
                .paragraphStyle: watermarkParagraph,
            ])
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

    private func buildMapHero() {
        mapContainer.backgroundColor = IncidentTheme.surface2
        mapContainer.clipsToBounds = true
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapContainer)

        // Soft shade under the overlapping summary card (the cards themselves
        // are clipped to their column, so they cannot cast a shadow upward).
        mapBottomShade.isUserInteractionEnabled = false
        mapBottomShade.translatesAutoresizingMaskIntoConstraints = false
        mapBottomShadeLayer.colors = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.38).cgColor]
        mapBottomShade.layer.addSublayer(mapBottomShadeLayer)
        mapContainer.addSubview(mapBottomShade)

        // Dims the map as it collapses; the controls stay above it.
        mapDimView.backgroundColor = .black
        mapDimView.alpha = 0
        mapDimView.isUserInteractionEnabled = false
        mapDimView.translatesAutoresizingMaskIntoConstraints = false
        mapContainer.addSubview(mapDimView)

        mapTypeSelector.translatesAutoresizingMaskIntoConstraints = false
        mapTypeSelector.isHidden = true // shown with the map
        mapTypeSelector.onSelectionChanged = { [weak self] index in
            self?.mapTypeChanged(to: index)
        }
        mapTypeSelector.onLockedSegmentTapped = { [weak self] index in
            guard PremiumTeaser.allCases.indices.contains(index) else { return }
            self?.premiumTeaserTapped(PremiumTeaser.allCases[index])
        }
        mapContainer.addSubview(mapTypeSelector)

        mapHeightConstraint = mapContainer.heightAnchor.constraint(equalToConstant: expandedMapHeight)

        NSLayoutConstraint.activate([
            mapContainer.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            mapContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapHeightConstraint,

            mapBottomShade.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor),
            mapBottomShade.trailingAnchor.constraint(equalTo: mapContainer.trailingAnchor),
            mapBottomShade.bottomAnchor.constraint(equalTo: mapContainer.bottomAnchor),
            mapBottomShade.heightAnchor.constraint(equalToConstant: 110),

            mapDimView.topAnchor.constraint(equalTo: mapContainer.topAnchor),
            mapDimView.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor),
            mapDimView.trailingAnchor.constraint(equalTo: mapContainer.trailingAnchor),
            mapDimView.bottomAnchor.constraint(equalTo: mapContainer.bottomAnchor),

            mapTypeSelector.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor, constant: 12),
            mapTypeSelector.topAnchor.constraint(equalTo: mapContainer.topAnchor, constant: 12),
            mapTypeSelector.trailingAnchor.constraint(lessThanOrEqualTo: mapContainer.trailingAnchor, constant: -12),
        ])
    }

    private func buildScrollContent() {
        // The cards live in a column that is clipped (with the cards' own
        // corner radius) just below the visible part of the map. Everything
        // above that line belongs to the map, so the map stays interactive and
        // content never scrolls over the collapsed strip's controls.
        cardsClipView.clipsToBounds = true
        cardsClipView.layer.cornerRadius = 16
        cardsClipView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardsClipView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardsClipView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        cardsClipView.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        cardsClipTopConstraint = cardsClipView.topAnchor.constraint(
            equalTo: mapContainer.bottomAnchor, constant: -Hero.overlap)

        NSLayoutConstraint.activate([
            cardsClipTopConstraint,
            cardsClipView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            cardsClipView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            cardsClipView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            // The scroll view keeps a fixed frame (header → bottom bar) so the
            // content does not jump while the clip line follows the map.
            scrollView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cardsClipView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardsClipView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let restInset = expandedMapHeight - Hero.overlap
        scrollView.contentInset.top = restInset
        scrollView.contentOffset = CGPoint(x: 0, y: -restInset)
    }

    // MARK: Map hero collapse

    /// Picks the expanded map height for this screen (380pt, less on short
    /// devices so the summary card is still on screen) and re-applies the hero.
    private func updateHeroMetrics() {
        let available = bottomBar.frame.minY - headerBar.frame.maxY
        guard available > 0 else { return }
        let target = min(Hero.maxHeight, max(260, floor(available * 0.6)))
        if abs(target - expandedMapHeight) > 0.5 {
            let scrolled = scrollView.contentOffset.y + scrollView.contentInset.top
            expandedMapHeight = target
            let restInset = target - Hero.overlap
            scrollView.contentInset.top = restInset
            scrollView.contentOffset.y = scrolled - restInset
        }
        updateHero()
    }

    /// Drives the map height, the cards' clip line, the dim overlay and the
    /// map padding from the scroll position. The clip line always coincides
    /// with the top of the scrolled content until the map is fully collapsed.
    private func updateHero() {
        guard mapHeightConstraint != nil, cardsClipTopConstraint != nil else { return }
        let expanded = expandedMapHeight
        // 0 at rest, positive once the cards are pushed up, negative on pull-down.
        let scrolled = scrollView.contentOffset.y + scrollView.contentInset.top

        let height: CGFloat
        let overlap: CGFloat
        let progress: CGFloat
        if scrolled <= 0 {
            height = expanded - scrolled // stretch with the pull-down bounce
            overlap = Hero.overlap
            progress = 0
        } else {
            // Scroll distance over which the map goes from expanded to strip.
            let distance = expanded - Hero.overlap + Hero.collapsedOverlap - Hero.minHeight
            progress = min(1, scrolled / max(distance, 1))
            height = expanded - progress * (expanded - Hero.minHeight)
            overlap = Hero.overlap - progress * (Hero.overlap - Hero.collapsedOverlap)
        }

        if abs(mapHeightConstraint.constant - height) > 0.01 {
            mapHeightConstraint.constant = height
        }
        if abs(cardsClipTopConstraint.constant + overlap) > 0.01 {
            cardsClipTopConstraint.constant = -overlap
        }
        mapDimView.alpha = Hero.maxDim * progress

        // Keep the camera target and the Google attribution inside the part of
        // the map that is not covered by the cards or the overlay controls.
        if let mapView {
            let padding = UIEdgeInsets(top: Hero.controlsInset, left: 0, bottom: overlap + 4, right: 0)
            if abs(mapView.padding.bottom - padding.bottom) > 0.5 || mapView.padding.top != padding.top {
                mapView.padding = padding
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        updateHero()
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

    private func buildProgressionCard() {
        IncidentTheme.cardStyle(progressionCard)
        progressionCard.isHidden = true // only once the title has changed
        contentStack.addArrangedSubview(progressionCard)

        let title = UILabel()
        title.text = "INCIDENT PROGRESSION"
        title.font = .systemFont(ofSize: 15, weight: .heavy)
        title.textColor = IncidentTheme.text

        progressionRows.axis = .vertical
        progressionRows.spacing = 0 // rows touch so the connector is continuous

        let cardStack = UIStackView(arrangedSubviews: [title, progressionRows])
        cardStack.axis = .vertical
        cardStack.spacing = 7
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        progressionCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: progressionCard.topAnchor, constant: 12),
            cardStack.leadingAnchor.constraint(equalTo: progressionCard.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: progressionCard.trailingAnchor, constant: -14),
            cardStack.bottomAnchor.constraint(equalTo: progressionCard.bottomAnchor, constant: -9),
        ])
    }

    /// Rows newest first: 24h time, dot + connector, title badge (latest in
    /// brand red, earlier titles muted). Title and timestamp only.
    private func rebuildProgression(_ entries: [ProgressionEntry]) {
        progressionRows.arrangedSubviews.forEach { $0.removeFromSuperview() }
        progressionCard.isHidden = entries.count < 2
        guard entries.count >= 2 else { return }

        let formatter = FWDateFormatter()
        for (index, entry) in entries.enumerated() {
            let isLatest = index == 0

            let time = UILabel()
            time.text = entry.at.flatMap { formatter.formatTimeString($0) } ?? "--:--"
            time.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
            time.textColor = IncidentTheme.muted

            let rail = ProgressionRailView(
                isLatest: isLatest,
                connectsUp: index > 0,
                connectsDown: index < entries.count - 1)

            let badge = PaddedLabel()
            badge.text = (entry.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            badge.font = .systemFont(ofSize: 11, weight: .heavy)
            badge.textColor = isLatest ? .white : IncidentTheme.muted
            badge.backgroundColor = isLatest ? IncidentTheme.red : IncidentTheme.surface2
            badge.layer.cornerRadius = 6
            badge.layer.masksToBounds = true
            badge.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            badge.lineBreakMode = .byTruncatingTail

            let row = UIView()
            [time, rail, badge].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                row.addSubview($0)
            }
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(greaterThanOrEqualToConstant: 34),

                time.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                time.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                time.widthAnchor.constraint(equalToConstant: 42),

                rail.leadingAnchor.constraint(equalTo: time.trailingAnchor, constant: 4),
                rail.topAnchor.constraint(equalTo: row.topAnchor),
                rail.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                rail.widthAnchor.constraint(equalToConstant: 16),

                badge.leadingAnchor.constraint(equalTo: rail.trailingAnchor, constant: 8),
                badge.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                badge.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor),
                badge.topAnchor.constraint(greaterThanOrEqualTo: row.topAnchor, constant: 4),
                badge.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -4),
            ])
            row.isAccessibilityElement = true
            row.accessibilityLabel = "\(time.text ?? ""), \(badge.text ?? "")"
            progressionRows.addArrangedSubview(row)
        }
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

        unitsLegendStack.spacing = 10
        unitsLegendStack.setChips([UnitCategory.engine, .truckRescue, .marine, .chief, .soc].map { makeLegendItem($0) })

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
        makeLegendItem(title: category.legendTitle, color: category.legendColor)
    }

    private func makeLegendItem(title: String, color: UIColor) -> UIView {
        LegendItemView(title: title, color: color)
    }

    /// Chip colors: the server's per-locality scheme when the response carries
    /// `respondingUnitColors` (12.1.2+), otherwise the hardcoded classifier.
    private func makeUnitChip(_ unitName: String, serverColors: [String: UnitColorModel]?) -> UIView {
        let chip = PaddedLabel()
        chip.text = unitName
        chip.font = .systemFont(ofSize: 12, weight: .bold)
        if let serverColors {
            let c = serverColors[unitName]
            let background = FireWireTheme.color(light: c?.bg, dark: c?.bgDark, fallback: UnitCategory.other.chipBackground)
            chip.backgroundColor = background
            // Missing/invalid fg or fgDark → automatic contrast on the actual bg, not gray.
            chip.textColor = FireWireTheme.unitText(
                light: c?.fg, dark: c?.fgDark,
                hasDarkBackground: FireWireTheme.color(fromHex: c?.bgDark) != nil,
                on: background)
        } else {
            let category = UnitCategory.classify(unitName)
            chip.textColor = category.chipText
            chip.backgroundColor = category.chipBackground
        }
        chip.layer.cornerRadius = 7
        chip.layer.masksToBounds = true
        chip.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return chip
    }

    /// Legend from the server scheme (nil = the static classifier legend).
    private func rebuildLegend(server: [UnitLegendModel]?) {
        if let server {
            unitsLegendStack.setChips(server.map { item in
                let color = FireWireTheme.color(light: item.color, dark: item.colorDark, fallback: UnitCategory.other.legendColor)
                return makeLegendItem(title: item.label ?? "", color: color)
            })
        } else {
            unitsLegendStack.setChips([UnitCategory.engine, .truckRescue, .marine, .chief, .soc].map { makeLegendItem($0) })
        }
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

        let subtitle = incidentDetail.field3Value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        incidentSubTitle.text = subtitle.uppercased()
        incidentSubTitle.isHidden = subtitle.isEmpty

        incidentDesc.text = incidentDetail.field2Value?.uppercased() ?? ""

        incidentDetail.isLiked
            ? favouriteButton.setImage(FWImage.favIconSelected?.withRenderingMode(.alwaysOriginal), for: .normal)
            : favouriteButton.setImage(FWImage.favIcon?.withRenderingMode(.alwaysTemplate), for: .normal)

        if mapView == nil {
            let manager = MapManager()
            mapManager = manager
            // setupMapView applies the user's default map type (My Account →
            // MAP TYPE) and the dark map style; the pill on the map is a
            // temporary override for this screen only.
            mapView = manager.setupMapView(frame: mapContainer.bounds)
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mapView.delegate = self
            applyPreferredMapType()
            manager.addMarkers(mapModel: viewModel?.markersList ?? [])
            mapContainer.insertSubview(mapView, at: 0)
            mapTypeSelector.isHidden = false
            updateHero() // map padding for the current scroll position

            // Centered on the incident, zoomed to keep the nearest firehouse in view.
            if let incident = viewModel?.incidentCoordinate ?? viewModel?.markersList.first?.coordinates {
                mapView.camera = GMSCameraPosition(target: incident, zoom: openingZoom(around: incident))
            }
        }

        rebuildProgression(viewModel?.progressionNewestFirst ?? [])

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

        // Server-resolved colors win when present; the legend then comes from the
        // locality's scheme and is hidden when the locality has none (all gray).
        var serverColors: [String: UnitColorModel]? = nil
        if let list = incidentDetail.respondingUnitColors {
            serverColors = Dictionary(list.compactMap { c -> (String, UnitColorModel)? in
                guard let u = c.unit?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !u.isEmpty else { return nil }
                return (u, c)
            }, uniquingKeysWith: { first, _ in first })
            rebuildLegend(server: incidentDetail.unitLegend ?? [])
            unitsLegendStack.isHidden = units.isEmpty || (incidentDetail.unitLegend ?? []).isEmpty
        } else {
            rebuildLegend(server: nil)
            unitsLegendStack.isHidden = units.isEmpty
        }
        unitsChipsView.setChips(units.map { makeUnitChip($0, serverColors: serverColors) })

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

        if openCommentsSection {
            openCommentsSection = false
            commentButtonTap()
        }
    }

    /// The closest zoom (≤ 17) at which the nearest firehouse pin still fits in
    /// the uncovered part of the hero map, never wider than zoom 14.
    private func openingZoom(around incident: CLLocationCoordinate2D) -> Float {
        let distances = (viewModel?.markersList ?? [])
            .filter { $0.markerType == .points }
            .map { GMSGeometryDistance(incident, $0.coordinates) }
        guard let nearest = distances.min(), nearest > 1 else { return Hero.closestZoom }

        // Radius (pt) around the incident that is clear of the controls, the
        // card overlap and the pin's own label.
        let clearHeight = expandedMapHeight - Hero.overlap - Hero.controlsInset
        let radius = max(80, min(view.bounds.width, clearHeight) / 2 - 36)
        let metersPerPointAtZoom0 = 156_543.03392 * cos(incident.latitude * .pi / 180)
        let zoom = log2(metersPerPointAtZoom0 * Double(radius) / nearest)
        guard zoom.isFinite else { return Hero.closestZoom }
        return min(Hero.closestZoom, max(Hero.widestZoom, Float(zoom)))
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

    /// A locked 360 / 3D segment was tapped: the map and the selection are left
    /// alone; basic users also get a route to the paywall.
    private func premiumTeaserTapped(_ teaser: PremiumTeaser) {
        Analytics.logEvent("incident_premium_teaser_tapped", parameters: [
            "feature": teaser.analyticsValue,
        ])
        let alert = UIAlertController(title: "Coming soon", message: teaser.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        if FWUserDefaults().userRole == "basic_user" {
            alert.addAction(UIAlertAction(title: "See Premium", style: .default) { [weak self] _ in
                self?.coordinator?.navigateToSubscriptionInfo()
            })
        }
        present(alert, animated: true)
    }

    /// `action` is "pin" (firehouse pin tapped, callout shown) or "directions"
    /// (callout tapped, maps app opened).
    private func logFirehouseTapped(_ firehouse: MapMarkerModel, action: String) {
        var parameters: [String: Any] = [
            "incident_id": viewModel?.incidentDetail?.id ?? "",
            "firehouse": firehouse.title,
            "action": action,
        ]
        if let miles = firehouse.distanceMiles {
            parameters["distance_miles"] = miles
        }
        Analytics.logEvent("incident_firehouse_tapped", parameters: parameters)
    }

    /// Driving directions to a firehouse: Google Maps when installed, else Apple Maps.
    private func openDirections(to firehouse: MapMarkerModel) {
        let destination = "\(firehouse.coordinates.latitude),\(firehouse.coordinates.longitude)"
        if let probe = URL(string: "comgooglemaps://"), UIApplication.shared.canOpenURL(probe),
           let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "https://maps.apple.com/?daddr=\(destination)&dirflg=d") {
            UIApplication.shared.open(url)
        }
    }

    /// Pill tapped on the hero map. Deliberately NOT persisted — the account
    /// default lives in My Account → MAP TYPE.
    func mapTypeChanged(to index: Int) {
        guard mapView != nil else { return }
        let order = MapTypePreference.selectorOrder
        let preference = order.indices.contains(index) ? order[index] : .standard
        mapView.mapType = preference.gmsMapType
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

// MARK: Map delegate (firehouse pins)

extension IncidentDetailViewController: GMSMapViewDelegate {
    private func firehouseModel(for marker: GMSMarker) -> MapMarkerModel? {
        guard let item = marker.userData as? MapMarkerModel, item.markerType == .points else { return nil }
        return item
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let firehouse = firehouseModel(for: marker) {
            logFirehouseTapped(firehouse, action: "pin")
        }
        return false // default behaviour: center the pin and show its callout
    }

    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        guard let firehouse = firehouseModel(for: marker) else { return nil } // incident pin: stock callout
        return FirehouseCalloutView(
            name: firehouse.title,
            detail: marker.snippet ?? "",
            traits: traitCollection,
            maxWidth: min(260, mapView.bounds.width - 48))
    }

    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        guard let firehouse = firehouseModel(for: marker) else { return }
        logFirehouseTapped(firehouse, action: "directions")
        openDirections(to: firehouse)
    }
}

// MARK: - Progression timeline rail

/// The dot + thin vertical connector between the time and the title badge of
/// one progression row. Rows are stacked with no gap so connectors join up.
final class ProgressionRailView: UIView {
    private let halo = UIView()
    private let dot = UIView()
    private let lineUp = UIView()
    private let lineDown = UIView()
    private let dotSize: CGFloat = 8
    private let haloSize: CGFloat = 14

    init(isLatest: Bool, connectsUp: Bool, connectsDown: Bool) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        [lineUp, lineDown].forEach {
            $0.backgroundColor = FireWireTheme.hairline
            addSubview($0)
        }
        lineUp.isHidden = !connectsUp
        lineDown.isHidden = !connectsDown

        halo.backgroundColor = FireWireTheme.red.withAlphaComponent(0.25)
        halo.layer.cornerRadius = haloSize / 2
        halo.isHidden = !isLatest
        addSubview(halo)

        dot.backgroundColor = isLatest ? FireWireTheme.red : FireWireTheme.muted
        dot.layer.cornerRadius = dotSize / 2
        addSubview(dot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        dot.frame = CGRect(x: center.x - dotSize / 2, y: center.y - dotSize / 2, width: dotSize, height: dotSize)
        halo.frame = CGRect(x: center.x - haloSize / 2, y: center.y - haloSize / 2, width: haloSize, height: haloSize)
        let gap: CGFloat = haloSize / 2 + 2
        lineUp.frame = CGRect(x: center.x - 1, y: 0, width: 2, height: max(0, center.y - gap))
        lineDown.frame = CGRect(x: center.x - 1, y: center.y + gap, width: 2, height: max(0, bounds.height - center.y - gap))
    }
}

// MARK: - Firehouse callout

/// Info window for a firehouse pin: name, "0.4 mi · address" and a DIRECTIONS
/// prompt. Google Maps snapshots this view, so it is sized up front and the
/// tap is handled by `mapView(_:didTapInfoWindowOf:)`.
final class FirehouseCalloutView: UIView {
    init(name: String, detail: String, traits: UITraitCollection, maxWidth: CGFloat) {
        super.init(frame: .zero)
        // Not in a window when snapshotted: pin the appearance explicitly.
        overrideUserInterfaceStyle = traits.userInterfaceStyle
        backgroundColor = FireWireTheme.surface.resolvedColor(with: traits)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = FireWireTheme.hairline.resolvedColor(with: traits).cgColor
        layer.masksToBounds = true

        let nameLabel = UILabel()
        nameLabel.text = name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        nameLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        nameLabel.textColor = FireWireTheme.text.resolvedColor(with: traits)
        nameLabel.numberOfLines = 2

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .systemFont(ofSize: 11.5, weight: .semibold)
        detailLabel.textColor = FireWireTheme.muted.resolvedColor(with: traits)
        detailLabel.numberOfLines = 2
        detailLabel.isHidden = detail.isEmpty

        let directionsLabel = UILabel()
        directionsLabel.text = "DIRECTIONS"
        directionsLabel.font = .systemFont(ofSize: 11, weight: .heavy)
        directionsLabel.textColor = FireWireTheme.red

        let stack = UIStackView(arrangedSubviews: [nameLabel, detailLabel, directionsLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        stack.setCustomSpacing(7, after: detailLabel.isHidden ? nameLabel : detailLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let inset: CGFloat = 11
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: inset - 1),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(inset - 1)),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset + 1),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(inset + 1)),
        ])

        let content = stack.systemLayoutSizeFitting(
            CGSize(width: maxWidth - 2 * (inset + 1), height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel)
        let width = min(maxWidth, max(120, ceil(content.width) + 2 * (inset + 1)))
        let fitted = stack.systemLayoutSizeFitting(
            CGSize(width: width - 2 * (inset + 1), height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        frame = CGRect(x: 0, y: 0, width: width, height: ceil(fitted.height) + 2 * (inset - 1))
        layoutIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - 360° street-level view

/// Full-screen Street View panorama near the incident, with a close button and
/// the address as a caption. Creating the panorama is a billable Maps event.
/// NOT REACHABLE right now: Street View is not shipped (the map pill's 360
/// segment is a locked "coming soon" teaser), so nothing instantiates this.
final class IncidentPanoramaViewController: UIViewController, GMSPanoramaViewDelegate {
    private let coordinate: CLLocationCoordinate2D
    private let caption: String
    private var didOrientCamera = false
    private let statusLabel = UILabel()

    init(coordinate: CLLocationCoordinate2D, caption: String) {
        self.coordinate = coordinate
        self.caption = caption
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let panoramaView = GMSPanoramaView(frame: view.bounds)
        panoramaView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        panoramaView.delegate = self
        view.addSubview(panoramaView)
        panoramaView.moveNearCoordinate(coordinate)

        statusLabel.text = "STREET VIEW IS NOT AVAILABLE HERE"
        statusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        statusLabel.textColor = UIColor(white: 1, alpha: 0.8)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(
            UIImage(systemName: "xmark",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)),
            for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor(rgb: 0x0F1115).withAlphaComponent(0.85)
        closeButton.layer.cornerRadius = 20
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor(white: 1, alpha: 0.14).cgColor
        closeButton.accessibilityLabel = "Close"
        closeButton.addTarget(self, action: #selector(closeTap), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        let captionLabel = PaddedLabel()
        captionLabel.text = caption.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        captionLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        captionLabel.textColor = .white
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 2
        captionLabel.backgroundColor = UIColor(rgb: 0x0F1115).withAlphaComponent(0.85)
        captionLabel.layer.cornerRadius = 12
        captionLabel.layer.masksToBounds = true
        captionLabel.insets = UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)
        captionLabel.isHidden = (captionLabel.text ?? "").isEmpty
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captionLabel)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 14),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            // Sits above the Street View attribution in the bottom corners.
            captionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -34),
            captionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    @objc private func closeTap() {
        dismiss(animated: true)
    }

    // Face the incident the first time a panorama loads.
    func panoramaView(_ view: GMSPanoramaView, didMoveTo panorama: GMSPanorama?) {
        guard let panorama, !didOrientCamera else { return }
        didOrientCamera = true
        statusLabel.isHidden = true
        guard GMSGeometryDistance(panorama.coordinate, coordinate) > 3 else { return }
        let heading = GMSGeometryHeading(panorama.coordinate, coordinate)
        view.camera = GMSPanoramaCamera(heading: heading, pitch: 0, zoom: 1)
    }

    func panoramaView(_ view: GMSPanoramaView, error: Error, onMoveNearCoordinate coordinate: CLLocationCoordinate2D) {
        statusLabel.isHidden = false
    }
}
