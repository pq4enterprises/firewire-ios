//
//  NewsListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit
import FirebaseAnalytics

protocol NewsListViewDelegate: AnyObject {
    func dataReceived()
    func error(message: String)
}

class NewsListViewController: UIViewController, NewsListViewDelegate {
    @IBOutlet var newsListCount: UILabel!
    @IBOutlet var tableView: UITableView!

    var viewModel: NewsListViewModel
    var coordinator: HomeCoordinator?

    init(viewModel: NewsListViewModel) {
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

        showLoader()
        tableView.isHidden = true
        viewModel.getNewsList()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_news_feed"
        ])
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.register(NewsListViewCell.nib(), forCellReuseIdentifier: NewsListViewCell.identifier)
    }

    func dataReceived() {
        hideLoader()
        tableView.isHidden = false
        tableView.reloadData()
        newsListCount.text = "\(viewModel.newsList.count) news are listed"
    }

    func error(message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    func shareContentToSocialMedia(text: String, image: UIImage? = nil) {
        var items: [Any] = [text]

        if let imageToShare = image {
            items.append(imageToShare)
        }

        if let iosUrl = URL(string: String.appStoreUrl) {
            items.append("Download the app on iOS: \(iosUrl)")
        }

        if let androidUrl = URL(string: String.playStoreUrl) {
            items.append("Download the app on Android: \(androidUrl)")
        }

        // Create an instance of UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Exclude certain activity types if needed (optional)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact, .airDrop]

        self.present(activityViewController, animated: true)
    }

}

extension NewsListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.newsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsListViewCell.identifier, for: indexPath) as! NewsListViewCell
        let newsDetail = viewModel.newsList[indexPath.row]
        cell.setupView(newsDetail)
        cell.shareAction = {
            let shareContent = "\(newsDetail.title) \nFind out: \(newsDetail.link)"
            self.shareContentToSocialMedia(text: shareContent)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.openURL(viewModel.newsList[indexPath.row].link )
    }
}
