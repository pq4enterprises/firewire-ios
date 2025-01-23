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
}
