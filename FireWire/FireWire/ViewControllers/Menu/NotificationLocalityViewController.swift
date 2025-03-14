//
//  NotificationLocalityViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

protocol NotificationLocalityDelegate: AnyObject {
    func setNotification(message: String)
}

class NotificationLocalityViewController: UIViewController, NotificationLocalityDelegate {
    var coordinator: HomeCoordinator?
    var localityData: LocalityResponseData?
    var localitySubHeadings = ["Sublocalities", "Units", "Incident Types"]
    var viewModel: NotificationLocalityViewModel?

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = NotificationLocalityViewModel()
        viewModel?.localityData = localityData
        viewModel?.saveAlreadySelectedArea()
        viewModel?.delegate = self
        setupTableView()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.sectionHeaderTopPadding = 0 // iOS 15+ to avoid space above section headers

        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
        tableView.register(SelectAreaListViewCell.nib(), forCellReuseIdentifier: SelectAreaListViewCell.identifier)
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    @IBAction func saveButtonTap(_ sender: UIButton) {
        showLoader()
        viewModel?.setSelectedLocalities()
    }

    func setNotification(message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> NotificationLocalityViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NotificationLocalityViewController") as! NotificationLocalityViewController
        return viewController
    }
}

extension NotificationLocalityViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let localityData = viewModel?.localityData else { return 0 }

        if section == 1 {
            return localityData.subLocality.count
        } else if section == 2 {
            return localityData.unit?.count ?? 0
        } else if section == 3 {
            return localityData.incidentType?.count ?? 0
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        54.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let localityData = viewModel?.localityData else { return nil }

        let headerView = tableView.dequeueReusableCell(withIdentifier: CityHeaderCell.identifier) as! CityHeaderCell

        if section == 0 {
            headerView.setupView(title: localityData.name, hideSelectAll: true)
        } else if section == 1 {
            headerView.setupView(
                title: localitySubHeadings[0],
                isAllSelected: viewModel?.isLocalityAllChecked() ?? false
            )
            headerView.selectAllAction = {
                self.viewModel?.toggleSelectAllSubLocalities()
                tableView.reloadData()
            }
        } else if section == 2 {
            if let units = localityData.unit, units.count > 0 {
                headerView.setupView(
                    title: localitySubHeadings[1],
                    isAllSelected: viewModel?.isUnitsAllChecked() ?? false
                )

                headerView.selectAllButton.isHidden = false
                headerView.selectAllAction = {
                    self.viewModel?.toggleSelectAllUnits()
                    tableView.reloadData()
                }
            } else {
                headerView.setupView(title: "")
                headerView.selectAllButton.isHidden = true
            }
        } else if section == 3 {
            if let incidentType = localityData.incidentType, incidentType.count > 0 {
                headerView.setupView(
                    title: localitySubHeadings[2],
                    isAllSelected: viewModel?.isIncidentTypeAllChecked() ?? false
                )
                headerView.selectAllButton.isHidden = false
                headerView.selectAllAction = {
                    self.viewModel?.toggleSelectAllIncidentTypes()
                    tableView.reloadData()
                }
            } else {
                headerView.setupView(title: "")
                headerView.selectAllButton.isHidden = true
            }
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let localityData = viewModel?.localityData else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: SelectAreaListViewCell.identifier) as! SelectAreaListViewCell
        cell.setupView(localityData, indexPath)
        cell.onCheckboxToggled = { [weak self] indexPath in
            self?.viewModel?.toggleSelection(at: indexPath)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
        }
        return cell
    }
}
