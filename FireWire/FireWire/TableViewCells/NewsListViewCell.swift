//
//  NewsListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class NewsListViewCell: UITableViewCell {
    static let identifier = "NewsListViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "NewsListViewCell", bundle: nil)
    }
}
