//
//  AlertFiltersViewController.swift
//  FireWire
//
//  Iteration 1 — per-locality alert picker ("<Locality> alerts").
//  Programmatic UIKit on FireWireTheme, same header / sticky-save shell as
//  AreasAlertsViewController. Two sections — INCIDENT TYPES and UNITS — each
//  with an "All …" switch; when the switch is off the section shows a
//  checklist (units get a search field and SELECT ALL / NONE).
//
//  Everything is a cell in an inset-grouped table so the cards line up:
//    section 0  INCIDENT TYPES  — All switch row, then type rows (when off)
//    section 1  UNITS           — All switch row, search row, count row (when off)
//    section 2                  — unit rows (when off; can be ~2k for NYC)
//  Only section 2 is reloaded while the user types, so the search field in
//  section 1 keeps the keyboard.
//
//  Reached from Areas & Alerts via the per-locality TYPES & UNITS row, and
//  premium-gated there the same way the ALERT switches are.
//
//  NOTE: no design exists for this screen yet — built to match the redesign's
//  look; needs design polish.
//

import UIKit
import FirebaseAnalytics

class AlertFiltersViewController: UIViewController {
    var coordinator: HomeCoordinator?
    let viewModel: AlertFiltersViewModel

    typealias Section = AlertFiltersViewModel.Section

    private enum TableSection: Int, CaseIterable {
        case types
        case unitControls
        case unitRows
    }

    private enum ReuseId {
        static let toggle = "AlertFilterSwitchCell"
        static let search = "AlertFilterSearchCell"
        static let count = "AlertFilterCountCell"
        static let check = "AlertFilterCheckCell"
        static let empty = "AlertFilterEmptyCell"
    }

    // MARK: Views

    private let headerBar = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let bottomBar = UIView()
    private let saveButton = UIButton(type: .system)

    /// Inline validation flags, shown on the section's All-switch row.
    private var showTypesValidation = false
    private var showUnitsValidation = false
    private var hasLoaded = false

    // MARK: Init

    init(localityId: String, localityName: String) {
        viewModel = AlertFiltersViewModel(localityId: localityId, localityName: localityName)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        bindViewModel()
        observeKeyboard()
        showLoader()
        viewModel.load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_alert_filters"
        ])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: View model binding

    private func bindViewModel() {
        viewModel.onDataLoaded = { [weak self] in
            guard let self else { return }
            self.hideLoader()
            self.hasLoaded = true
            self.updateTitle()
            self.tableView.reloadData()
        }

        viewModel.onError = { [weak self] message in
            guard let self else { return }
            self.hideLoader()
            if !self.hasLoaded {
                // Nothing on screen yet — offer a retry or a way out.
                self.showAlert(
                    title: "",
                    message: message,
                    actions: [
                        UIAlertAction(title: "Retry", style: .default) { _ in
                            self.showLoader()
                            self.viewModel.load()
                        },
                        UIAlertAction(title: "Back", style: .cancel) { _ in
                            self.coordinator?.popView()
                        },
                    ])
            } else {
                self.showAlert(
                    title: "",
                    message: message,
                    actions: [UIAlertAction(title: "Ok", style: .cancel)])
            }
        }

        viewModel.onSaved = { [weak self] in
            guard let self else { return }
            self.hideLoader()
            Analytics.logEvent("alert_filters_saved", parameters: [
                AnalyticsParameterScreenName: "ios_alert_filters",
                "types_all": self.viewModel.typesAll ? 1 : 0,
                "units_all": self.viewModel.unitsAll ? 1 : 0,
                "type_count": self.viewModel.typesAll ? 0 : self.viewModel.checkedCount(in: .types),
                "unit_count": self.viewModel.unitsAll ? 0 : self.viewModel.checkedCount(in: .units),
            ])
            self.coordinator?.popView()
        }
    }

    // MARK: UI construction

    private func buildUI() {
        view.backgroundColor = FireWireTheme.background
        buildHeaderBar()
        buildBottomBar()
        buildTable()
    }

    private func updateTitle() {
        titleLabel.text = "\(viewModel.localityName) ALERTS".uppercased()
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

        updateTitle()
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
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
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
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

    private func buildTable() {
        tableView.backgroundColor = FireWireTheme.background
        tableView.separatorColor = FireWireTheme.hairline
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.alwaysBounceVertical = true
        tableView.sectionHeaderTopPadding = 6
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionHeaderHeight = 28
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AlertFilterSwitchCell.self, forCellReuseIdentifier: ReuseId.toggle)
        tableView.register(AlertFilterSearchCell.self, forCellReuseIdentifier: ReuseId.search)
        tableView.register(AlertFilterCountCell.self, forCellReuseIdentifier: ReuseId.count)
        tableView.register(AlertFilterCheckCell.self, forCellReuseIdentifier: ReuseId.check)
        tableView.register(AlertFilterEmptyCell.self, forCellReuseIdentifier: ReuseId.empty)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
        ])
    }

    // MARK: Keyboard

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardTop = view.convert(frame, from: nil).minY
        let overlap = max(0, tableView.frame.maxY - keyboardTop)
        tableView.contentInset.bottom = overlap
        tableView.verticalScrollIndicatorInsets.bottom = overlap
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset.bottom = 0
        tableView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: Row helpers

    private static let searchRow = 1
    private static let countRow = 2

    private var unitsSearchIndexPath: IndexPath {
        IndexPath(row: Self.searchRow, section: TableSection.unitControls.rawValue)
    }

    private var unitsCountIndexPath: IndexPath {
        IndexPath(row: Self.countRow, section: TableSection.unitControls.rawValue)
    }

    private func switchIndexPath(_ section: Section) -> IndexPath {
        IndexPath(row: 0, section: section == .types ? TableSection.types.rawValue : TableSection.unitControls.rawValue)
    }

    /// Refreshes the units "N of M selected" row in place (no reload, so the
    /// search field keeps the keyboard).
    private func refreshUnitsCountCell() {
        guard let cell = tableView.cellForRow(at: unitsCountIndexPath) as? AlertFilterCountCell else { return }
        configureCountCell(cell)
    }

    private func refreshTypesSwitchCell() {
        guard let cell = tableView.cellForRow(at: switchIndexPath(.types)) as? AlertFilterSwitchCell else { return }
        configureSwitchCell(cell, section: .types)
    }

    private func refreshUnitsSwitchCell() {
        guard let cell = tableView.cellForRow(at: switchIndexPath(.units)) as? AlertFilterSwitchCell else { return }
        configureSwitchCell(cell, section: .units)
    }

    // MARK: Cell configuration

    private func configureSwitchCell(_ cell: AlertFilterSwitchCell, section: Section) {
        let all = viewModel.isAll(section)
        let invalid = section == .types ? showTypesValidation : showUnitsValidation
        let subtitle: String
        if invalid, !all {
            subtitle = "Pick at least one, or switch All back on"
        } else if all {
            subtitle = "Alerts for every \(section == .types ? "incident type" : "unit") in this area"
        } else {
            subtitle = "Only the \(section == .types ? "incident types" : "units") you pick below"
        }
        cell.configure(title: section.allLabel, subtitle: subtitle, isOn: all, highlightSubtitle: invalid && !all)
        cell.onToggle = { [weak self] on in
            self?.allSwitchChanged(on, section: section)
        }
    }

    private func configureCountCell(_ cell: AlertFilterCountCell) {
        let total = viewModel.units.count
        let checked = viewModel.checkedCount(in: .units)
        let visible = viewModel.visibleCount(in: .units)
        let text = viewModel.unitSearchText.isEmpty
            ? "\(checked) of \(total) selected"
            : "\(checked) of \(total) selected · \(visible) match"
        cell.configure(
            text: text,
            actionTitle: viewModel.allVisibleChecked(in: .units) ? "SELECT NONE" : "SELECT ALL",
            actionHidden: visible == 0)
        cell.onAction = { [weak self] in
            self?.selectAllTap(.units)
        }
    }

    // MARK: Actions

    @objc private func backButtonTap() {
        view.endEditing(true)
        coordinator?.popView()
    }

    private func allSwitchChanged(_ on: Bool, section: Section) {
        view.endEditing(true)
        viewModel.setAll(on, in: section)
        if section == .types {
            showTypesValidation = false
            tableView.reloadSections(IndexSet(integer: TableSection.types.rawValue), with: .automatic)
        } else {
            showUnitsValidation = false
            tableView.reloadSections(
                IndexSet([TableSection.unitControls.rawValue, TableSection.unitRows.rawValue]), with: .automatic)
        }
    }

    private func selectAllTap(_ section: Section) {
        let checkAll = !viewModel.allVisibleChecked(in: section)
        viewModel.setVisible(checked: checkAll, in: section)
        switch section {
        case .types:
            if checkAll { showTypesValidation = false }
            tableView.reloadSections(IndexSet(integer: TableSection.types.rawValue), with: .none)
        case .units:
            if checkAll { showUnitsValidation = false }
            UIView.performWithoutAnimation {
                tableView.reloadSections(IndexSet(integer: TableSection.unitRows.rawValue), with: .none)
            }
            refreshUnitsCountCell()
            refreshUnitsSwitchCell()
        }
    }

    private func searchChanged(_ text: String) {
        viewModel.setUnitSearch(text)
        UIView.performWithoutAnimation {
            tableView.reloadSections(IndexSet(integer: TableSection.unitRows.rawValue), with: .none)
        }
        refreshUnitsCountCell()
    }

    private func searchDidBegin() {
        // Keyboard inset lands a beat later; then bring the field to the top.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self, self.tableView.numberOfRows(inSection: TableSection.unitControls.rawValue) > Self.searchRow
            else { return }
            self.tableView.scrollToRow(at: self.unitsSearchIndexPath, at: .top, animated: true)
        }
    }

    @objc private func saveButtonTap() {
        view.endEditing(true)

        // Refuse an OFF section with nothing picked — inline, on that section.
        showTypesValidation = viewModel.needsSelection(.types)
        showUnitsValidation = viewModel.needsSelection(.units)
        if showTypesValidation || showUnitsValidation {
            let target = switchIndexPath(showTypesValidation ? .types : .units)
            tableView.reloadRows(at: [switchIndexPath(.types), switchIndexPath(.units)], with: .none)
            tableView.scrollToRow(at: target, at: .top, animated: true)
            return
        }

        guard viewModel.hasChanges else {
            coordinator?.popView()
            return
        }

        showLoader()
        viewModel.save()
    }
}

// MARK: - Table data source / delegate

extension AlertFiltersViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        hasLoaded ? TableSection.allCases.count : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = TableSection(rawValue: section) else { return 0 }
        switch section {
        case .types:
            return 1 + viewModel.visibleCount(in: .types)
        case .unitControls:
            return viewModel.unitsAll ? 1 : 3
        case .unitRows:
            guard !viewModel.unitsAll else { return 0 }
            let visible = viewModel.visibleCount(in: .units)
            return visible == 0 ? 1 : visible   // 1 = "no match" row
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = TableSection(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .types:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.toggle, for: indexPath) as! AlertFilterSwitchCell
                configureSwitchCell(cell, section: .types)
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.check, for: indexPath) as! AlertFilterCheckCell
            let item = viewModel.item(forRow: indexPath.row - 1, in: .types)
            cell.configure(name: item.name, checked: item.checked)
            return cell

        case .unitControls:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.toggle, for: indexPath) as! AlertFilterSwitchCell
                configureSwitchCell(cell, section: .units)
                return cell
            case Self.searchRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.search, for: indexPath) as! AlertFilterSearchCell
                cell.configure(text: viewModel.unitSearchText)
                cell.onTextChanged = { [weak self] text in self?.searchChanged(text) }
                cell.onBeginEditing = { [weak self] in self?.searchDidBegin() }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.count, for: indexPath) as! AlertFilterCountCell
                configureCountCell(cell)
                return cell
            }

        case .unitRows:
            if viewModel.visibleCount(in: .units) == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.empty, for: indexPath) as! AlertFilterEmptyCell
                cell.configure(text: viewModel.units.isEmpty ? "No units in this area yet" : "No units match your search")
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseId.check, for: indexPath) as! AlertFilterCheckCell
            let item = viewModel.item(forRow: indexPath.row, in: .units)
            cell.configure(name: item.name, checked: item.checked)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = TableSection(rawValue: indexPath.section) else { return 50 }
        switch section {
        case .types:
            return indexPath.row == 0 ? UITableView.automaticDimension : 50
        case .unitControls:
            return indexPath.row == 0 ? UITableView.automaticDimension : 50
        case .unitRows:
            return 50
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = TableSection(rawValue: section) else { return nil }
        switch section {
        case .types: return AlertFilterCaptionHeaderView(text: Section.types.title)
        case .unitControls: return AlertFilterCaptionHeaderView(text: Section.units.title)
        case .unitRows: return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == TableSection.unitRows.rawValue ? .leastNonzeroMagnitude : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch TableSection(rawValue: section) {
        case .types: return 14
        case .unitControls: return viewModel.unitsAll ? 14 : 2
        default: return 16
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = TableSection(rawValue: indexPath.section) else { return }
        switch section {
        case .types:
            guard indexPath.row > 0 else { return }
            viewModel.toggle(row: indexPath.row - 1, in: .types)
            let item = viewModel.item(forRow: indexPath.row - 1, in: .types)
            (tableView.cellForRow(at: indexPath) as? AlertFilterCheckCell)?.setChecked(item.checked, animated: true)
            if showTypesValidation, viewModel.checkedCount(in: .types) > 0 {
                showTypesValidation = false
                refreshTypesSwitchCell()
            }
        case .unitControls:
            if indexPath.row == Self.searchRow {
                (tableView.cellForRow(at: indexPath) as? AlertFilterSearchCell)?.focus()
            }
        case .unitRows:
            guard viewModel.visibleCount(in: .units) > 0 else { return }
            viewModel.toggle(row: indexPath.row, in: .units)
            let item = viewModel.item(forRow: indexPath.row, in: .units)
            (tableView.cellForRow(at: indexPath) as? AlertFilterCheckCell)?.setChecked(item.checked, animated: true)
            refreshUnitsCountCell()
            if showUnitsValidation, viewModel.checkedCount(in: .units) > 0 {
                showUnitsValidation = false
                refreshUnitsSwitchCell()
            }
        }
    }
}

// MARK: - Caption header

/// Monospaced eyebrow caption ("INCIDENT TYPES" / "UNITS") — same treatment as
/// the GLOBAL ALERT SOUND caption on Areas & Alerts. Stateless, so it is safe
/// to recreate on every reload.
final class AlertFilterCaptionHeaderView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
                .kern: 1.0,
                .foregroundColor: FireWireTheme.muted,
            ])
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// MARK: - "All …" switch cell

final class AlertFilterSwitchCell: UITableViewCell {
    var onToggle: ((Bool) -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let toggle = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = FireWireTheme.surface

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = FireWireTheme.muted
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)

        toggle.onTintColor = FireWireTheme.success
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toggle)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -10),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -10),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13),

            toggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    func configure(title: String, subtitle: String, isOn: Bool, highlightSubtitle: Bool) {
        titleLabel.text = title.uppercased()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = highlightSubtitle ? FireWireTheme.red : FireWireTheme.muted
        subtitleLabel.font = .systemFont(ofSize: 11, weight: highlightSubtitle ? .bold : .medium)
        if toggle.isOn != isOn { toggle.setOn(isOn, animated: false) }
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}

// MARK: - Units search cell

final class AlertFilterSearchCell: UITableViewCell, UITextFieldDelegate {
    var onTextChanged: ((String) -> Void)?
    var onBeginEditing: (() -> Void)?

    private let searchField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = FireWireTheme.surface

        let magnifier = UIImageView(image: UIImage(
            systemName: "magnifyingglass",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        magnifier.tintColor = FireWireTheme.muted
        magnifier.contentMode = .scaleAspectFit
        magnifier.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(magnifier)

        searchField.placeholder = "Search units (e.g. E-1, L-10, BC)"
        searchField.font = .systemFont(ofSize: 15, weight: .medium)
        searchField.textColor = FireWireTheme.text
        searchField.tintColor = FireWireTheme.red
        searchField.clearButtonMode = .whileEditing
        searchField.autocorrectionType = .no
        searchField.spellCheckingType = .no
        searchField.autocapitalizationType = .allCharacters
        searchField.returnKeyType = .done
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchField)

        NSLayoutConstraint.activate([
            magnifier.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            magnifier.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            magnifier.widthAnchor.constraint(equalToConstant: 18),

            searchField.leadingAnchor.constraint(equalTo: magnifier.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTextChanged = nil
        onBeginEditing = nil
    }

    func configure(text: String) {
        if searchField.text != text { searchField.text = text }
    }

    func focus() {
        searchField.becomeFirstResponder()
    }

    @objc private func textChanged() {
        onTextChanged?(searchField.text ?? "")
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Count + SELECT ALL / NONE cell

final class AlertFilterCountCell: UITableViewCell {
    var onAction: (() -> Void)?

    private let countLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = FireWireTheme.surface

        countLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        countLabel.textColor = FireWireTheme.muted
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countLabel)

        actionButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .heavy)
        actionButton.tintColor = FireWireTheme.red
        actionButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),

            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAction = nil
    }

    func configure(text: String, actionTitle: String, actionHidden: Bool) {
        countLabel.text = text
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionHidden
    }

    @objc private func actionTap() {
        onAction?()
    }
}

// MARK: - Checklist cell

final class AlertFilterCheckCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let checkIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = FireWireTheme.surface
        let selected = UIView()
        selected.backgroundColor = FireWireTheme.surface2
        selectedBackgroundView = selected

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = FireWireTheme.text
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        checkIcon.contentMode = .scaleAspectFit
        checkIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkIcon)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkIcon.leadingAnchor, constant: -10),

            checkIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            checkIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 24),
            checkIcon.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(name: String, checked: Bool) {
        nameLabel.text = name.uppercased()
        accessibilityLabel = name
        setChecked(checked, animated: false)
    }

    func setChecked(_ checked: Bool, animated: Bool) {
        let image = UIImage(systemName: checked ? "checkmark.circle.fill" : "circle")
        let tint = checked ? FireWireTheme.red : FireWireTheme.muted
        if animated {
            UIView.transition(with: checkIcon, duration: 0.15, options: .transitionCrossDissolve) {
                self.checkIcon.image = image
                self.checkIcon.tintColor = tint
            }
        } else {
            checkIcon.image = image
            checkIcon.tintColor = tint
        }
        accessibilityTraits = checked ? [.button, .selected] : [.button]
    }
}

// MARK: - Empty-state cell

final class AlertFilterEmptyCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = FireWireTheme.surface
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = FireWireTheme.muted
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(text: String) {
        label.text = text
    }
}
