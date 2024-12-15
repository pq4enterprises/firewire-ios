//
//  MapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import GoogleMaps
import MapKit
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
        let camera = GMSCameraPosition.camera(withLatitude: 37.7749, longitude: -122.4194, zoom: 10.0)
        let mapOptions = GMSMapViewOptions()
        mapOptions.camera = camera

        mapView = GMSMapView(options: mapOptions)
        mapView.frame = contentView.bounds
        mapView.mapType = .normal

        addIncidentMarkers()
        loadMapStyle()
        contentView.addSubview(mapView)
    }

    func addIncidentMarkers() {
        guard !mapViewModel.markersList.isEmpty else { return }

        for coordinate in mapViewModel.markersList {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            marker.icon = FWImage.mapMarker
            marker.map = mapView
        }

        // Once markers are added, fit them to the map
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

    func loadMapStyle() {
        if let path = Bundle.main.path(forResource: "mapStyle", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                if let jsonString = String(data: data, encoding: .utf8) {
                    do {
                        mapView.mapStyle = try GMSMapStyle(jsonString: jsonString)
                    } catch {
                        NSLog("Unable to load map style")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    NSLog("Unable to load map style data")
                }
            }
        }
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
