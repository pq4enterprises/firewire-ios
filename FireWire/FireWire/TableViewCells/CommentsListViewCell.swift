//
//  CommentsListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import UIKit

class CommentsListViewCell: UITableViewCell {

    static let identifier = "CommentsListViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "CommentsListViewCell", bundle: nil)
    }

    @IBOutlet weak var userImageView: FWRoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageCollectionView: UICollectionView!

    private var model: CommentsData!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageCollectionView.register(CommentsImageViewItem.nib(), forCellWithReuseIdentifier: CommentsImageViewItem.identifier)
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
    }

    func setupView(_ model: CommentsData) {
        self.model = model
        nameLabel.text = model.userID.firstName

        if model.userID.subLocality.count > 0, let locality = model.userID.subLocality[0] {
            cityLabel.text = locality.name
        }

        descriptionLabel.text = model.comment
    }

}

extension CommentsListViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.img.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentsImageViewItem.identifier, for: indexPath) as! CommentsImageViewItem

        let image = model.img[indexPath.row]
        cell.configure(with: image)

        return cell
    }
}
