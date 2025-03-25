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
    var markers = [GMSMarker]()

    func setupMapView(frame: CGRect, zoom: Float = 15.0) -> GMSMapView {
        mapView = GMSMapView()
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

    func addMarkers(mapModel: [MapMarkerModel]) {
        guard !mapModel.isEmpty else { return }

        for item in mapModel {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: item.coordinates.latitude, longitude: item.coordinates.longitude)
            marker.title = item.title
            marker.snippet = item.address
            marker.icon = item.markerType == .incident ? FWImage.mapMarker : FWImage.mapFireMarker
            marker.map = mapView
            markers.append(marker)
        }
    }

    func removeAllMapMarker(){
        for marker in markers {
            marker.map = nil
        }
        markers.removeAll()
    }

}
