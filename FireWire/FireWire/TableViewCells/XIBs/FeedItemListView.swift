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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playIcon: UIImageView!

    func setupView(_ model: FeedListData){
        titleLabel.text = model.name
        playIcon.image = model.isPlaying ? FWImage.pauseIcon : FWImage.playIcon
    }
}
