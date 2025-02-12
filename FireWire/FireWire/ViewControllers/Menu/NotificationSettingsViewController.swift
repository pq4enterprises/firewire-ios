//
//  NotificationSettingsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class NotificationSettingsViewController: UIViewController, IncidentLocalityListViewDelegate {
    var coordinator: HomeCoordinator?
    var viewModel: IncidentLocalityListViewModel!

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = IncidentLocalityListViewModel()
        viewModel.delegate = self

        showLoader()
        viewModel.getLocalities(forType: .notification)

        setupTableView()
    }

    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self

        tableView.sectionHeaderTopPadding = 0  // iOS 15+ to avoid space above section headers
    }

    func dataReceived() {
        hideLoader()
        tableView.reloadData()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> NotificationSettingsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NotificationSettingsViewController") as! NotificationSettingsViewController
        return viewController
    }

}

extension NotificationSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: NotificationChooseLocalityHeaderCell.identifier) as! NotificationChooseLocalityHeaderCell
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.localityData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationLocalityCell.identifier) as! NotificationLocalityCell
        cell.setupView(viewModel.localityData[indexPath.row].name)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.navigateToNotificationLocalityView(viewModel.localityData[indexPath.row])
    }

}
