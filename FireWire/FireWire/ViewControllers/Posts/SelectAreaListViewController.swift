//
//  FilterListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/11/24.
//

import UIKit

class SelectAreaListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var coordinator: IncidentsCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(SelectAreaListViewCell.nib(), forCellReuseIdentifier: SelectAreaListViewCell.identifier)
    }

    @IBAction func doneButtonTap(_ sender: UIButton) {
        coordinator?.popView()
        coordinator?.start()
    }
}

extension SelectAreaListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectAreaListViewCell.identifier, for: indexPath) as! SelectAreaListViewCell
        cell.areaLabel.text = "Area \(indexPath.row)"
        cell.selectAreaAction = {
            debugPrint("Checkbox tap")
            if cell.selectAreaButton.tag == 0 { // Temp logic to update checkbox
                cell.selectAreaButton.tag = 1
                cell.selectAreaButton.setImage(FWImage.checkBoxChecked, for: .normal)
            }else{
                cell.selectAreaButton.tag = 0
                cell.selectAreaButton.setImage(FWImage.checkBoxUnChecked, for: .normal)
            }
        }
        return cell
    }



}
