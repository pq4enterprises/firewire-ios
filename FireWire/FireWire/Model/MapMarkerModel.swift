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
    let coordinates: CLLocationCoordinate2D
    let address: String
    let markerType: MarkerType
}
