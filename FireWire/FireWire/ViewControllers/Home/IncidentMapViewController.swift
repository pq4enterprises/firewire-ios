//
//  IncidentMapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 17/07/25.
//

import GoogleMaps
import UIKit

class IncidentMapViewController: UIViewController {
    var mapView: GMSMapView!
    var mapManager: MapManager!
    var coordinator: HomeCoordinator?
    var selectedMarker: GMSMarker?

    var markersList: [MapMarkerModel] = [] {
        didSet {
            if markersList.isEmpty {
                clearMapMarkers()
            } else {
                addMapMarkers()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
    }

    func setupMap() {
        mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        view.addSubview(mapView)
    }

    func addMapMarkers() {
        mapManager.addMarkers(mapModel: markersList)

        // focus on first marker
        guard !markersList.isEmpty else { return }
        let firstLocation = markersList[0].coordinates
        let camera = GMSCameraPosition.camera(withTarget: firstLocation, zoom: 15.0)
        mapView.animate(to: camera)
    }

    func clearMapMarkers() {
        mapManager.removeAllMapMarker()
    }
}

extension IncidentMapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let markerTitle = marker.title,
            let selectedIncidentID = getSelectedIncidentIdFromMapTitle(title: markerTitle)
        {
            coordinator?.navigateToIncidentDetail(selectedIncidentID)
        }
    }

    func getSelectedIncidentIdFromMapTitle(title: String) -> String? {
        markersList.first { $0.title.lowercased() == title.lowercased() }?.incidentId
    }
}
