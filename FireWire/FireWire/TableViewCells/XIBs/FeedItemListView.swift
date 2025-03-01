//
//  FeedItemListView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 21/01/25.
//

import UIKit

class FeedItemListView: UITableViewCell {
    static let identifier = "FeedItemListView"

    static func nib() -> UINib {
        return UINib(nibName: "FeedItemListView", bundle: nil)
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var playIcon: UIImageView!
    @IBOutlet var liveLabel: UILabel!
    @IBOutlet var musicPlayImage: UIImageView!

    func setupView(_ model: FeedListData) {
        titleLabel.text = model.name
        if model.isPlaying {
            playIcon.image = FWImage.pauseIcon
            liveLabel.isHidden = false
            musicPlayImage.isHidden = false
        } else {
            playIcon.image = FWImage.playIcon
            liveLabel.isHidden = true
            musicPlayImage.isHidden = true

        }
    }
}
