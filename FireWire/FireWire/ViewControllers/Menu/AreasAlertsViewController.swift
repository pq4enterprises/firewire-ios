//
//  AreasAlertsViewController.swift
//  FireWire
//
//  2026 redesign (programmatic UIKit, FireWireTheme) — combined "Areas &
//  Alerts" screen replacing the personalization hub: FEED toggles select the
//  areas shown in the wire feed, ALERT toggles opt into push alerts per area,
//  and the top card links to the global Notification Sounds screen.
//

import UIKit

class AreasAlertsViewController: UIViewController {
    var coordinator: HomeCoordinator?
    let viewModel = AreasAlertsViewModel()

    // MARK: Views

    private let headerBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bottomBar = UIView()
    private let saveButton = UIButton(type: .system)

    private let soundCard = UIView()
    private let soundNameLabel = UILabel()

    /// Container for the region groups so they can be rebuilt after loading.
    private let groupsStack = UIStackView()

    /// Live control references, indexed [group][row] / [group].
    private var feedSwitches: [[UISwitch]] = []
    private var alertSwitches: [[UISwitch]] = []
    private var groupActionButtons: [UIButton] = []

    /// Card-styled views whose CGColor borders need refreshing on theme change.
    private var borderedViews: [UIView] = []

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        bindViewModel()
        showLoader()
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSoundLabel() // refresh after returning from the sounds screen
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

    // MARK: View model binding

    private func bindViewModel() {
        viewModel.onDataLoaded = { [weak self] in
            self?.hideLoader()
            self?.renderGroups()
        }

        viewModel.onError = { [weak self] message in
            self?.hideLoader()
            self?.showAlert(
                title: "",
                message: message,
                actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }

        viewModel.onSaved = { [weak self] in
            self?.hideLoader()
            self?.showAlert(
                title: "",
                message: "Areas & Alerts updated successfully",
                actions: [UIAlertAction(title: "Ok", style: .default) { _ in
                    self?.coordinator?.popView()
                }])
        }
    }

    // MARK: UI construction

    private func buildUI() {
        view.backgroundColor = FireWireTheme.background
        buildHeaderBar()
        buildBottomBar()
        buildScrollContent()
        buildSoundCard()
        buildHelperText()
        buildColumnHeaders()

        groupsStack.axis = .vertical
        groupsStack.spacing = 0
        contentStack.addArrangedSubview(groupsStack)
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
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" BACK", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.tintColor = FireWireTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "AREAS & ALERTS"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

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
        ])
    }

    private func buildBottomBar() {
        bottomBar.backgroundColor = FireWireTheme.surface
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(hairline)

        saveButton.setTitle("SAVE", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .heavy)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = FireWireTheme.red
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveButtonTap), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(saveButton)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hairline.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            hairline.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 54),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
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
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24),
        ])
    }

    private func buildSoundCard() {
        FireWireTheme.cardStyle(soundCard)
        soundCard.layer.cornerRadius = 14
        borderedViews.append(soundCard)

        let iconSquare = UIView()
        iconSquare.backgroundColor = FireWireTheme.redTint
        iconSquare.layer.cornerRadius = 12
        iconSquare.translatesAutoresizingMaskIntoConstraints = false

        let bellIcon = UIImageView(image: UIImage(
            systemName: "bell",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)))
        bellIcon.tintColor = FireWireTheme.red
        bellIcon.contentMode = .scaleAspectFit
        bellIcon.translatesAutoresizingMaskIntoConstraints = false
        iconSquare.addSubview(bellIcon)

        let captionLabel = UILabel()
        captionLabel.attributedText = NSAttributedString(
            string: "GLOBAL ALERT SOUND",
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
                .kern: 1.0,
                .foregroundColor: FireWireTheme.muted,
            ])

        soundNameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        soundNameLabel.textColor = FireWireTheme.text
        updateSoundLabel()

        let textStack = UIStackView(arrangedSubviews: [captionLabel, soundNameLabel])
        textStack.axis = .vertical
        textStack.spacing = 5
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = FireWireTheme.muted
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        soundCard.addSubview(iconSquare)
        soundCard.addSubview(textStack)
        soundCard.addSubview(chevron)

        NSLayoutConstraint.activate([
            iconSquare.leadingAnchor.constraint(equalTo: soundCard.leadingAnchor, constant: 14),
            iconSquare.centerYAnchor.constraint(equalTo: soundCard.centerYAnchor),
            iconSquare.widthAnchor.constraint(equalToConstant: 44),
            iconSquare.heightAnchor.constraint(equalToConstant: 44),

            bellIcon.centerXAnchor.constraint(equalTo: iconSquare.centerXAnchor),
            bellIcon.centerYAnchor.constraint(equalTo: iconSquare.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: iconSquare.trailingAnchor, constant: 13),
            textStack.topAnchor.constraint(equalTo: soundCard.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: soundCard.bottomAnchor, constant: -14),

            chevron.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 8),
            chevron.trailingAnchor.constraint(equalTo: soundCard.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: soundCard.centerYAnchor),
        ])

        soundCard.isUserInteractionEnabled = true
        soundCard.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(soundCardTap)))

        contentStack.addArrangedSubview(soundCard)
    }

    private func updateSoundLabel() {
        let soundName = NotificationSoundsViewModel().selectedSoundName ?? "Default"
        soundNameLabel.text = soundName.uppercased()
    }

    private func buildHelperText() {
        // Not uppercased — matches the mockup, which keeps this helper in
        // sentence case.
        let helperLabel = UILabel()
        helperLabel.text = "Toggle an area into your feed, then use the bell to get push alerts for it. Feed without alerts is fine."
        helperLabel.font = .systemFont(ofSize: 11, weight: .medium)
        helperLabel.textColor = FireWireTheme.muted
        helperLabel.numberOfLines = 0

        contentStack.setCustomSpacing(12, after: soundCard)
        let wrapper = UIView()
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(helperLabel)
        NSLayoutConstraint.activate([
            helperLabel.topAnchor.constraint(equalTo: wrapper.topAnchor),
            helperLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 6),
            helperLabel.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -6),
            helperLabel.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        contentStack.addArrangedSubview(wrapper)
        contentStack.setCustomSpacing(10, after: wrapper)
    }

    /// FEED / ALERT captions aligned over the two switch columns.
    private func buildColumnHeaders() {
        let headerRow = UIView()

        let feedHeader = columnHeader(
            caption: "FEED", systemImage: "line.3.horizontal", iconColor: FireWireTheme.text)
        let alertHeader = columnHeader(
            caption: "ALERT", systemImage: "bell", iconColor: FireWireTheme.red)

        headerRow.addSubview(feedHeader)
        headerRow.addSubview(alertHeader)

        // Mirrors the row layout: [name][switch 51][gap 14][switch 51][pad 14]
        NSLayoutConstraint.activate([
            feedHeader.topAnchor.constraint(equalTo: headerRow.topAnchor),
            feedHeader.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor),
            feedHeader.widthAnchor.constraint(equalToConstant: 51),

            alertHeader.topAnchor.constraint(equalTo: headerRow.topAnchor),
            alertHeader.widthAnchor.constraint(equalToConstant: 51),
            alertHeader.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor, constant: -14),
            feedHeader.trailingAnchor.constraint(equalTo: alertHeader.leadingAnchor, constant: -14),
        ])

        contentStack.addArrangedSubview(headerRow)
        contentStack.setCustomSpacing(2, after: headerRow)
    }

    private func columnHeader(caption: String, systemImage: String, iconColor: UIColor) -> UIView {
        let icon = UIImageView(image: UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)))
        icon.tintColor = iconColor
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: caption,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 8.5, weight: .heavy),
                .kern: 0.5,
                .foregroundColor: FireWireTheme.text,
            ])

        let chevron = UIImageView(image: UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)))
        chevron.tintColor = FireWireTheme.muted
        chevron.contentMode = .scaleAspectFit

        let stack = UIStackView(arrangedSubviews: [icon, label, chevron])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    // MARK: Region groups

    private func renderGroups() {
        borderedViews.removeAll { view in
            groupsStack.arrangedSubviews.contains { $0 === view || view.isDescendant(of: $0) }
        }
        groupsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        feedSwitches = []
        alertSwitches = []
        groupActionButtons = []

        for (groupIndex, group) in viewModel.groups.enumerated() {
            feedSwitches.append([])
            alertSwitches.append([])
            groupsStack.addArrangedSubview(groupHeaderRow(for: group, groupIndex: groupIndex))
            groupsStack.addArrangedSubview(groupCard(for: group, groupIndex: groupIndex))
        }
    }

    private func groupHeaderRow(for group: AreasAlertsViewModel.RegionGroup, groupIndex: Int) -> UIView {
        let row = UIView()

        let nameLabel = UILabel()
        nameLabel.text = group.name.uppercased()
        nameLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        nameLabel.textColor = FireWireTheme.text
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(nameLabel)

        let actionButton = UIButton(type: .system)
        actionButton.setTitle(group.allFeedOn ? "UNSELECT ALL" : "SELECT ALL", for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .heavy)
        actionButton.tintColor = FireWireTheme.red
        actionButton.tag = groupIndex
        actionButton.addTarget(self, action: #selector(selectAllTap(_:)), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(actionButton)
        groupActionButtons.append(actionButton)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 40),
            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 4),
            nameLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor, constant: 4),
            actionButton.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -4),
            actionButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
        ])
        return row
    }

    private func groupCard(for group: AreasAlertsViewModel.RegionGroup, groupIndex: Int) -> UIView {
        let card = UIView()
        FireWireTheme.cardStyle(card)
        card.layer.cornerRadius = 14
        card.clipsToBounds = true
        borderedViews.append(card)

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = 0
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: card.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        for (rowIndex, areaRow) in group.rows.enumerated() {
            rowsStack.addArrangedSubview(areaRowView(
                for: areaRow,
                groupIndex: groupIndex,
                rowIndex: rowIndex,
                isLast: rowIndex == group.rows.count - 1))
        }
        return card
    }

    private func areaRowView(
        for areaRow: AreasAlertsViewModel.AreaRow,
        groupIndex: Int,
        rowIndex: Int,
        isLast: Bool
    ) -> UIView {
        let row = UIView()

        let nameLabel = UILabel()
        nameLabel.text = areaRow.name.uppercased()
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = FireWireTheme.text
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(nameLabel)

        let feedSwitch = UISwitch()
        feedSwitch.onTintColor = FireWireTheme.success
        feedSwitch.isOn = areaRow.feedOn
        feedSwitch.tag = switchTag(groupIndex: groupIndex, rowIndex: rowIndex)
        feedSwitch.addTarget(self, action: #selector(feedSwitchChanged(_:)), for: .valueChanged)
        feedSwitch.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(feedSwitch)
        feedSwitches[groupIndex].append(feedSwitch)

        let alertSwitch = UISwitch()
        alertSwitch.onTintColor = FireWireTheme.success
        alertSwitch.isOn = areaRow.feedOn && areaRow.alertOn
        alertSwitch.isEnabled = areaRow.feedOn
        alertSwitch.alpha = areaRow.feedOn ? 1.0 : 0.35
        alertSwitch.tag = switchTag(groupIndex: groupIndex, rowIndex: rowIndex)
        alertSwitch.addTarget(self, action: #selector(alertSwitchChanged(_:)), for: .valueChanged)
        alertSwitch.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(alertSwitch)
        alertSwitches[groupIndex].append(alertSwitch)

        var constraints: [NSLayoutConstraint] = [
            row.heightAnchor.constraint(equalToConstant: 58),

            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: feedSwitch.leadingAnchor, constant: -8),

            alertSwitch.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            alertSwitch.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            feedSwitch.trailingAnchor.constraint(equalTo: alertSwitch.leadingAnchor, constant: -14),
            feedSwitch.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ]

        if !isLast {
            let separator = UIView()
            separator.backgroundColor = FireWireTheme.hairline
            separator.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(separator)
            constraints += [
                separator.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1),
            ]
        }

        NSLayoutConstraint.activate(constraints)
        return row
    }

    private func switchTag(groupIndex: Int, rowIndex: Int) -> Int {
        groupIndex * 1000 + rowIndex
    }

    // MARK: State updates

    private func refreshRow(groupIndex: Int, rowIndex: Int) {
        let areaRow = viewModel.groups[groupIndex].rows[rowIndex]
        let alertSwitch = alertSwitches[groupIndex][rowIndex]
        alertSwitch.setOn(areaRow.feedOn && areaRow.alertOn, animated: true)
        alertSwitch.isEnabled = areaRow.feedOn
        alertSwitch.alpha = areaRow.feedOn ? 1.0 : 0.35
    }

    private func refreshGroupActionButton(groupIndex: Int) {
        let allOn = viewModel.groups[groupIndex].allFeedOn
        groupActionButtons[groupIndex].setTitle(allOn ? "UNSELECT ALL" : "SELECT ALL", for: .normal)
    }

    // MARK: Actions

    @objc private func backButtonTap() {
        coordinator?.popView()
    }

    @objc private func soundCardTap() {
        coordinator?.navigateToNotificationSounds()
    }

    @objc private func feedSwitchChanged(_ sender: UISwitch) {
        let groupIndex = sender.tag / 1000
        let rowIndex = sender.tag % 1000
        viewModel.toggleFeed(groupIndex: groupIndex, rowIndex: rowIndex)
        refreshRow(groupIndex: groupIndex, rowIndex: rowIndex)
        refreshGroupActionButton(groupIndex: groupIndex)
    }

    @objc private func alertSwitchChanged(_ sender: UISwitch) {
        let groupIndex = sender.tag / 1000
        let rowIndex = sender.tag % 1000

        // Push alerts are a premium feature — same gate the old Notification
        // Settings entry had on the personalization hub.
        if sender.isOn, unlockPremiumFeatureIfValid() {
            sender.setOn(false, animated: true)
            return
        }

        viewModel.toggleAlert(groupIndex: groupIndex, rowIndex: rowIndex)
    }

    @objc private func selectAllTap(_ sender: UIButton) {
        let groupIndex = sender.tag
        let turnOn = !viewModel.groups[groupIndex].allFeedOn
        viewModel.setFeedForAllRows(inGroup: groupIndex, on: turnOn)

        for rowIndex in viewModel.groups[groupIndex].rows.indices {
            feedSwitches[groupIndex][rowIndex].setOn(turnOn, animated: true)
            refreshRow(groupIndex: groupIndex, rowIndex: rowIndex)
        }
        refreshGroupActionButton(groupIndex: groupIndex)
    }

    @objc private func saveButtonTap() {
        guard !viewModel.groups.isEmpty else { return }

        guard viewModel.hasFeedSelection else {
            showAlert(
                title: "",
                message: "Select at least one location to proceed.",
                actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        guard viewModel.feedChanged || viewModel.alertChanged else {
            coordinator?.popView()
            return
        }

        showLoader()
        viewModel.save()
    }

    func unlockPremiumFeatureIfValid() -> Bool {
        if FWUserDefaults().userRole == "basic_user" {
            coordinator?.navigateToSubscriptionInfo()
            return true
        }
        return false
    }

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> AreasAlertsViewController {
        return AreasAlertsViewController()
    }
}
