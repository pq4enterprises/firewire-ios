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
}

extension NewsListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.newsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsListViewCell.identifier, for: indexPath) as! NewsListViewCell
        cell.setupView(viewModel.newsList[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        debugPrint("select row \(indexPath.row)")
        coordinator?.navigateToNewsDetail()
    }
}
