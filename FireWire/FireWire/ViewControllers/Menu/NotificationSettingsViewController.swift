//
//  NotificationSettingsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class NotificationSettingsViewController: UIViewController {
    var coordinator: HomeCoordinator?
    var localityList = ["Long Island", "New York City", "USA"]

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
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
        let sectionLabel = UILabel()
        sectionLabel.frame = CGRect(x: 20, y: sectionLabel.frame.origin.y, width: sectionLabel.frame.size.width, height: sectionLabel.frame.size.height)
        sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
        sectionLabel.textColor = UIColor.black
        sectionLabel.text = "Choose a Locality"
        sectionLabel.sizeToFit()

        let headerView = UIView()
        headerView.addSubview(sectionLabel)

        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        localityList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalityCell") as! LocalityCell
        cell.setupView(localityList[indexPath.row])
        return cell
    }

}
