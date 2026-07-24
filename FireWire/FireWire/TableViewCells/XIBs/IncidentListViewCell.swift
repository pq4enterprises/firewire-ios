//
//  IncidentListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//  Redesigned to the 2026 design system (programmatic card cell, FireWireTheme).
//

import UIKit

class IncidentListViewCell: UITableViewCell {
    static let identifier = "IncidentListViewCell"

    // MARK: Views
    // `incidentTitle`, `favouriteButton`, `commentButton` and `shareButton`
    // are referenced by the onboarding showcase in the list view controllers —
    // keep their names stable.

    let incidentTitle = UILabel()
    let favouriteButton = UIButton(type: .system)
    let commentButton = UIButton(type: .system)
    let shareButton = UIButton(type: .system)

    private let cardView = UIView()
    private let levelBadge = FWPaddedLabel()
    private let incidentDateTime = UILabel()
    private let incidentImageView = FWImageView()
    private let flameIcon = UIImageView()
    private let incidentAddress = UILabel()
    private let incidentLocality = UILabel()
    private let actionsSeparator = UIView()

    var selectedIncidentId: String?

    var favAction: (() -> Void)?
    var commentAction: (() -> Void)?
    var shareAction: (() -> Void)?

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        // Badge + timestamp row
        levelBadge.font = FireWireTheme.chipFont()
        levelBadge.textColor = .white
        levelBadge.backgroundColor = FireWireTheme.red
        levelBadge.layer.cornerRadius = 8
        levelBadge.layer.masksToBounds = true
        levelBadge.insets = UIEdgeInsets(top: 6, left: 11, bottom: 6, right: 11)
        levelBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        levelBadge.setContentHuggingPriority(.required, for: .horizontal)

        incidentDateTime.font = FireWireTheme.monoTimestampFont()
        incidentDateTime.textColor = FireWireTheme.muted
        incidentDateTime.textAlignment = .right
        incidentDateTime.setContentCompressionResistancePriority(.required, for: .horizontal)

        let badgeRow = UIStackView(arrangedSubviews: [levelBadge, UIView(), incidentDateTime])
        badgeRow.axis = .horizontal
        badgeRow.alignment = .center
        badgeRow.spacing = 10

        // Title (incident description text)
        incidentTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        incidentTitle.textColor = FireWireTheme.text
        incidentTitle.numberOfLines = 0

        // Optional scene photo
        incidentImageView.contentMode = .scaleAspectFill
        incidentImageView.layer.cornerRadius = 12
        incidentImageView.layer.masksToBounds = true
        incidentImageView.backgroundColor = FireWireTheme.surface2
        incidentImageView.heightAnchor.constraint(equalToConstant: 168).isActive = true

        // Address row: flame + address / locality
        flameIcon.image = UIImage(systemName: "flame.fill")
        flameIcon.tintColor = FireWireTheme.red
        flameIcon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            flameIcon.widthAnchor.constraint(equalToConstant: 18),
            flameIcon.heightAnchor.constraint(equalToConstant: 18),
        ])

        incidentAddress.font = .systemFont(ofSize: 14, weight: .bold)
        incidentAddress.textColor = FireWireTheme.red
        incidentAddress.numberOfLines = 0

        incidentLocality.font = .systemFont(ofSize: 11.5, weight: .semibold)
        incidentLocality.textColor = FireWireTheme.muted
        incidentLocality.numberOfLines = 0

        let addressTextStack = UIStackView(arrangedSubviews: [incidentAddress, incidentLocality])
        addressTextStack.axis = .vertical
        addressTextStack.spacing = 4

        let addressRow = UIStackView(arrangedSubviews: [flameIcon, addressTextStack])
        addressRow.axis = .horizontal
        addressRow.alignment = .top
        addressRow.spacing = 8

        // Actions row
        actionsSeparator.backgroundColor = FireWireTheme.hairline
        actionsSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        favouriteButton.configuration = Self.countPillConfiguration()
        favouriteButton.addTarget(self, action: #selector(favButtonTap), for: .touchUpInside)

        commentButton.configuration = Self.countPillConfiguration()
        commentButton.addTarget(self, action: #selector(commentButtonTap), for: .touchUpInside)

        var shareConfig = UIButton.Configuration.filled()
        shareConfig.baseBackgroundColor = FireWireTheme.redTint
        shareConfig.baseForegroundColor = FireWireTheme.red
        shareConfig.cornerStyle = .fixed
        shareConfig.background.cornerRadius = 10
        shareConfig.image = UIImage(
            systemName: "square.and.arrow.up",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        shareConfig.imagePadding = 7
        shareConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        shareConfig.attributedTitle = AttributedString(
            "SHARE",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
                .kern: 0.5,
            ]))
        shareButton.configuration = shareConfig
        shareButton.addTarget(self, action: #selector(shareButtonTap), for: .touchUpInside)

        let actionsRow = UIStackView(arrangedSubviews: [favouriteButton, commentButton, UIView(), shareButton])
        actionsRow.axis = .horizontal
        actionsRow.alignment = .center
        actionsRow.spacing = 8
        for button in [favouriteButton, commentButton, shareButton] {
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        }

        let cardStack = UIStackView(arrangedSubviews: [
            badgeRow, incidentTitle, incidentImageView, addressRow, actionsSeparator, actionsRow,
        ])
        cardStack.axis = .vertical
        cardStack.spacing = 11
        cardStack.setCustomSpacing(9, after: badgeRow)
        cardStack.setCustomSpacing(9, after: actionsSeparator)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            cardStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            cardStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            cardStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
        ])
    }

    /// Shared style for the star/comment count pills.
    private static func countPillConfiguration() -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = FireWireTheme.surface2
        config.baseForegroundColor = FireWireTheme.muted
        config.cornerStyle = .fixed
        config.background.cornerRadius = 10
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        return config
    }

    private static func pillTitle(_ value: Int) -> AttributedString {
        AttributedString(
            "\(value)",
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 13, weight: .bold)]))
    }

    // MARK: Data binding

    func setupView(_ model: IncidentDataModel) {
        selectedIncidentId = model.id

        levelBadge.text = model.field1Value.uppercased()
        levelBadge.backgroundColor = FireWireTheme.severityColor(forLevel: model.field1Value)

        incidentTitle.text = model.field2Value.uppercased()

        incidentAddress.text = model.address.uppercased()

        var locality = model.field3Value
        if let subLocalityName = model.subLocality.first?.name, !subLocalityName.isEmpty {
            if !locality.isEmpty {
                locality.append(", ")
            }
            locality.append(subLocalityName)
        }
        incidentLocality.text = locality.uppercased()
        incidentLocality.isHidden = locality.isEmpty

        if let formattedDate = FWDateFormatter().formatDateString(model.createdAt) {
            incidentDateTime.text = formattedDate.uppercased()
        }

        var favConfig = favouriteButton.configuration ?? Self.countPillConfiguration()
        favConfig.image = UIImage(
            systemName: model.isLiked ? "star.fill" : "star",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        favConfig.baseForegroundColor = model.isLiked ? FireWireTheme.red : FireWireTheme.muted
        favConfig.attributedTitle = Self.pillTitle(model.likeCount)
        favouriteButton.configuration = favConfig

        var commentConfig = commentButton.configuration ?? Self.countPillConfiguration()
        commentConfig.image = UIImage(
            systemName: "bubble.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        commentConfig.attributedTitle = Self.pillTitle(model.commentCount)
        commentButton.configuration = commentConfig

        if let featureImageUrlString = model.featuredImageURL, let imageUrl = URL(string: featureImageUrlString) {
            incidentImageView.loadImage(from: imageUrl)
            incidentImageView.isHidden = false
        } else {
            incidentImageView.isHidden = true
        }
    }

    // MARK: Actions

    @objc func favButtonTap(_ sender: UIButton) {
        favAction?()
    }

    @objc func commentButtonTap(_ sender: UIButton) {
        commentAction?()
    }

    @objc func shareButtonTap(_ sender: UIButton) {
        shareAction?()
    }
}
