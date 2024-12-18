//
//  FilterListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/11/24.
//

import UIKit

protocol SelectAreaViewDelegate: AnyObject {
    func dataReceived()
}

class SelectAreaListViewController: UIViewController, SelectAreaViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!

    var coordinator: IncidentsCoordinator?
    var viewModel: SelectAreaViewModel!
    var selectedAreas: SelectedLocalities!

    init(viewModel: SelectAreaViewModel) {
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
        viewModel?.getLocalities()
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showActivityIndicator(true)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(SelectAreaListViewCell.nib(), forCellReuseIdentifier: SelectAreaListViewCell.identifier)
        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
    }

    @IBAction func doneButtonTap(_ sender: UIButton) {
        coordinator?.popView()
        self.coordinator?.start(with: [], selectedAreas)
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
}

extension SelectAreaListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.localityData.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: CityHeaderCell.identifier) as! CityHeaderCell
        headerView.setupView(title: viewModel.localityData[section].name)
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.localityData[section].subLocality.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectAreaListViewCell.identifier, for: indexPath) as! SelectAreaListViewCell
        cell.setupView(viewModel.localityData[indexPath.section], indexPath)

        cell.selectAreaAction = { selectedArea in
            self.selectedAreas = selectedArea
        }
        return cell
    }
}
