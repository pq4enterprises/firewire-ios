//
//  NewsListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import SwiftSoup
import UIKit

class NewsListViewCell: UITableViewCell {
    static let identifier = "NewsListViewCell"

    @IBOutlet var newsTitle: UILabel!
    @IBOutlet var newsDateTime: UILabel!
    @IBOutlet var newsDescription: UILabel!
    @IBOutlet var newsImageView: FWImageView!

    var newsExternalUrl: String?

    static func nib() -> UINib {
        return UINib(nibName: "NewsListViewCell", bundle: nil)
    }

    func setupView(_ model: NewsItem) {
        newsTitle.text = model.title

        do {
            let document = try SwiftSoup.parse(model.description)

            if let imageElement = try document.select("img").first() {
                let imageSrc = try imageElement.attr("src")
                if let imageUrl = URL(string: imageSrc) {
                    newsImageView.loadImage(from: imageUrl)
                }
            }

            let description = try document.select("p").eachText()
            newsDescription.text = description[0]

            if let linkElement = try document.select("a").first() {
                newsExternalUrl = try linkElement.attr("href")
            }

        } catch {
            debugPrint("Error parsing HTML: \(error.localizedDescription)")
        }

        if let formattedDate = FWDateFormatter(inputDateFormat: "EEE, dd MMM yyyy HH:mm:ss Z").formatDateString(model.pubDate) {
            newsDateTime.text = formattedDate
        }
    }
}
