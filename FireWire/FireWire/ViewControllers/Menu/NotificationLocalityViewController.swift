//
//  NotificationLocalityViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class NotificationLocalityViewController: UIViewController {
    var coordinator: HomeCoordinator?

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(SelectAreaListViewCell.nib(), forCellReuseIdentifier: SelectAreaListViewCell.identifier)
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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 5
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = tableView.dequeueReusableCell(withIdentifier: CityHeaderCell.identifier) as! CityHeaderCell
            headerView.setupView(title: "New York City")
            return headerView
        } else if section == 1 {
            let headerView = tableView.dequeueReusableCell(withIdentifier: LocalityHeaderCell.identifier) as! LocalityHeaderCell
            headerView.setupView()
            return headerView
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectAreaListViewCell") as! SelectAreaListViewCell
        return cell
    }
}
