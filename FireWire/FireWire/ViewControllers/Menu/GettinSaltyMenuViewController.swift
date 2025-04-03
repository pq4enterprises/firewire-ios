//
//  GettinSaltyMenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/04/25.
//

import UIKit

class GettinSaltyMenuViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!

    private var menuData: [SaltyMenuData] = []
    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView.collectionViewLayout = layout

        collectionView?.register(GettinSaltyMenuCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView?.register(MenuCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.delegate = self
        collectionView.dataSource = self

        showLoader()
        getSaltyMenu()
    }

    func getSaltyMenu() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.gettinSaltyMenu,
            expect: SaltyMenuResponseModel.self,
            requestType: APIConstants.GET
        )
        { [weak self] response, _, error in
            self?.hideLoader()
            if let errorMessage = error {
                self?.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            if let apiResponse = response as? SaltyMenuResponseModel {
                self?.menuData = apiResponse.data?.data ?? []
                self?.collectionView.reloadData()
            }
        }
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> GettinSaltyMenuViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "GettinSaltyMenuViewController") as! GettinSaltyMenuViewController
        return viewController
    }
}

extension GettinSaltyMenuViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        menuData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GettinSaltyMenuCollectionViewCell
        let menuItem = menuData[indexPath.item]
        cell.titleLabel.text = menuItem.title
        if let url = URL(string: menuItem.url) {
            cell.iconImageView.loadImage(from: url)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = menuData[indexPath.item]
        coordinator?.openURL(menuItem.link)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! MenuCollectionReusableView
            headerView.imageView.image = UIImage(named: "gettin_salty_banner")
            headerView.imageView.contentMode = .scaleAspectFill
            return headerView
        }
        fatalError("Unexpected element kind")
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let minimumInteritemSpacing: CGFloat = 10

        let availableWidth = collectionView.frame.width - padding - minimumInteritemSpacing
        let widthPerItem = availableWidth / 2

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 150)
    }
}
