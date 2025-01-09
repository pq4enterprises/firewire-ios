//
//  IncidentListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

protocol PostListViewDelegate: AnyObject {
    func filterDataReceived()
}

class IncidentListViewController: UIViewController {
    @IBOutlet weak var incidentListCount: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var coordinator: IncidentsCoordinator?
    var viewModel: IncidentListViewModel

    init(viewModel: IncidentListViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        //viewModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //showActivityIndicator(true)
    }

    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(IncidentListViewCell.nib(), forCellReuseIdentifier: IncidentListViewCell.identifier)

        incidentListCount.text = "\(viewModel.incidentList.count) posts are listed"
    }

    @IBAction func filterButtonTap(_ sender: UIButton) {
        coordinator?.popView()
        coordinator?.navigateToSelectAreaListView()
    }

    //    func dataReceived() {
    //        showActivityIndicator(false)
    //        tableView.reloadData()
    //        incidentListCount.text = "\(viewModel.incidentList.count) posts are listed"
    //    }

    //    func showActivityIndicator(_ value: Bool){
    //        if value {
    //            activityIndicator.isHidden = false
    //            activityIndicator.startAnimating()
    //
    //            tableView.isHidden = true
    //        }else{
    //            activityIndicator.stopAnimating()
    //            activityIndicator.isHidden = true
    //
    //            tableView.isHidden = false
    //        }
    //    }
}

extension IncidentListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.incidentList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncidentListViewCell.identifier, for: indexPath) as! IncidentListViewCell
        cell.setupView(viewModel.incidentList[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.dismissView(animated: true)
        let selectedIncidentID = viewModel.incidentList[indexPath.row].id
        coordinator?.navigateToIncidentDetail(selectedIncidentID)
    }

}
