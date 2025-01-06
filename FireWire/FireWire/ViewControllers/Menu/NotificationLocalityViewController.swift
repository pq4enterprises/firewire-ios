//
//  NotificationLocalityViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class NotificationLocalityViewController: UIViewController {
    var coordinator: HomeCoordinator?
    var localityData: LocalityResponseData?
    var localitySubHeadings = ["Sublocalities", "Units"]

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(SelectAreaListViewCell.nib(), forCellReuseIdentifier: SelectAreaListViewCell.identifier)
        tableView.register(NotificationLocalityHeaderView.nib(), forHeaderFooterViewReuseIdentifier: NotificationLocalityHeaderView.identifier)
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
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
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let localityData else { return 0 }

        if section == 1 {
            debugPrint("section 1 count -- \(localityData.subLocality.count)")
            return localityData.subLocality.count
        }else if section == 2 {
            debugPrint("section 2 count -- \(localityData.unit?.count ?? 0)")
            return localityData.unit?.count ?? 0
        }else{
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        54.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let localityData else { return nil }

        // Dequeue the custom header view
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: NotificationLocalityHeaderView.identifier) as? NotificationLocalityHeaderView else {
            return nil
        }

        if section == 0 {
            headerView.cityTitle.text = localityData.name
        } else if section == 1 {
            headerView.cityTitle.text = localitySubHeadings[0]
            headerView.cityTitle.font = UIFont.boldSystemFont(ofSize: 18.0)
        }else if section == 2 {
            if let units = localityData.unit, units.count > 0 {
                headerView.cityTitle.text = localitySubHeadings[1]
                headerView.cityTitle.font = UIFont.boldSystemFont(ofSize: 18.0)
            }else{
                headerView.cityTitle.text = ""
            }
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let localityData else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: SelectAreaListViewCell.identifier) as! SelectAreaListViewCell
        cell.setupView(localityData, indexPath)
        return cell
    }
}
