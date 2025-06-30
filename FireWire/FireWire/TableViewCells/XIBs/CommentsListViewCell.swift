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

    @IBOutlet var userImageView: FWRoundedImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var dateTimeLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var imageCollectionView: UICollectionView!
    @IBOutlet var imgCollectionHeightConstraint: NSLayoutConstraint!

    private var model: CommentsData!
    var commentsAction: ((CommentsData) -> Void)?
    var imageTapHandler: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        imageCollectionView.register(CommentsImageViewItem.nib(), forCellWithReuseIdentifier: CommentsImageViewItem.identifier)
    }

    func setupView(_ model: CommentsData) {
        self.model = model

        let userName = "\(model.userID?.firstName ?? "") \(model.userID?.lastName ?? "")"
        nameLabel.text = userName

        if model.userID?.subLocality.count ?? 0 > 0, let locality = model.userID?.subLocality[0] {
            cityLabel.text = locality.name
        }

        if let profileImage = model.userID?.img, let imageUrl = URL(string: profileImage) {
            userImageView.loadImage(from: imageUrl)
        } else {
            let defaultImage = UIImage(systemName: "person.crop.circle")
            userImageView.image = defaultImage
        }

        descriptionLabel.text = model.comment

        if let commentsImage = model.img, commentsImage.count > 0 {
            for img in commentsImage {
                if img.isEmpty {
                    imgCollectionHeightConstraint.constant = 0
                    imageCollectionView.isHidden = true
                } else {
                    imgCollectionHeightConstraint.constant = 100.0
                    imageCollectionView.isHidden = false
                    imageCollectionView.dataSource = self
                    imageCollectionView.delegate = self

                    if let layout = imageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        layout.scrollDirection = .horizontal
                        layout.itemSize = CGSize(width: 80, height: 80) // Set item size
                    }
                    imageCollectionView.reloadData()
                }
            }
        } else {
            imgCollectionHeightConstraint.constant = 0
            imageCollectionView.isHidden = true
        }

        if let formattedDate = FWDateFormatter().formatDateString(model.createdAt) {
            dateTimeLabel.text = formattedDate
        }

        cityLabel.text = ""
    }

    @IBAction func commentsActionTap(_ sender: UIButton) {
        commentsAction?(model)
    }
}

extension CommentsListViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.img?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentsImageViewItem.identifier, for: indexPath) as! CommentsImageViewItem

        if let image = model.img?[indexPath.row] {
            cell.configure(with: image)

            cell.onImageTap = { [weak self] in
                self?.imageTapHandler?(image)
            }
        }

        return cell
    }
}
