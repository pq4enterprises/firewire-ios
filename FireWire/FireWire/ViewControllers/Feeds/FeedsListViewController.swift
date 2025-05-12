//
//  FeedsListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit
import FirebaseAnalytics

protocol FeedListViewDelegate: AnyObject {
    func dataReceived()
    func errorReceived(message: String)
}

class FeedsListViewController: UIViewController, FeedListViewDelegate {
    @IBOutlet var noFeedsLabel: UILabel!
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

        noFeedsLabel.isHidden = true

        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateChanged), name: AudioManager.playbackStateChangedNotification, object: nil)

    }

    @objc func playbackStateChanged() {
        let isPlaying = AudioManager.shared.isPlaying
        if let currentID = AppManager.shared.currentScannerIDListeningTO{
            updatePlayingState(forFeedID: currentID, isPlaying: isPlaying)
            tableView.reloadData()
        }
    }

    func updatePlayingState(forFeedID id: String, isPlaying: Bool) {
        if viewModel.items.count > 0 {
            for sectionIndex in 0..<viewModel.items.count {
                for rowIndex in 0..<viewModel.items[sectionIndex].feedList.count {
                    if viewModel.items[sectionIndex].feedList[rowIndex].id == id {
                        viewModel.items[sectionIndex].feedList[rowIndex].isPlaying = isPlaying
                        return
                    }
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_scanner_feeds"
        ])
        showLoader()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.register(CityHeaderCell.nib(), forCellReuseIdentifier: CityHeaderCell.identifier)
        tableView.register(FeedItemListView.nib(), forCellReuseIdentifier: FeedItemListView.identifier)
    }

    func errorReceived(message: String) {
        hideLoader()
        tableView.isHidden = true
        noFeedsLabel.isHidden = false
    }

    func dataReceived() {
        hideLoader()
        tableView.reloadData()
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

    func unlockPremiumFeatureIfValid() -> Bool {
        if FWUserDefaults().userRole == "basic_user" {
            coordinator?.navigateToSubscriptionInfo()
            return true
        }
        return false
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

        Analytics.logEvent("radio_feed_tapped", parameters: [
            "feed_title": feedData.name
        ])

        if AppManager.shared.currentScannerIDListeningTO == feedData.id {
            self.showAlert(title: "Stop Listening", message: "Are you sure you want to stop listening?", actions: [UIAlertAction(title: "Stop Listening", style: .default, handler: { action in
                self.stopListeningToFeed(indexPath: indexPath)
            })], cancel: true)
        } else {
            guard unlockPremiumFeatureIfValid() == false else { return }
            startListeningToFeed(id: feedData.id, title: feedData.name, urlString: feedData.url, indexPath: indexPath)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func startListeningToFeed(id: String, title: String, urlString: String, indexPath: IndexPath) {
        if let url = URL(string: urlString) {
            // if audio is already playing stop & start playing new
            if let playingFeedIndex = getIndexOfPlayingFeed() {
                viewModel.items[playingFeedIndex.section].feedList[playingFeedIndex.row].isPlaying = false
            }

            viewModel.items[indexPath.section].feedList[indexPath.row].isPlaying = true
            tableView.reloadData()

            AudioManager.shared.streamAudioFromURL(url: url, feedTitle: title)
            AppManager.shared.currentScannerIDListeningTO = id

        } else {
            showAlert(title: "", message: "This feed is unavailable at this time.", actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }
    }

    func stopListeningToFeed(indexPath: IndexPath?) {
        if let indexPath {
            viewModel.items[indexPath.section].feedList[indexPath.row].isPlaying = false
        }

        AppManager.shared.currentScannerIDListeningTO = nil
        AudioManager.shared.stopStreaming()
        AudioManager.shared.stopRemotePlaybackUI()
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
