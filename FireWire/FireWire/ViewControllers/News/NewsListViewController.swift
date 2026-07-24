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

        tableView.register(NewsListViewCell.self, forCellReuseIdentifier: NewsListViewCell.identifier)
        styleUI()
    }

    /// New design system: cards on the app background, heavy uppercase
    /// stories count on a surface header bar with hairline.
    private func styleUI() {
        view.backgroundColor = FireWireTheme.background
        tableView.backgroundColor = FireWireTheme.background
        tableView.separatorStyle = .none

        newsListCount.font = FireWireTheme.sectionTitleFont()
        newsListCount.textColor = FireWireTheme.text
        newsListCount.text = nil

        if let headerBar = newsListCount.superview {
            headerBar.backgroundColor = FireWireTheme.surface

            let hairline = UIView()
            hairline.backgroundColor = FireWireTheme.hairline
            hairline.translatesAutoresizingMaskIntoConstraints = false
            headerBar.addSubview(hairline)

            NSLayoutConstraint.activate([
                hairline.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
                hairline.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
                hairline.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
                hairline.heightAnchor.constraint(equalToConstant: 1),
            ])
        }
    }

    func dataReceived() {
        hideLoader()
        tableView.isHidden = false
        tableView.reloadData()
        newsListCount.text = "\(viewModel.newsList.count) STORIES LISTED"
    }

    func error(message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
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
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.openURL(viewModel.newsList[indexPath.row].link )
    }
}
