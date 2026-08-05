//
//  NewsListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//  Redesigned to the 2026 design system (programmatic card cell, FireWireTheme).
//

import SwiftSoup
import UIKit

class NewsListViewCell: UITableViewCell {
    static let identifier = "NewsListViewCell"

    // MARK: Views

    private let cardView = UIView()
    private let newsTitle = UILabel()
    private let newsDateTime = UILabel()
    private let newsDescription = UILabel()
    private let imageContainer = UIView()
    private let newsImageView = FWImageView()

    var newsExternalUrl: String?

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        newsImageView.image = UIImage(named: "news_placeholder")
        newsExternalUrl = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CGColor-based borders don't auto-update with dark mode
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            cardView.layer.borderColor = FireWireTheme.hairline.cgColor
        }
    }

    // MARK: UI construction

    private func buildUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        FireWireTheme.cardStyle(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Headline
        newsTitle.font = .systemFont(ofSize: 18, weight: .bold)
        newsTitle.textColor = FireWireTheme.text
        newsTitle.numberOfLines = 0

        // Timestamp
        newsDateTime.font = FireWireTheme.monoTimestampFont()
        newsDateTime.textColor = FireWireTheme.muted

        // Excerpt
        newsDescription.font = FireWireTheme.bodyFont()
        newsDescription.textColor = FireWireTheme.muted
        newsDescription.numberOfLines = 3

        // Story image (mockup: 172pt tall, 12pt radius). FWImageView resets
        // its own corner radius on layout, so the container does the rounding.
        imageContainer.backgroundColor = FireWireTheme.surface2
        imageContainer.layer.cornerRadius = 12
        imageContainer.layer.masksToBounds = true
        imageContainer.heightAnchor.constraint(equalToConstant: 172).isActive = true

        newsImageView.contentMode = .scaleAspectFill
        newsImageView.image = UIImage(named: "news_placeholder")
        newsImageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(newsImageView)
        NSLayoutConstraint.activate([
            newsImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            newsImageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            newsImageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            newsImageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
        ])

        let cardStack = UIStackView(arrangedSubviews: [
            newsTitle, newsDateTime, newsDescription, imageContainer,
        ])
        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.setCustomSpacing(8, after: newsTitle)
        cardStack.setCustomSpacing(10, after: newsDateTime)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            cardStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
        ])
    }

    // MARK: Data binding

    func setupView(_ model: NewsItem) {
        newsTitle.text = model.title.uppercased()

        do {
            let document = try SwiftSoup.parse(model.description)

            if let imageElement = try document.select("img").first() {
                let imageSrc = try imageElement.attr("src")
                if let imageUrl = URL(string: imageSrc) {
                    newsImageView.loadImage(from: imageUrl)
                }
            }

            let description = try document.select("p").eachText()
            newsDescription.text = description.first?.uppercased()

            if let linkElement = try document.select("a").first() {
                newsExternalUrl = try linkElement.attr("href")
            }

        } catch {
            debugPrint("Error parsing HTML: \(error.localizedDescription)")
        }

        if let formattedDate = FWDateFormatter(inputDateFormat: "EEE, dd MMM yyyy HH:mm:ss Z").formatDateWithPOSIX(model.pubDate) {
            newsDateTime.text = formattedDate.uppercased()
        }
    }
}
