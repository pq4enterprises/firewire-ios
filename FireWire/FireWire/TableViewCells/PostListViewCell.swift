//
//  PostListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class PostListViewCell: UITableViewCell {
    static let identifier = "PostListViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "PostListViewCell", bundle: nil)
    }
    
}
