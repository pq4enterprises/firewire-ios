//
//  FeedAreaListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 22/02/25.
//

import UIKit

class FeedAreaListViewController: UIViewController, IncidentLocalityListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!

    var coordinator: HomeCoordinator?
    var viewModel: IncidentLocalityListViewModel!
    var selectedAreas: SelectedLocalities!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel?.getLocalities(forType: .area)
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showActivityIndicator(true)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(IncidentLocalityListItem.nib(), forCellReuseIdentifier: IncidentLocalityListItem.identifier)
        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
    }

    @IBAction func doneButtonTap(_ sender: UIButton) {
        viewModel.setSelectedLocalities()
        coordinator?.popView()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }
    
    func dataReceived() {
        showActivityIndicator(false)
        tableView.reloadData()
    }

    func error(message: String) {
        showActivityIndicator(false)
        showAlertMessage(message)
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

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> FeedAreaListViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeedAreaListViewController") as! FeedAreaListViewController
        return viewController
    }
}

extension FeedAreaListViewController: UITableViewDataSource, UITableViewDelegate {
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
