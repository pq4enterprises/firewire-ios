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

    var markersList: [MapMarkerModel] = [] {
        didSet {
            if markersList.isEmpty {
                clearMapMarkers()
            }else{
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

    func clearMapMarkers(){
        mapManager.removeAllMapMarker()
    }
}
