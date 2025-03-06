//
//  FeedsListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

protocol FeedListViewDelegate: AnyObject {
    func dataReceived()
    func errorReceived(message: String)
}

class FeedsListViewController: UIViewController, FeedListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var noFeedsLabel: UILabel!
    @IBOutlet var tableView: UITableView!

    var coordinator: HomeCoordinator?
    var viewModel: FeedsListViewModel!
    var paginationHandler: PaginationHandler<FeedsListViewModel>!

    override func viewDidLoad() {
        super.viewDidLoad()
        unlockPremiumFeature()
    }

    func unlockPremiumFeature() {
        tableView.isHidden = true

        if FWUserDefaults().userRole == "basic_user" {
            activityIndicator.isHidden = true
            noFeedsLabel.isHidden = false
            noFeedsLabel.text = "Unlock this feature by subscribing to our premium plan."
        } else {
            activityIndicator.isHidden = false
            showActivityIndicator(true)

            viewModel = FeedsListViewModel()
            viewModel.getFeedList()
            viewModel.delegate = self

            paginationHandler = PaginationHandler(viewModel: viewModel)

            setupTableView()

            noFeedsLabel.text = "No Feeds found!"
            noFeedsLabel.isHidden = true
        }
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
        tableView.register(FeedItemListView.nib(), forCellReuseIdentifier: FeedItemListView.identifier)
    }

    func errorReceived(message: String) {
        showActivityIndicator(false)
        tableView.isHidden = true
        noFeedsLabel.isHidden = false
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        if contentHeight - scrollOffset <= screenHeight {
            // Load the next page when the user scrolls to the bottom
            paginationHandler.loadNextPage()
        }
    }

    fileprivate func showAlertMessage(title: String = "", _ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: title,
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Okay"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> FeedsListViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeedsViewController") as! FeedsListViewController
        return viewController
    }
}

extension FeedsListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: CityHeaderCell.identifier) as! CityHeaderCell
        headerView.setupView(title: viewModel.items[section].localityName, hideSelectAll: true)
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items[section].feedList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedItemListView.identifier, for: indexPath) as! FeedItemListView
        cell.setupView(viewModel.items[indexPath.section].feedList[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feedData = viewModel.items[indexPath.section].feedList[indexPath.row]

        if AppManager.shared.currentScannerIDListeningTO == feedData.id {
            showAlertMessage(title: "Stop Listening", "Are you sure you want to stop listening?") {
                self.stopListeningToFeed(indexPath: indexPath)
            }
        } else {
            startListeningToFeed(id: feedData.id, urlString: feedData.url, indexPath: indexPath)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func startListeningToFeed(id: String, urlString: String, indexPath: IndexPath) {
        if let url = URL(string: urlString) {
            // if audio is already playing stop & start playing new
            if let playingFeedIndex = getIndexOfPlayingFeed() {
                viewModel.items[playingFeedIndex.section].feedList[playingFeedIndex.row].isPlaying = false
            }

            viewModel.items[indexPath.section].feedList[indexPath.row].isPlaying = true
            tableView.reloadData()

            AudioManager.shared.streamAudioFromURL(url: url)
            AppManager.shared.currentScannerIDListeningTO = id

        } else {
            showAlertMessage("This feed is unavailable at this time.")
        }
    }

    func stopListeningToFeed(indexPath: IndexPath?) {
        if let indexPath {
            viewModel.items[indexPath.section].feedList[indexPath.row].isPlaying = false
        }

        AppManager.shared.currentScannerIDListeningTO = nil
        AudioManager.shared.stopStreaming()
        tableView.reloadData()
    }

    func getIndexOfPlayingFeed() -> IndexPath? {
        for sectionIndex in 0 ..< viewModel.items.count {
            let feedList = viewModel.items[sectionIndex].feedList
            if let rowIndex = feedList.firstIndex(where: { $0.isPlaying == true }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}
