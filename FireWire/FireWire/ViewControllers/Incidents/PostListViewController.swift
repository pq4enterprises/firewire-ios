//
//  MapListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

protocol PostListViewDelegate: AnyObject {
    func dataReceived()
}

class PostListViewController: UIViewController, PostListViewDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var incidentListCount: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var coordinator: IncidentsCoordinator?
    var viewModel: PostListViewModel

    init(viewModel: PostListViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
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
        showActivityIndicator(true)
    }

    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(PostListViewCell.nib(), forCellReuseIdentifier: PostListViewCell.identifier)
    }

    @IBAction func filterButtonTap(_ sender: UIButton) {
        coordinator?.popView()
        coordinator?.navigateToSelectAreaListView()
    }

    func dataReceived() {
        showActivityIndicator(false)
        tableView.reloadData()
        incidentListCount.text = "\(viewModel.incidentList.count) posts are listed"
    }

    func showActivityIndicator(_ value: Bool){
        if value {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()

            tableView.isHidden = true
        }else{
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true

            tableView.isHidden = false
        }
    }
}

extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.incidentList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostListViewCell.identifier, for: indexPath) as! PostListViewCell
        cell.setupView(viewModel.incidentList[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.dismissView(animated: true)
        let selectedIncidentID = viewModel.incidentList[indexPath.row].id
        coordinator?.navigateToPostDetail(selectedIncidentID)
    }

}
