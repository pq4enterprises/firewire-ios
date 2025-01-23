//
//  FeedsListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

protocol FeedListViewDelegate: AnyObject {
    func dataReceived()
}

class FeedsListViewController: UIViewController, FeedListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    var coordinator: HomeCoordinator?
    var viewModel: FeedsListViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = FeedsListViewModel()
        viewModel.getFeedList()
        viewModel.delegate = self
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showActivityIndicator(true)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(FeedItemListView.nib(), forCellReuseIdentifier: FeedItemListView.identifier)
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

    @IBAction func closeButtonTap(_ sender: Any) {
        coordinator?.navigateBackToHome()
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> FeedsListViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeedsViewController") as! FeedsListViewController
        return viewController
    }

}

extension FeedsListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.feedList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedItemListView.identifier, for: indexPath) as! FeedItemListView
        cell.setupView(viewModel.feedList[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        debugPrint(viewModel.feedList[indexPath.row].url)
    }
}
