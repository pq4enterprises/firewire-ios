//
//  ScannerViewController.swift
//  FireWire
//
//  2026 redesign — "Instrument Panel" scanner screen (direction 1A).
//  Programmatic UIKit + FireWireTheme. The instrument console is a
//  fixed-dark hardware-style card (matches the approved unified design,
//  where the console stays dark in both light and dark mode); the rest of
//  the screen adapts to light/dark via theme tokens.
//
//  Playback + premium gating logic is carried over verbatim from the old
//  FeedsListViewController: AudioManager.shared streams the feed URL,
//  AppManager.shared.currentScannerIDListeningTO tracks the active feed,
//  and basic users are routed to SubscriptionInfoViewController before a
//  stream can start.
//

import FirebaseAnalytics
import UIKit

protocol FeedListViewDelegate: AnyObject {
    func dataReceived()
    func errorReceived(message: String)
}

// MARK: - Console palette (fixed dark, both appearance modes)

private enum ConsolePalette {
    static let background = UIColor(rgb: 0x0E1016)
    static let cellBackground = UIColor(rgb: 0x0B0C11)
    static let gridGap = UIColor(white: 1, alpha: 0.06)
    static let hairline = UIColor(white: 1, alpha: 0.07)
    static let label = UIColor(rgb: 0x5B6270)
    static let value = UIColor(rgb: 0xF5B93C)
    static let info = UIColor(rgb: 0x8B93A1)
    static let text = UIColor.white
    static let segmentOff = UIColor(white: 1, alpha: 0.09)
    static let waveTop = UIColor(rgb: 0x4ADE80)
}

class ScannerViewController: UIViewController, FeedListViewDelegate {
    var coordinator: HomeCoordinator?
    var viewModel: FeedsListViewModel!
    var paginationHandler: PaginationHandler<FeedsListViewModel>!

    // MARK: Views

    private let headerBar = UIView()
    private let liveCountLabel = UILabel()
    private let liveDot = UIView()

    private let consoleCard = UIView()
    private let consoleStatusLabel = UILabel()
    private let consoleStatusDot = UIView()
    private let channelNameLabel = UILabel()
    private let readoutRegionValue = UILabel()
    private let readoutStatusValue = UILabel()
    private let readoutElapsedValue = UILabel()
    private var ledSegments: [UIView] = []
    private let waveformStack = UIStackView()
    private let infoLine1 = UILabel()
    private let infoLine2 = UILabel()
    private let transportButton = UIButton(type: .system)

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let noFeedsLabel = UILabel()

    // MARK: State

    /// Region names the user expanded (all regions start collapsed). The
    /// region that contains the actively-playing feed is auto-expanded so the
    /// live row is always reachable.
    private var expandedRegions = Set<String>()

    private var elapsedTimer: Timer?
    private var ledTimer: Timer?
    private var playbackStartDate: Date?

    private var currentFeed: FeedListData? {
        guard let id = AppManager.shared.currentScannerIDListeningTO else { return nil }
        return viewModel.items.flatMap { $0.feedList }.first { $0.id == id }
    }

    private var isAudioPlaying: Bool {
        AppManager.shared.currentScannerIDListeningTO != nil && AudioManager.shared.isPlaying
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()

        showLoader()
        viewModel = FeedsListViewModel()
        viewModel.delegate = self
        viewModel.getFeedList()

        paginationHandler = PaginationHandler(viewModel: viewModel)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: AudioManager.playbackStateChangedNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)

        if isAudioPlaying {
            playbackStartDate = Date()
        }
        updateConsole()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_scanner_feeds",
        ])
        syncAnimations()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // CGColor borders don't follow dark-mode changes automatically.
            consoleCard.layer.borderColor = FireWireTheme.red.withAlphaComponent(0.32).cgColor
            tableView.reloadData()
        }
    }

    deinit {
        elapsedTimer?.invalidate()
        ledTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> ScannerViewController {
        return ScannerViewController()
    }

    // MARK: FeedListViewDelegate

    func dataReceived() {
        hideLoader()
        noFeedsLabel.isHidden = true
        tableView.isHidden = false
        expandRegionOfActiveFeed()
        tableView.reloadData()
        updateConsole()
    }

    /// Auto-expand the region group that contains the actively-playing feed
    /// so the live row is visible even though groups default collapsed.
    private func expandRegionOfActiveFeed() {
        guard let activeID = AppManager.shared.currentScannerIDListeningTO else { return }
        for group in viewModel.items where group.feedList.contains(where: { $0.id == activeID }) {
            expandedRegions.insert(group.localityName)
            return
        }
    }

    func errorReceived(message: String) {
        hideLoader()
        tableView.isHidden = true
        noFeedsLabel.isHidden = false
        updateConsole()
    }

    // MARK: Premium gate (verbatim from the pre-redesign screen)

    func unlockPremiumFeatureIfValid() -> Bool {
        if FWUserDefaults().userRole == "basic_user" {
            coordinator?.navigateToSubscriptionInfo()
            return true
        }
        return false
    }

    // MARK: UI construction

    private func buildUI() {
        view.backgroundColor = FireWireTheme.background
        buildHeaderBar()
        buildConsoleCard()
        buildTableView()
    }

    private func buildHeaderBar() {
        headerBar.backgroundColor = FireWireTheme.surface
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(hairline)

        let backButton = UIButton(type: .system)
        backButton.setImage(
            UIImage(systemName: "chevron.left",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)),
            for: .normal)
        backButton.tintColor = FireWireTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.attributedText = NSAttributedString(
            string: "SCANNER",
            attributes: [
                .font: UIFont.systemFont(ofSize: 19, weight: .heavy),
                .kern: 2.0,
                .foregroundColor: FireWireTheme.text,
            ])
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        liveDot.backgroundColor = FireWireTheme.success
        liveDot.layer.cornerRadius = 3.5
        liveDot.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(liveDot)

        liveCountLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        liveCountLabel.textColor = FireWireTheme.success
        liveCountLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(liveCountLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),

            hairline.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            backButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: -14),

            liveCountLabel.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -16),
            liveCountLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            liveDot.trailingAnchor.constraint(equalTo: liveCountLabel.leadingAnchor, constant: -6),
            liveDot.centerYAnchor.constraint(equalTo: liveCountLabel.centerYAnchor),
            liveDot.widthAnchor.constraint(equalToConstant: 7),
            liveDot.heightAnchor.constraint(equalToConstant: 7),
        ])
    }

    private func buildConsoleCard() {
        consoleCard.backgroundColor = ConsolePalette.background
        consoleCard.layer.cornerRadius = 18
        consoleCard.layer.borderWidth = 1
        consoleCard.layer.borderColor = FireWireTheme.red.withAlphaComponent(0.32).cgColor
        consoleCard.layer.shadowColor = UIColor.black.cgColor
        consoleCard.layer.shadowOpacity = 0.4
        consoleCard.layer.shadowRadius = 14
        consoleCard.layer.shadowOffset = CGSize(width: 0, height: 8)
        consoleCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(consoleCard)

        // ----- top strip: RECEIVER · CH LOCK + status -----
        let receiverLabel = UILabel()
        receiverLabel.attributedText = NSAttributedString(
            string: "◈ RECEIVER · CH LOCK",
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .semibold),
                .kern: 1.6,
                .foregroundColor: ConsolePalette.label,
            ])
        receiverLabel.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(receiverLabel)

        consoleStatusDot.layer.cornerRadius = 4
        consoleStatusDot.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(consoleStatusDot)

        consoleStatusLabel.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        consoleStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(consoleStatusLabel)

        let stripHairline = UIView()
        stripHairline.backgroundColor = ConsolePalette.hairline
        stripHairline.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(stripHairline)

        // ----- channel name -----
        channelNameLabel.font = .systemFont(ofSize: 23, weight: .heavy)
        channelNameLabel.textColor = ConsolePalette.text
        channelNameLabel.adjustsFontSizeToFitWidth = true
        channelNameLabel.minimumScaleFactor = 0.6
        channelNameLabel.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(channelNameLabel)

        // ----- data readout grid (REGION / STATUS / ELAPSED) -----
        let grid = UIStackView()
        grid.axis = .horizontal
        grid.distribution = .fillEqually
        grid.spacing = 1
        grid.backgroundColor = ConsolePalette.gridGap
        grid.layer.cornerRadius = 8
        grid.clipsToBounds = true
        grid.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(grid)

        func readoutCell(caption: String, valueLabel: UILabel) -> UIView {
            let cell = UIView()
            cell.backgroundColor = ConsolePalette.cellBackground

            let captionLabel = UILabel()
            captionLabel.attributedText = NSAttributedString(
                string: caption,
                attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 8, weight: .semibold),
                    .kern: 1.0,
                    .foregroundColor: ConsolePalette.label,
                ])
            captionLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(captionLabel)

            valueLabel.font = .monospacedSystemFont(ofSize: 13, weight: .bold)
            valueLabel.textColor = ConsolePalette.value
            valueLabel.adjustsFontSizeToFitWidth = true
            valueLabel.minimumScaleFactor = 0.6
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(valueLabel)

            NSLayoutConstraint.activate([
                captionLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 9),
                captionLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
                captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),

                valueLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 5),
                valueLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
                valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
                valueLabel.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -9),
            ])
            return cell
        }

        grid.addArrangedSubview(readoutCell(caption: "REGION", valueLabel: readoutRegionValue))
        grid.addArrangedSubview(readoutCell(caption: "STATUS", valueLabel: readoutStatusValue))
        grid.addArrangedSubview(readoutCell(caption: "ELAPSED", valueLabel: readoutElapsedValue))

        // ----- LED signal meter -----
        let sigLabel = UILabel()
        sigLabel.attributedText = NSAttributedString(
            string: "SIG",
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 8, weight: .semibold),
                .kern: 1.5,
                .foregroundColor: ConsolePalette.label,
            ])
        sigLabel.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(sigLabel)

        let ledStack = UIStackView()
        ledStack.axis = .horizontal
        ledStack.distribution = .fillEqually
        ledStack.spacing = 3
        ledStack.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(ledStack)

        for _ in 0..<16 {
            let segment = UIView()
            segment.backgroundColor = ConsolePalette.segmentOff
            segment.layer.cornerRadius = 1
            ledSegments.append(segment)
            ledStack.addArrangedSubview(segment)
        }

        // ----- waveform -----
        waveformStack.axis = .horizontal
        waveformStack.distribution = .fillEqually
        waveformStack.spacing = 3
        waveformStack.alignment = .center
        waveformStack.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(waveformStack)

        for _ in 0..<30 {
            let bar = UIView()
            bar.backgroundColor = FireWireTheme.success
            bar.layer.cornerRadius = 1
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.heightAnchor.constraint(equalToConstant: 34).isActive = true
            waveformStack.addArrangedSubview(bar)
        }

        // ----- transport row -----
        infoLine1.font = .monospacedSystemFont(ofSize: 9.5, weight: .semibold)
        infoLine1.textColor = ConsolePalette.info
        infoLine1.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(infoLine1)

        infoLine2.font = .monospacedSystemFont(ofSize: 9.5, weight: .semibold)
        infoLine2.textColor = ConsolePalette.info
        infoLine2.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(infoLine2)

        transportButton.backgroundColor = FireWireTheme.red
        transportButton.tintColor = .white
        transportButton.layer.cornerRadius = 28
        transportButton.layer.shadowColor = FireWireTheme.red.cgColor
        transportButton.layer.shadowOpacity = 0.5
        transportButton.layer.shadowRadius = 8
        transportButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        transportButton.addTarget(self, action: #selector(transportButtonTap), for: .touchUpInside)
        transportButton.translatesAutoresizingMaskIntoConstraints = false
        consoleCard.addSubview(transportButton)

        NSLayoutConstraint.activate([
            consoleCard.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 10),
            consoleCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            consoleCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),

            receiverLabel.topAnchor.constraint(equalTo: consoleCard.topAnchor, constant: 14),
            receiverLabel.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),

            consoleStatusLabel.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),
            consoleStatusLabel.centerYAnchor.constraint(equalTo: receiverLabel.centerYAnchor),

            consoleStatusDot.trailingAnchor.constraint(equalTo: consoleStatusLabel.leadingAnchor, constant: -6),
            consoleStatusDot.centerYAnchor.constraint(equalTo: consoleStatusLabel.centerYAnchor),
            consoleStatusDot.widthAnchor.constraint(equalToConstant: 8),
            consoleStatusDot.heightAnchor.constraint(equalToConstant: 8),

            stripHairline.topAnchor.constraint(equalTo: receiverLabel.bottomAnchor, constant: 9),
            stripHairline.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),
            stripHairline.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),
            stripHairline.heightAnchor.constraint(equalToConstant: 1),

            channelNameLabel.topAnchor.constraint(equalTo: stripHairline.bottomAnchor, constant: 10),
            channelNameLabel.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),
            channelNameLabel.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),

            grid.topAnchor.constraint(equalTo: channelNameLabel.bottomAnchor, constant: 11),
            grid.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),
            grid.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),

            sigLabel.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 12),
            sigLabel.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),
            sigLabel.widthAnchor.constraint(equalToConstant: 30),

            ledStack.centerYAnchor.constraint(equalTo: sigLabel.centerYAnchor),
            ledStack.leadingAnchor.constraint(equalTo: sigLabel.trailingAnchor, constant: 9),
            ledStack.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),
            ledStack.heightAnchor.constraint(equalToConstant: 14),

            waveformStack.topAnchor.constraint(equalTo: ledStack.bottomAnchor, constant: 12),
            waveformStack.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),
            waveformStack.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),
            waveformStack.heightAnchor.constraint(equalToConstant: 40),

            infoLine1.topAnchor.constraint(equalTo: waveformStack.bottomAnchor, constant: 12),
            infoLine1.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),
            infoLine2.topAnchor.constraint(equalTo: infoLine1.bottomAnchor, constant: 4),
            infoLine2.leadingAnchor.constraint(equalTo: consoleCard.leadingAnchor, constant: 15),

            transportButton.trailingAnchor.constraint(equalTo: consoleCard.trailingAnchor, constant: -15),
            transportButton.topAnchor.constraint(equalTo: waveformStack.bottomAnchor, constant: 8),
            transportButton.widthAnchor.constraint(equalToConstant: 56),
            transportButton.heightAnchor.constraint(equalToConstant: 56),
            transportButton.bottomAnchor.constraint(equalTo: consoleCard.bottomAnchor, constant: -15),
        ])
    }

    private func buildTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ScannerFeedCell.self, forCellReuseIdentifier: ScannerFeedCell.identifier)
        tableView.sectionHeaderTopPadding = 0
        tableView.contentInset = UIEdgeInsets(top: 2, left: 0, bottom: 16, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        noFeedsLabel.text = "NO FEEDS FOUND"
        noFeedsLabel.font = FireWireTheme.sectionTitleFont()
        noFeedsLabel.textColor = FireWireTheme.muted
        noFeedsLabel.textAlignment = .center
        noFeedsLabel.isHidden = true
        noFeedsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noFeedsLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: consoleCard.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            noFeedsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noFeedsLabel.topAnchor.constraint(equalTo: consoleCard.bottomAnchor, constant: 60),
        ])
    }

    // MARK: Console state

    private func updateConsole() {
        let totalFeeds = viewModel?.items.flatMap { $0.feedList }.count ?? 0
        let regionCount = viewModel?.items.count ?? 0

        liveCountLabel.text = "\(totalFeeds)"

        let feed = currentFeed
        let playing = isAudioPlaying

        channelNameLabel.text = (feed?.name ?? "NO FEED SELECTED").uppercased()
        readoutRegionValue.text = (feed?.locality.name ?? "—").uppercased()

        let statusText: String
        let statusColor: UIColor
        if playing {
            statusText = "RX"
            statusColor = FireWireTheme.success
        } else if feed != nil {
            statusText = "STANDBY"
            statusColor = FireWireTheme.warning
        } else {
            statusText = "STANDBY"
            statusColor = ConsolePalette.label
        }
        readoutStatusValue.text = statusText
        consoleStatusLabel.text = statusText
        consoleStatusLabel.textColor = statusColor
        consoleStatusDot.backgroundColor = statusColor

        updateElapsedLabel()

        infoLine1.attributedText = infoAttributed(caption: "FEEDS ", value: "\(totalFeeds)")
        infoLine2.attributedText = infoAttributed(caption: "REGIONS ", value: "\(regionCount)")

        let iconName = playing ? "pause.fill" : "play.fill"
        transportButton.setImage(
            UIImage(systemName: iconName,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)),
            for: .normal)
        transportButton.alpha = feed == nil ? 0.45 : 1.0

        syncAnimations()
        syncTimers()
    }

    private func infoAttributed(caption: String, value: String) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: caption,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .semibold),
                .kern: 0.5,
                .foregroundColor: ConsolePalette.info,
            ])
        result.append(NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
                .kern: 0.5,
                .foregroundColor: ConsolePalette.text,
            ]))
        return result
    }

    private func updateElapsedLabel() {
        if isAudioPlaying, let start = playbackStartDate {
            let seconds = Int(Date().timeIntervalSince(start))
            readoutElapsedValue.text = String(format: "%02d:%02d", seconds / 60, seconds % 60)
        } else {
            readoutElapsedValue.text = "00:00"
        }
    }

    // MARK: Animations & timers

    private func syncAnimations() {
        let playing = isAudioPlaying

        // Waveform: staggered scale-y pulse when receiving, dimmed when idle.
        waveformStack.alpha = playing ? 1.0 : 0.28
        for (index, bar) in waveformStack.arrangedSubviews.enumerated() {
            if playing {
                if bar.layer.animation(forKey: "fwwave") == nil {
                    let wave = CABasicAnimation(keyPath: "transform.scale.y")
                    wave.fromValue = 0.16
                    wave.toValue = 1.0
                    wave.duration = 0.45
                    wave.autoreverses = true
                    wave.repeatCount = .infinity
                    wave.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    wave.timeOffset = Double((index * 37) % 100) / 100.0 * 0.9
                    bar.layer.add(wave, forKey: "fwwave")
                }
            } else {
                bar.layer.removeAnimation(forKey: "fwwave")
                bar.layer.transform = CATransform3DMakeScale(1, 0.16, 1)
            }
        }

        // Status dot pulse.
        if playing || currentFeed != nil {
            if consoleStatusDot.layer.animation(forKey: "fwpulse") == nil {
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 1.0
                pulse.toValue = 0.25
                pulse.duration = 0.55
                pulse.autoreverses = true
                pulse.repeatCount = .infinity
                consoleStatusDot.layer.add(pulse, forKey: "fwpulse")
            }
        } else {
            consoleStatusDot.layer.removeAnimation(forKey: "fwpulse")
        }

        if !playing {
            updateLEDMeter(litCount: 0)
        }
    }

    private func syncTimers() {
        if isAudioPlaying {
            if elapsedTimer == nil {
                elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateElapsedLabel()
                }
            }
            if ledTimer == nil {
                ledTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
                    self?.updateLEDMeter(litCount: Int.random(in: 10...15))
                }
            }
        } else {
            elapsedTimer?.invalidate()
            elapsedTimer = nil
            ledTimer?.invalidate()
            ledTimer = nil
        }
    }

    private func updateLEDMeter(litCount: Int) {
        for (index, segment) in ledSegments.enumerated() {
            if index < litCount {
                let color: UIColor
                if index < 9 {
                    color = FireWireTheme.success
                } else if index < 13 {
                    color = FireWireTheme.warning
                } else {
                    color = FireWireTheme.red
                }
                segment.backgroundColor = color
            } else {
                segment.backgroundColor = ConsolePalette.segmentOff
            }
        }
    }

    @objc private func appWillEnterForeground() {
        // CAAnimations are removed while backgrounded — rebuild them.
        updateConsole()
    }

    // MARK: Actions

    @objc private func backButtonTap() {
        coordinator?.navigateBackToHome()
    }

    @objc private func transportButtonTap() {
        guard let feed = currentFeed else { return }
        feedTapped(feed)
    }

    @objc private func playbackStateChanged() {
        let isPlaying = AudioManager.shared.isPlaying
        if let currentID = AppManager.shared.currentScannerIDListeningTO {
            updatePlayingState(forFeedID: currentID, isPlaying: isPlaying)
        }
        if isPlaying, playbackStartDate == nil {
            playbackStartDate = Date()
        } else if !isPlaying {
            playbackStartDate = nil
        }
        if isPlaying {
            expandRegionOfActiveFeed()
        }
        tableView.reloadData()
        updateConsole()
    }

    func updatePlayingState(forFeedID id: String, isPlaying: Bool) {
        if viewModel.items.count > 0 {
            for sectionIndex in 0..<viewModel.items.count {
                for rowIndex in 0..<viewModel.items[sectionIndex].feedList.count {
                    if viewModel.items[sectionIndex].feedList[rowIndex].id == id {
                        viewModel.items[sectionIndex].feedList[rowIndex].isPlaying = isPlaying
                        return
                    }
                }
            }
        }
    }

    @objc private func regionHeaderTap(_ sender: UIButton) {
        let section = sender.tag
        guard section < viewModel.items.count else { return }
        let region = viewModel.items[section].localityName
        if expandedRegions.contains(region) {
            expandedRegions.remove(region)
        } else {
            expandedRegions.insert(region)
        }
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }

    // MARK: Playback control (logic carried over verbatim)

    private func feedTapped(_ feedData: FeedListData, indexPath: IndexPath? = nil) {
        Analytics.logEvent("radio_feed_tapped", parameters: [
            "feed_title": feedData.name,
        ])

        if AppManager.shared.currentScannerIDListeningTO == feedData.id {
            showAlert(
                title: "Stop Listening",
                message: "Are you sure you want to stop listening?",
                actions: [UIAlertAction(title: "Stop Listening", style: .default, handler: { _ in
                    self.stopListeningToFeed(indexPath: indexPath ?? self.getIndexOfPlayingFeed())
                })],
                cancel: true)
        } else {
            guard unlockPremiumFeatureIfValid() == false else { return }
            guard let indexPath = indexPath ?? indexPathOfFeed(withID: feedData.id) else { return }
            startListeningToFeed(
                id: feedData.id,
                title: feedData.name,
                urlString: feedData.url,
                indexPath: indexPath)
        }
    }

    func startListeningToFeed(id: String, title: String, urlString: String, indexPath: IndexPath) {
        if let url = URL(string: urlString) {
            // if audio is already playing stop & start playing new
            if let playingFeedIndex = getIndexOfPlayingFeed() {
                viewModel.items[playingFeedIndex.section].feedList[playingFeedIndex.row].isPlaying = false
            }

            viewModel.items[indexPath.section].feedList[indexPath.row].isPlaying = true

            AudioManager.shared.streamAudioFromURL(url: url, feedTitle: title)
            AppManager.shared.currentScannerIDListeningTO = id
            playbackStartDate = Date()

            // Keep the live row visible if its group was collapsed.
            expandedRegions.insert(viewModel.items[indexPath.section].localityName)
            tableView.reloadData()
            updateConsole()
        } else {
            showAlert(
                title: "",
                message: "This feed is unavailable at this time.",
                actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }
    }

    func stopListeningToFeed(indexPath: IndexPath?) {
        if let indexPath {
            viewModel.items[indexPath.section].feedList[indexPath.row].isPlaying = false
        }

        AppManager.shared.currentScannerIDListeningTO = nil
        AudioManager.shared.stopStreaming()
        AudioManager.shared.stopRemotePlaybackUI()
        playbackStartDate = nil

        tableView.reloadData()
        updateConsole()
    }

    func getIndexOfPlayingFeed() -> IndexPath? {
        for sectionIndex in 0 ..< viewModel.items.count {
            let feedList = viewModel.items[sectionIndex].feedList
            if let rowIndex = feedList.firstIndex(where: { $0.isPlaying == true }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }

    private func indexPathOfFeed(withID id: String) -> IndexPath? {
        for sectionIndex in 0 ..< viewModel.items.count {
            if let rowIndex = viewModel.items[sectionIndex].feedList.firstIndex(where: { $0.id == id }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}

// MARK: - Table view

extension ScannerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = viewModel.items[section]
        return expandedRegions.contains(group.localityName) ? group.feedList.count : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = viewModel.items[section]
        let expanded = expandedRegions.contains(group.localityName)

        let container = UIView()

        let card = UIView()
        card.backgroundColor = FireWireTheme.surface
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = FireWireTheme.hairline.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        let chevron = UIImageView(image: UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .heavy)))
        chevron.tintColor = FireWireTheme.muted
        chevron.contentMode = .center
        if expanded {
            chevron.transform = CGAffineTransform(rotationAngle: .pi / 2)
        }
        chevron.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chevron)

        let nameLabel = UILabel()
        nameLabel.attributedText = NSAttributedString(
            string: group.localityName.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
                .kern: 1.5,
                .foregroundColor: FireWireTheme.text,
            ])
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        let countLabel = UILabel()
        countLabel.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        countLabel.textColor = FireWireTheme.muted
        countLabel.text = "\(group.feedList.count) FEEDS"
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(countLabel)

        let liveDot = UIView()
        liveDot.backgroundColor = FireWireTheme.success
        liveDot.layer.cornerRadius = 3
        liveDot.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(liveDot)

        let liveLabel = UILabel()
        liveLabel.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        liveLabel.textColor = FireWireTheme.success
        liveLabel.text = "LIVE"
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(liveLabel)

        let tapButton = UIButton(type: .custom)
        tapButton.tag = section
        tapButton.addTarget(self, action: #selector(regionHeaderTap(_:)), for: .touchUpInside)
        tapButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(tapButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            chevron.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 16),

            nameLabel.leadingAnchor.constraint(equalTo: chevron.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            countLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            countLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            liveLabel.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -10),
            liveLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            liveDot.trailingAnchor.constraint(equalTo: liveLabel.leadingAnchor, constant: -5),
            liveDot.centerYAnchor.constraint(equalTo: liveLabel.centerYAnchor),
            liveDot.widthAnchor.constraint(equalToConstant: 6),
            liveDot.heightAnchor.constraint(equalToConstant: 6),

            tapButton.topAnchor.constraint(equalTo: card.topAnchor),
            tapButton.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            tapButton.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        52
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ScannerFeedCell.identifier,
            for: indexPath) as! ScannerFeedCell
        let feed = viewModel.items[indexPath.section].feedList[indexPath.row]
        cell.configure(with: feed)
        cell.onPlayTap = { [weak self] in
            self?.feedTapped(feed, indexPath: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let feedData = viewModel.items[indexPath.section].feedList[indexPath.row]
        feedTapped(feedData, indexPath: indexPath)
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
}

// MARK: - Feed row cell

final class ScannerFeedCell: UITableViewCell {
    static let identifier = "ScannerFeedCell"

    var onPlayTap: (() -> Void)?

    private let card = UIView()
    private let statusDot = UIView()
    private let nameLabel = UILabel()
    private let datalineLabel = UILabel()
    private let statusChip = FWPaddedLabel()
    private let playButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildUI() {
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(statusDot)

        nameLabel.font = .systemFont(ofSize: 14.5, weight: .heavy)
        nameLabel.textColor = FireWireTheme.text
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        datalineLabel.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        datalineLabel.textColor = FireWireTheme.muted
        datalineLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(datalineLabel)

        statusChip.font = .monospacedSystemFont(ofSize: 9, weight: .heavy)
        statusChip.insets = UIEdgeInsets(top: 6, left: 9, bottom: 6, right: 9)
        statusChip.layer.cornerRadius = 6
        statusChip.clipsToBounds = true
        statusChip.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(statusChip)

        playButton.layer.cornerRadius = 22
        playButton.addTarget(self, action: #selector(playTap), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(playButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            statusDot.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 13),
            statusDot.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 13),
            nameLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 13),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusChip.leadingAnchor, constant: -8),

            datalineLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            datalineLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            datalineLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusChip.leadingAnchor, constant: -8),
            datalineLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -13),

            statusChip.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -10),
            statusChip.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            playButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            playButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func configure(with feed: FeedListData) {
        let isActive = feed.isPlaying || AppManager.shared.currentScannerIDListeningTO == feed.id
        let playing = isActive && AudioManager.shared.isPlaying

        nameLabel.text = feed.name.uppercased()

        let statusText: String
        let statusColor: UIColor
        if playing {
            statusText = "RX"
            statusColor = FireWireTheme.success
        } else if isActive {
            statusText = "STANDBY"
            statusColor = FireWireTheme.warning
        } else {
            statusText = "LIVE"
            statusColor = FireWireTheme.success
        }

        let dataline = "\(feed.locality.name) · STREAM \(statusText)"
        datalineLabel.attributedText = NSAttributedString(
            string: dataline.uppercased(),
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .medium),
                .kern: 0.3,
                .foregroundColor: FireWireTheme.muted,
            ])

        statusDot.backgroundColor = statusColor
        statusDot.layer.shadowColor = statusColor.cgColor
        statusDot.layer.shadowOpacity = isActive ? 0.8 : 0
        statusDot.layer.shadowRadius = 4
        statusDot.layer.shadowOffset = .zero

        statusChip.attributedText = NSAttributedString(
            string: statusText,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                .kern: 1.0,
                .foregroundColor: statusColor,
            ])
        statusChip.backgroundColor = statusColor.withAlphaComponent(0.16)

        if isActive {
            card.backgroundColor = statusColor.withAlphaComponent(0.12)
            card.layer.borderColor = statusColor.withAlphaComponent(0.5).cgColor
        } else {
            card.backgroundColor = FireWireTheme.surface
            card.layer.borderColor = FireWireTheme.hairline.cgColor
        }

        let iconName = playing ? "pause.fill" : "play.fill"
        playButton.setImage(
            UIImage(systemName: iconName,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)),
            for: .normal)
        if playing {
            playButton.backgroundColor = FireWireTheme.red
            playButton.tintColor = .white
        } else {
            playButton.backgroundColor = FireWireTheme.success.withAlphaComponent(0.16)
            playButton.tintColor = FireWireTheme.success
        }
    }

    @objc private func playTap() {
        onPlayTap?()
    }
}
