//
//  MapManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import Foundation
import GoogleMaps

class MapManager {

    var mapView: GMSMapView!

    func setupMapView(frame: CGRect) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 37.7749, longitude: -122.4194, zoom: 2)
        let mapOptions = GMSMapViewOptions()
        mapOptions.camera = camera

        mapView = GMSMapView(options: mapOptions)
        mapView.frame = frame
        mapView.mapType = .normal

        //addIncidentMarkers()
        loadMapStyle()
        return mapView
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

    func addMarkers(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        for coordinate in coordinates {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            marker.icon = FWImage.mapMarker
            marker.map = mapView
        }
    }

}
