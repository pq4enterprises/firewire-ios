//
//  MapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import GoogleMaps
import UIKit

protocol MapViewDelegate: AnyObject {
    func dataReceived()
}

class MapViewController: UIViewController, MapViewDelegate {
    @IBOutlet var contentView: UIView!

    var coordinator: HomeCoordinator?
    var mapView: GMSMapView!
    var mapViewModel: MapViewModel!
    var mapManager: MapManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapViewModel = MapViewModel()
        mapViewModel.delegate = self
        mapViewModel.getIncidentList()

        setupUI()
    }

    func setupUI() {
        mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: contentView.bounds)
        contentView.addSubview(mapView)
    }

    func addMapMarkers(){
        mapManager.addMarkers(coordinates: mapViewModel.markersList)
        fitMarkersToMap()
    }

    func fitMarkersToMap() {
        guard !mapViewModel.markersList.isEmpty else { return }

        var bounds = GMSCoordinateBounds()

        for coordinate in mapViewModel.markersList {
            let position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            bounds = bounds.includingCoordinate(position)
        }

        // Update the camera position to fit the markers with a padding
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50.0)
        mapView.animate(with: update)
    }

    @IBAction func viewListTap(_ sender: UIButton) {
        if mapViewModel.incidentList.count > 0 {
            coordinator?.navigateToIncidentList(mapViewModel.incidentList)
        }

        /// Note: Native way to show bottom sheet, but it has customisation issue
        /// if custom bottom sheet satisfies the requirement, this code should be removed later.
        //        let mapListView = MapListViewController()
        //        let navVC = UINavigationController(rootViewController: mapListView)
        //        navVC.modalPresentationStyle = .pageSheet
        //
        //        if let sheet = navVC.sheetPresentationController {
        //            sheet.detents = [.medium(), .custom(resolver: {context in
        //                0.95 * context.maximumDetentValue
        //            })]
        //            sheet.prefersGrabberVisible = true
        //        }
        //        self.present(navVC, animated: true, completion: nil)
    }

    func dataReceived() {
        addMapMarkers()
    }
}
