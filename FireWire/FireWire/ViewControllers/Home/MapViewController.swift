//
//  MapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import GoogleMaps
import UIKit

class MapViewController: UIViewController {
    @IBOutlet var contentView: UIView!

    var coordinator: HomeCoordinator?
    var mapView: GMSMapView!
    var mapViewModel: MapViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapViewModel = MapViewModel()
        // mapViewModel.getIncidentList()

        setupUI()
    }

    func setupUI() {
        let mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: contentView.bounds)

        mapManager.addMarkers(coordinates: mapViewModel.markersList)
        fitMarkersToMap()
        
        contentView.addSubview(mapView)
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
        coordinator?.navigateToIncidentList()

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
}
