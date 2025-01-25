//
//  FeedsListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

protocol FeedListViewDelegate: AnyObject {
    func dataReceived()
    func errorPlayingAudio()
}

class FeedsListViewController: UIViewController, FeedListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    var coordinator: HomeCoordinator?
    var viewModel: FeedsListViewModel!
    var paginationHandler: PaginationHandler<FeedsListViewModel>!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = FeedsListViewModel()
        viewModel.getFeedList()
        viewModel.delegate = self
        
        paginationHandler = PaginationHandler(viewModel: viewModel)

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

    func errorPlayingAudio() {
        showAlert(
            title: "",
            message: "Unable to play the audio!",
            alertStyle: .alert,
            actionTitles: ["Ok"],
            actionStyles: [.default],
            actions: [{ _ in }]
        )
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        if contentHeight - scrollOffset <= screenHeight {
            // Load the next page when the user scrolls to the bottom
            paginationHandler.loadNextPage()
        }
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
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedItemListView.identifier, for: indexPath) as! FeedItemListView
        cell.setupView(viewModel.items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let urlString = viewModel.items[indexPath.row].url
        viewModel.playAudio(urlString, index: indexPath)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if viewModel.currentIndex == indexPath {
            viewModel.stopAudio()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}
