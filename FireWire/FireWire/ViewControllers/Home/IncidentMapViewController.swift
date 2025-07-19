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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.centerMapOnMarkerAboveDrawer()
        }
    }

    func clearMapMarkers() {
        mapManager.removeAllMapMarker()
    }

    func centerMapOnMarkerAboveDrawer() {
        guard let firstMarker = mapManager.markers.first else { return }
        let markerCoordinate = firstMarker.position

        let markerPoint = mapView.projection.point(for: markerCoordinate)
        let offsetY: CGFloat = UIScreen.main.bounds.height * -0.15
        let adjustedPoint = CGPoint(x: markerPoint.x, y: markerPoint.y - offsetY)
        let adjustedCoordinate = mapView.projection.coordinate(for: adjustedPoint)
        let camera = GMSCameraPosition.camera(withTarget: adjustedCoordinate, zoom: 15.0)
        mapView.animate(to: camera)
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
