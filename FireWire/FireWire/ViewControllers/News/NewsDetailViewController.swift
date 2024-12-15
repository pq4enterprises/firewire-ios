//
//  NewsDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/12/24.
//

import UIKit

protocol NewsDetailViewDelegate: AnyObject {
    func dataReceived()
}

class NewsDetailViewController: UIViewController, NewsDetailViewDelegate {
    var coordinator: HomeCoordinator?
    var viewModel: NewsDetailViewModel?

    @IBOutlet weak var newsTitle: UILabel!
    @IBOutlet weak var newsDateTime: UILabel!
    @IBOutlet weak var newsImageView: FWImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func setViewModel(viewModel: NewsDetailViewModel){
        self.viewModel = viewModel
        self.viewModel?.delegate = self
    }

    func updateUI(){
        guard let newsDetail = viewModel?.newsDetail else {
            return
        }
        newsTitle.text = newsDetail.title
        if let formattedDate = FWDateFormatter().formatDateString(newsDetail.createdAt){
            newsDateTime.text = formattedDate
        }

        if let imageUrl = URL(string: newsDetail.url){
            newsImageView.loadImage(from: imageUrl)
        }
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    func dataReceived() {
        updateUI()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> NewsDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NewsDetailViewController") as! NewsDetailViewController
        return viewController
    }

}
