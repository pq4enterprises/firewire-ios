//
//  IncidentLocalityListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/11/24.
//

import UIKit

protocol IncidentLocalityListViewDelegate: AnyObject {
    func dataReceived()
    func error(message: String)
}

class IncidentLocalityListViewController: UIViewController, IncidentLocalityListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!

    var coordinator: HomeCoordinator?
    var viewModel: IncidentLocalityListViewModel!
    var selectedAreas: SelectedLocalities!

    init(viewModel: IncidentLocalityListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showActivityIndicator(true)
        viewModel?.getLocalities(forType: .area)
        setupTableView()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.register(IncidentLocalityListItem.nib(), forCellReuseIdentifier: IncidentLocalityListItem.identifier)
        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
    }

    @IBAction func doneButtonTap(_ sender: UIButton) {
        if viewModel.selectedAreas.isEmpty {
            showAlert(title: "", message: "Select at least one location to proceed.", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        viewModel.setSelectedLocalities()
        coordinator?.dismissView(animated: true)
        //debugPrint("Selected areas \(self.viewModel.getSelectedIds())")
        //self.coordinator?.start(with: [], viewModel.getSelectedIds())
    }

    func dataReceived() {
        showActivityIndicator(false)
        tableView.reloadData()
    }

    func error(message: String) {
        showActivityIndicator(false)
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    func showActivityIndicator(_ value: Bool) {
        if value {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()

            tableView.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true

            tableView.isHidden = false
        }
    }
}

extension IncidentLocalityListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.localityData.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: CityHeaderCell.identifier) as! CityHeaderCell

        headerView.setupView(
            title: viewModel.localityData[section].name,
            isAllSelected: viewModel.isLocalityAllChecked(section: section)
        )

        headerView.selectAllAction = {
            self.viewModel.toggleSelectAll(forSection: section)
            tableView.reloadSections([section], with: .automatic)
            tableView.reloadData()
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.localityData[section].subLocality.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncidentLocalityListItem.identifier, for: indexPath) as! IncidentLocalityListItem
        cell.setupView(viewModel.localityData[indexPath.section], indexPath)
        cell.onCheckboxToggled = { [weak self] indexPath in
            self?.viewModel.toggleSelection(at: indexPath)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
        }

        return cell
    }
}
