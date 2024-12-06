//
//  MapListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class PostListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var coordinator: HomeCoordinator?
    var viewModel: PostListViewModel

    init(viewModel: PostListViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(PostListViewCell.nib(), forCellReuseIdentifier: PostListViewCell.identifier)
    }

    @IBAction func filterButtonTap(_ sender: UIButton) {
        coordinator?.dismissView()
        coordinator?.navigateToSelectAreaListView()
    }
    
}

extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostListViewCell.identifier, for: indexPath) as! PostListViewCell
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        debugPrint("select row \(indexPath.row)")
        coordinator?.dismissView()
        coordinator?.navigateToPostDetail()
    }

}
