//
//  NewsListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

protocol NewsListViewDelegate: AnyObject {
    func dataReceived()
}

class NewsListViewController: UIViewController, NewsListViewDelegate {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
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

        showActivityIndicator(true)
        viewModel.getNewsList()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(NewsListViewCell.nib(), forCellReuseIdentifier: NewsListViewCell.identifier)
    }

    func dataReceived() {
        showActivityIndicator(false)
        tableView.reloadData()
        newsListCount.text = "\(viewModel.newsList.count) news are listed"
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
    
    func shareContentToSocialMedia(text: String, image: UIImage? = nil, url: URL? = nil) {
        var items: [Any] = [text]

        if let imageToShare = image {
            items.append(imageToShare)
        }

        if let urlToShare = url {
            items.append("Checkout: \(urlToShare)")
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
            self.shareContentToSocialMedia(text: shareContent, url: URL(string: "https://apps.apple.com/us/app/nyc-fire-wire/id980572369"))
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.openURL(viewModel.newsList[indexPath.row].link )
    }
}
