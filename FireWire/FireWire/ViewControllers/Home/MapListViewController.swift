//
//  MapListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class MapListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var coordinator: HomeCoordinator?

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
        coordinator?.navigateToFilterListView()
    }
    
}

extension MapListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostListViewCell.identifier, for: indexPath) as! PostListViewCell
        return cell
    }

}
