//
//  SelectAreaViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 08/02/25.
//

import UIKit

protocol SelectAreaDelegate: AnyObject {
    func confirmSelectArea()
}

class SelectAreaViewController: UIViewController, IncidentLocalityListViewDelegate, SelectAreaDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var confirmButton: FWFilledButton!

    weak var parentCoordinator: AppCoordinator?
    var coordinator: IncidentsCoordinator?
    var viewModel: IncidentLocalityListViewModel!
    var selectedAreas: SelectedLocalities!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        showActivityIndicator(true)
        viewModel = IncidentLocalityListViewModel()
        viewModel.delegate = self
        viewModel.selectAreaDelegate = self
        viewModel.getLocalities(forType: .area)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(IncidentLocalityListItem.nib(), forCellReuseIdentifier: IncidentLocalityListItem.identifier)
        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
    }

    func dataReceived() {
        showActivityIndicator(false)
        tableView.reloadData()
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

    @IBAction func confirmButtonTap(_ sender: UIButton) {
        showLoader()
        viewModel.setSelectedLocalities()
    }

    func confirmSelectArea() {
        hideLoader()
        coordinator?.backToParentCoordinator()
        parentCoordinator?.navigateToHome()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> SelectAreaViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SelectAreaViewController") as! SelectAreaViewController
        return viewController
    }
}

extension SelectAreaViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.localityData.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: CityHeaderCell.identifier) as! CityHeaderCell
        headerView.setupView(title: viewModel.localityData[section].name)
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
