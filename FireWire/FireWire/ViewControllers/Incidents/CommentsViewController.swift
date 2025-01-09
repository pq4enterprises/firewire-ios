//
//  CommentsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import UIKit

protocol CommentsListViewDelegate: AnyObject {
    func dataReceived()
    func noCommentsForIncident()
}

class CommentsViewController: UIViewController, CommentsListViewDelegate {
    @IBOutlet var commentsListCount: UILabel!
    @IBOutlet weak var noCommentsLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var viewModel: CommentsListViewModel!
    private var selectedIncidentID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setSelectedIncidentID(_ id: String) {
        selectedIncidentID = id
        viewModel = CommentsListViewModel()
        viewModel?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showActivityIndicator(true)
        if let selectedIncidentID {
            viewModel?.getCommentsList(for: selectedIncidentID)
        }
    }

    func dataReceived() {
        showActivityIndicator(false)
        tableView.isHidden = false
        commentsListCount.isHidden = false
        noCommentsLabel.isHidden = true

        commentsListCount.text = "\(viewModel.commentsList.count) Comments"
        tableView.reloadData()
    }

    func noCommentsForIncident() {
        showActivityIndicator(false)
        tableView.isHidden = true
        commentsListCount.isHidden = true
        noCommentsLabel.isHidden = false
    }

    func showActivityIndicator(_ value: Bool) {
        if value {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(CommentsListViewCell.nib(), forCellReuseIdentifier: CommentsListViewCell.identifier)
    }

    static func instantiate() -> CommentsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        return viewController
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.commentsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentsListViewCell.identifier, for: indexPath) as! CommentsListViewCell
        cell.setupView(viewModel.commentsList[indexPath.row])
        return cell
    }
}
