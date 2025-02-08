//
//  IncidentListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

extension Notification.Name {
    static let incidentListDidChange = Notification.Name("incidentListDidChange")
}

protocol PostListViewDelegate: AnyObject {
    func filterDataReceived()
    func noIncidentData()
    func error(message: String)
}

class IncidentListViewController: UIViewController, PostListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var incidentListCount: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noIncidentsLabel: UILabel!

    var coordinator: IncidentsCoordinator?
    var viewModel: IncidentListViewModel
    var paginationHandler: PaginationHandler<IncidentListViewModel>!

    init(viewModel: IncidentListViewModel) {
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
        setupTableView()
        showActivityIndicator(true)
        paginationHandler = PaginationHandler(viewModel: viewModel)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(IncidentListViewCell.nib(), forCellReuseIdentifier: IncidentListViewCell.identifier)

        incidentListCount.text = "\(viewModel.items.count) posts are listed"
    }

    @IBAction func filterButtonTap(_ sender: UIButton) {
        coordinator?.popView()
        coordinator?.navigateToSelectAreaListView()
    }

    func filterDataReceived() {
        showActivityIndicator(false)
        incidentListCount.text = "\(viewModel.items.count) posts are listed"

        if viewModel.items.count > 0 {
            noIncidentsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }else{
            tableView.isHidden = true
            noIncidentsLabel.isHidden = false
        }
        postNotification()
    }

    func noIncidentData() {
        showActivityIndicator(false)
        tableView.isHidden = true
        noIncidentsLabel.isHidden = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        if contentHeight - scrollOffset <= screenHeight {
            // Load the next page when the user scrolls to the bottom
            paginationHandler.loadNextPage()
        }
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

    @objc func postNotification() {
        NotificationCenter.default.post(name: .incidentListDidChange, object: nil, userInfo: ["newData": viewModel.items])
    }
}

extension IncidentListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncidentListViewCell.identifier, for: indexPath) as! IncidentListViewCell

        let selectedIncident = viewModel.items[indexPath.row]

        cell.favAction = {
            let value = selectedIncident.likeCount > 0 ? false : true
            self.viewModel.favouriteIncident(incidentId: selectedIncident.id, like: value) { result in
                if result {
                    tableView.reloadData()
                }
            }
        }
        cell.shareAction = {
            self.showToast(message: "share action")
        }
        cell.setupView(selectedIncident)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.dismissView(animated: true)
        let selectedIncidentID = viewModel.items[indexPath.row].id
        coordinator?.navigateToIncidentDetail(selectedIncidentID)
    }
}

// MARK: View model delegates

extension IncidentListViewController {
    func error(message: String) {
        self.showToast(message: message)
    }
}
