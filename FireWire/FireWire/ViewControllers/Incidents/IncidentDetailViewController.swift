//
//  IncidentDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import GoogleMaps
import UIKit
import FirebaseAnalytics

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
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet var commentButton: UIButton!
    @IBOutlet var imageMapStackView: UIStackView!
    @IBOutlet var unitsView: FWView!
    @IBOutlet var unitsLabel: UILabel!

    var coordinator: HomeCoordinator?
    var viewModel: IncidentDetailViewModel?

    private var selectedIncidentID: String?
    private var openCommentsSection: Bool = false
    private var isLabelExpanded = false
    private var mapView: GMSMapView!

    func setSelectedIncidentID(_ id: String, _ openComments: Bool) {
        selectedIncidentID = id
        openCommentsSection = openComments
        viewModel = IncidentDetailViewModel()
        viewModel?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        FWLoaderView.shared.showLoader(on: view)

        setupUI()
        setupActions()

        NotificationCenter.default.addObserver(self, selector: #selector(newCommentAdded(_:)), name: .newCommentAdded, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .newCommentAdded, object: nil)
    }

    func setupUI() {
        incidentDesc.isUserInteractionEnabled = true
        unitsView.setCornerRadius()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_incident_details"
        ])
        
        if let selectedIncidentID {
            viewModel?.getIncidentDetail(for: selectedIncidentID)
        }
    }

    @objc func newCommentAdded(_ notification: Notification) {
        if let selectedIncidentID {
            viewModel?.getIncidentDetail(for: selectedIncidentID)
        }
    }

    func updateUI() {
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }
        incidentTitle.text = incidentDetail.field1Value ?? ""
        incidentDesc.text = incidentDetail.field2Value ?? ""

        if let formattedDate = FWDateFormatter().formatDateString(incidentDetail.createdAt) {
            incidentDateTime.text = formattedDate
        }

        incidentAddress.text = incidentDetail.address

        incidentDetail.isLiked
            ? favouriteButton.setImage(FWImage.favIconSelected, for: .normal)
            : favouriteButton.setImage(FWImage.favIcon, for: .normal)

        if mapView == nil {
            let mapManager = MapManager()
            mapView = mapManager.setupMapView(frame: incidentMapView.bounds)
            mapView.mapType = .satellite
            mapManager.addMarkers(mapModel: viewModel?.markersList ?? [])
            incidentMapView.addSubview(mapView)

            // focus on first marker
            guard let markers = viewModel?.markersList else { return }
            let firstLocation = markers[0].coordinates
            let camera = GMSCameraPosition.camera(withTarget: firstLocation, zoom: 15.0)
            mapView.animate(to: camera)
        }

        if let imageUrlString = incidentDetail.featuredImageUrl, let imageUrl = URL(string: imageUrlString) {
            incidentImageView.isHidden = false
            incidentImageView.loadImage(from: imageUrl)

            let newHeight = self.imageMapStackView.bounds.height - 140.0
            mapView.frame = CGRect(x: 0, y: 0, width: self.imageMapStackView.bounds.width, height: newHeight)
        } else {
            incidentImageView.isHidden = true
            mapView.frame = imageMapStackView.bounds
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.imageMapStackView.layoutIfNeeded()
        }

        incidentFavourites.text = "\(incidentDetail.likeCount) Likes"
        incidentComments.text = "\(incidentDetail.commentCount) \(incidentDetail.commentCount == 1 ? "Comment" : "Comments")"

        if let units = incidentDetail.respondingUnits?.compactMap({ $0 }), !units.isEmpty {
            let unitsString = "[ " + units.joined(separator: ", ") + " ]"
            unitsLabel.text = unitsString
        } else {
            unitsLabel.text = "No data found"
        }

        if openCommentsSection {
            openCommentsSection = false
            commentButton.sendActions(for: .touchUpInside)
        }
    }

    func fitMarkersToMap() {
        guard let viewModel, !viewModel.markersList.isEmpty else { return }

        var bounds = GMSCoordinateBounds()

        for item in viewModel.markersList {
            let position = CLLocationCoordinate2D(latitude: item.coordinates.latitude, longitude: item.coordinates.longitude)
            bounds = bounds.includingCoordinate(position)
        }

        // Update the camera position to fit the markers with a padding
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50.0)
        mapView.animate(with: update)
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
        showLoader()
        let value = viewModel?.incidentDetail?.isLiked == true ? true : false
        viewModel?.favouriteIncident(like: value)
    }

    @IBAction func commentButtonTap(_ sender: UIButton) {
        if let selectedIncidentID {
            coordinator?.navigateToIncidentComments(selectedIncidentID)
        }
    }

    @IBAction func shareButtonTap(_ sender: UIButton) {
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }

        let shareContent = "\(incidentDetail.field1Value ?? "") \n\(incidentDetail.address)"
        shareContentToSocialMedia(text: shareContent, url: URL(string: String.appStoreUrl))

        // let shareContent = "\(incidentDetail.field1Value ?? "") \n\(incidentDetail.address)"
        // coordinator?.navigateToShareView(shareMessage: shareContent)
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

        present(activityViewController, animated: true)
    }

    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .satellite
        case 1:
            mapView.mapType = .normal
        case 2:
            mapView.mapType = .hybrid
        default:
            mapView.mapType = .satellite
        }
    }

    @IBAction func feedButtonTap(_ sender: UIButton) {
        coordinator?.navigateToFeeds()
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
        FWLoaderView.shared.hideLoader()
        updateUI()
        viewModel?.postIncidentDetailViewCount()
    }

    func incidentFavourited(like: Bool) {
        hideLoader()
        viewModel?.incidentDetail?.isLiked = like
        like
            ? favouriteButton.setImage(FWImage.favIconSelected, for: .normal)
            : favouriteButton.setImage(FWImage.favIcon, for: .normal)

        if let currentLikeCount = viewModel?.incidentDetail?.likeCount {
            viewModel?.incidentDetail?.likeCount = max(0, currentLikeCount + (like ? 1 : -1))
        }
        incidentFavourites.text = "\(viewModel?.incidentDetail?.likeCount ?? 0) Likes"
    }

    func error(message: String) {
        showToast(message: message)
    }
}
