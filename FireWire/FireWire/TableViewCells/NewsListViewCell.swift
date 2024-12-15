//
//  NewsListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class NewsListViewCell: UITableViewCell {
    static let identifier = "NewsListViewCell"

    @IBOutlet var newsTitle: UILabel!
    @IBOutlet var newsDateTime: UILabel!
    @IBOutlet var newsDescription: UILabel!
    @IBOutlet var newsImageView: FWImageView!

    static func nib() -> UINib {
        return UINib(nibName: "NewsListViewCell", bundle: nil)
    }

    func setupView(_ model: NewsDataModel) {
        newsTitle.text = model.title

        if let formattedDate = FWDateFormatter().formatDateString(model.createdAt) {
            newsDateTime.text = formattedDate
        }

        if let imageUrl = URL(string: model.link) {
            newsImageView.loadImage(from: imageUrl)
        }
    }
}
