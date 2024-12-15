//
//  IncidentDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import GoogleMaps
import UIKit

protocol PostDetailViewDelegate: AnyObject {
    func dataReceived()
}

class IncidentDetailViewController: UIViewController, PostDetailViewDelegate {

    @IBOutlet weak var incidentTitle: UILabel!
    @IBOutlet weak var incidentSubTitle: UILabel!
    @IBOutlet weak var incidentDesc: UILabel!
    @IBOutlet weak var incidentDateTime: UILabel!
    @IBOutlet weak var incidentImageView: FWImageView!
    @IBOutlet weak var incidentAddress: UILabel!
    @IBOutlet weak var incidentFavourites: UILabel!
    @IBOutlet weak var incidentComments: UILabel!
    @IBOutlet weak var incidentMapView: UIView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!

    var coordinator: IncidentsCoordinator?
    var viewModel: IncidentDetailViewModel?

    private var isLabelExpanded = false
    private var mapView: GMSMapView!

    func setViewModel(viewModel: IncidentDetailViewModel){
        self.viewModel = viewModel
        self.viewModel?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    func setupUI() {
        incidentDesc.isUserInteractionEnabled = true
    }

    func updateUI(){
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }
        incidentTitle.text = incidentDetail.field1Value
        incidentSubTitle.text = incidentDetail.field2Value
        if let formattedDate = FWDateFormatter().formatDateString(incidentDetail.createdAt){
            incidentDateTime.text = formattedDate
        }
        incidentDesc.text = incidentDetail.field3Value
        incidentAddress.text = incidentDetail.address

        if let imageUrl = URL(string: incidentDetail.featuredImageUrl){
            imageLoadingIndicator.isHidden = true
            incidentImageView.loadImage(from: imageUrl)
        }

        let mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: incidentMapView.bounds)

        if let latitude = Double(incidentDetail.latitude), let longitude = Double(incidentDetail.longitude) {
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude:longitude)
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

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> IncidentDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "IncidentDetailViewController") as! IncidentDetailViewController
        return viewController
    }

    func dataReceived() {
        updateUI()
    }
}
