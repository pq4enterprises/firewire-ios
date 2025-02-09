//
//  IncidentDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import GoogleMaps
import UIKit

protocol IncidentDetailViewDelegate: AnyObject {
    func dataReceived()
    func incidentFavourited(like: Bool)
    func error(message: String)
}

class IncidentDetailViewController: UIViewController, IncidentDetailViewDelegate {
    @IBOutlet var incidentTitle: UILabel!
    @IBOutlet var incidentSubTitle: UILabel!
    @IBOutlet var incidentDesc: UILabel!
    @IBOutlet var incidentDateTime: UILabel!
    @IBOutlet var incidentImageView: FWImageView!
    @IBOutlet var incidentAddress: UILabel!
    @IBOutlet var incidentFavourites: UILabel!
    @IBOutlet var incidentComments: UILabel!
    @IBOutlet var incidentMapView: UIView!
    @IBOutlet var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet weak var activityVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageMapStackView: UIStackView!

    //var coordinator: IncidentsCoordinator?
    var coordinator: HomeCoordinator?
    var viewModel: IncidentDetailViewModel?

    private var selectedIncidentID: String?
    private var isLabelExpanded = false
    private var mapView: GMSMapView!

    func setSelectedIncidentID(_ id: String) {
        selectedIncidentID = id
        viewModel = IncidentDetailViewModel()
        viewModel?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    func setupUI() {
        incidentDesc.isUserInteractionEnabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selectedIncidentID {
            viewModel?.getIncidentDetail(for: selectedIncidentID)
        }
    }

    func updateUI() {
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }
        incidentTitle.text = incidentDetail.field1Value ?? ""
        incidentSubTitle.text = incidentDetail.field2Value ?? ""
        if let formattedDate = FWDateFormatter().formatDateString(incidentDetail.createdAt) {
            incidentDateTime.text = formattedDate
        }

        if let desc = incidentDetail.field3Value, desc.isEmpty {
            activityVerticalConstraint.constant = activityVerticalConstraint.constant + 20
        }

        incidentDesc.text = incidentDetail.field3Value ?? ""
        incidentAddress.text = incidentDetail.address

        incidentDetail.likeCount > 0
            ? favouriteButton.setImage(FWImage.favIconSelected, for: .normal)
            : favouriteButton.setImage(FWImage.favIcon, for: .normal)

        if let imageUrlString = incidentDetail.featuredImageUrl, let imageUrl = URL(string: imageUrlString) {
            imageLoadingIndicator.isHidden = true
            incidentImageView.loadImage(from: imageUrl)
            imageMapStackView.distribution = .fillEqually
        } else{
            imageLoadingIndicator.isHidden = true
            incidentImageView.isHidden = true
            imageMapStackView.distribution = .fill
            view.layoutIfNeeded()
        }

        let mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: incidentMapView.bounds)

        if let latitude = Double(incidentDetail.latitude), let longitude = Double(incidentDetail.longitude) {
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            mapManager.addMarkers(coordinates: [coordinates])
            mapView.animate(toLocation: coordinates)
        }

        incidentMapView.addSubview(mapView)
    }

    func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleLabel))
        incidentDesc.addGestureRecognizer(tapGesture)
    }

    @objc func toggleLabel() {
        if isLabelExpanded {
            incidentDesc.numberOfLines = 3
        } else {
            incidentDesc.numberOfLines = 0
        }
        isLabelExpanded.toggle()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    @IBAction func likeButtonTap(_ sender: UIButton) {
        let value = viewModel?.incidentDetail?.likeCount ?? 0 > 0 ? false : true
        viewModel?.favouriteIncident(like: value)
    }

    @IBAction func commentButtonTap(_ sender: UIButton) {
        if let selectedIncidentID {
            //coordinator?.navigateToIncidentComments(selectedIncidentID)
        }
    }

    @IBAction func shareButtonTap(_ sender: UIButton) {
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }

        let shareContent = "\(incidentDetail.field1Value ?? "") \n\(incidentDetail.address)"
        shareContentToSocialMedia(text: shareContent, url: URL(string: "https://apps.apple.com/us/app/nyc-fire-wire/id980572369"))

        //let shareContent = "\(incidentDetail.field1Value ?? "") \n\(incidentDetail.address)"
        //coordinator?.navigateToShareView(shareMessage: shareContent)
    }


    func shareContentToSocialMedia(text: String, image: UIImage? = nil, url: URL? = nil) {
        var items: [Any] = [text]

        if let imageToShare = image {
            items.append(imageToShare)
        }

        if let urlToShare = url {
            items.append("Checkout: \(urlToShare)")
        }

        // Create an instance of UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Exclude certain activity types if needed (optional)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact, .airDrop]

        self.present(activityViewController, animated: true)
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> IncidentDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "IncidentDetailViewController") as! IncidentDetailViewController
        return viewController
    }
}

// MARK: View model delegates

extension IncidentDetailViewController {
    func dataReceived() {
        updateUI()
    }

    func incidentFavourited(like: Bool) {
        like
            ? favouriteButton.setImage(FWImage.favIconSelected, for: .normal)
            : favouriteButton.setImage(FWImage.favIcon, for: .normal)
    }

    func error(message: String) {
        self.showToast(message: message)
    }
}
