//
//  MapMarkerModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/02/25.
//

import MapKit

enum MarkerType {
    case points //near by fire stations
    case incident // fire location
}

struct MapMarkerModel {
    let incidentId: String
    let coordinates: CLLocationCoordinate2D
    let title: String
    let address: String
    let markerType: MarkerType
}
