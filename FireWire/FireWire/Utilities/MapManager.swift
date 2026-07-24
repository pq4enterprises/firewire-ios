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
        // Default the feed map to hybrid (satellite + labels) per the 2026
        // redesign; any user-facing map-type toggle still applies on top.
        mapView.mapType = .hybrid

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
            if item.markerType == .incident {
                marker.icon = FWImage.mapMarker
            } else {
                // Firehouse / point-of-interest: "Classic Pin" — red teardrop
                // with a white firehouse glyph, composed with a design-system
                // label underneath (Google Maps can't style marker titles, so
                // the label is baked into the marker image).
                let composed = FirehouseMarker.composedIcon(
                    label: item.title,
                    traits: mapView?.traitCollection ?? .current)
                marker.icon = composed.image
                marker.groundAnchor = composed.groundAnchor
            }
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

// MARK: - Firehouse "Classic Pin" marker

/// Draws the approved "Classic Pin" firehouse marker entirely in code:
/// a FireWireTheme.red teardrop pin with a 2.5pt white border and a white
/// firehouse glyph (house silhouette whose lower half is a garage door),
/// composed into a single image with the firehouse name underneath in the
/// design-system chip typography (SF heavy, uppercase, kern 0.8) with a
/// halo stroke for map legibility.
enum FirehouseMarker {

    // MARK: Metrics (points)

    /// Head-circle radius of the teardrop.
    private static let headRadius: CGFloat = 11.5
    /// White border stroke width.
    private static let borderWidth: CGFloat = 2.5
    /// Vertical gap between the pin tip and the label.
    private static let labelGap: CGFloat = 3
    /// Extra transparent padding around the composition (keeps the halo
    /// stroke and the pin border from clipping at the bitmap edge).
    private static let padding: CGFloat = 2

    /// Pin bounding width/height (excluding label). ~26 x 33pt drawn area.
    private static var pinWidth: CGFloat { headRadius * 2 + borderWidth }
    private static var pinHeight: CGFloat { headRadius * 2.5 + borderWidth + 3 }

    // MARK: Composition

    /// Renders the pin + label into one marker image.
    /// - Returns: the image and the `groundAnchor` that places the pin tip
    ///   (not the image bottom — the label hangs below the tip) on the
    ///   marker coordinate.
    static func composedIcon(label: String, traits: UITraitCollection) -> (image: UIImage, groundAnchor: CGPoint) {
        let name = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        // Design-system label treatment: same as unit chips / action labels.
        let textColor = FireWireTheme.text.resolvedColor(with: traits)
        // Halo inverts with the text so the label reads on any map imagery:
        // white halo around dark text (light mode), dark halo around the
        // near-white dark-mode text.
        let haloColor: UIColor = traits.userInterfaceStyle == .dark
            ? UIColor(rgb: 0x15161B)
            : .white

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .heavy),
            .kern: 0.8
        ]
        let labelSize: CGSize
        if name.isEmpty {
            labelSize = .zero
        } else {
            let measured = (name as NSString).size(withAttributes: baseAttributes)
            labelSize = CGSize(width: ceil(measured.width), height: ceil(measured.height))
        }

        let imageWidth = max(pinWidth, labelSize.width) + padding * 2
        let pinTipY = padding + pinHeight
        let imageHeight = pinTipY + (name.isEmpty ? 0 : labelGap + labelSize.height) + padding

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: imageWidth, height: imageHeight))
        let image = renderer.image { context in
            let cx = imageWidth / 2
            drawPin(in: context.cgContext, centerX: cx, topY: padding)

            if !name.isEmpty {
                let labelOrigin = CGPoint(
                    x: cx - labelSize.width / 2,
                    y: pinTipY + labelGap)
                // Halo pass: stroke-only draw underneath …
                var strokeAttributes = baseAttributes
                strokeAttributes[.strokeColor] = haloColor
                strokeAttributes[.strokeWidth] = 9.0 // % of font size; subtle
                (name as NSString).draw(at: labelOrigin, withAttributes: strokeAttributes)
                // … then the fill on top.
                var fillAttributes = baseAttributes
                fillAttributes[.foregroundColor] = textColor
                (name as NSString).draw(at: labelOrigin, withAttributes: fillAttributes)
            }
        }

        // Anchor the pin tip — not the label — to the coordinate.
        let anchor = CGPoint(x: 0.5, y: pinTipY / imageHeight)
        return (image, anchor)
    }

    // MARK: Pin drawing

    private static func drawPin(in context: CGContext, centerX cx: CGFloat, topY: CGFloat) {
        let r = headRadius
        let inset = borderWidth / 2 // stroke is centered on the path
        let headCenter = CGPoint(x: cx, y: topY + inset + r)
        let tip = CGPoint(x: cx, y: topY + pinHeight - inset)

        // Teardrop: arc over the head, tapering curves down to the tip.
        // (UIKit coordinates: y down, angles clockwise from +x.)
        let startAngle: CGFloat = 150 * .pi / 180  // lower-left of head
        let endAngle: CGFloat = 30 * .pi / 180     // lower-right of head
        let start = CGPoint(
            x: headCenter.x + r * cos(startAngle),
            y: headCenter.y + r * sin(startAngle))
        let end = CGPoint(
            x: headCenter.x + r * cos(endAngle),
            y: headCenter.y + r * sin(endAngle))

        let pin = UIBezierPath()
        pin.move(to: start)
        pin.addArc(withCenter: headCenter, radius: r,
                   startAngle: startAngle, endAngle: endAngle, clockwise: true)
        pin.addQuadCurve(
            to: tip,
            controlPoint: CGPoint(x: end.x - r * 0.18, y: headCenter.y + r * 1.35))
        pin.addQuadCurve(
            to: start,
            controlPoint: CGPoint(x: start.x + r * 0.18, y: headCenter.y + r * 1.35))
        pin.close()

        FireWireTheme.red.setFill()
        pin.fill()
        UIColor.white.setStroke()
        pin.lineWidth = borderWidth
        pin.lineJoinStyle = .round
        pin.stroke()

        drawFirehouseGlyph(centeredAt: headCenter)
    }

    /// White house silhouette whose lower half is a garage door — a red
    /// cutout crossed by two thin white horizontal lines.
    private static func drawFirehouseGlyph(centeredAt c: CGPoint) {
        // Glyph box ~13 x 12pt centered in the pin head.
        let apex = CGPoint(x: c.x, y: c.y - 6)
        let eaveY = c.y - 0.8
        let eaveHalf: CGFloat = 6.4
        let wallHalf: CGFloat = 4.9
        let baseY = c.y + 6

        let house = UIBezierPath()
        house.move(to: apex)
        house.addLine(to: CGPoint(x: c.x + eaveHalf, y: eaveY))
        house.addLine(to: CGPoint(x: c.x + wallHalf, y: eaveY))
        house.addLine(to: CGPoint(x: c.x + wallHalf, y: baseY))
        house.addLine(to: CGPoint(x: c.x - wallHalf, y: baseY))
        house.addLine(to: CGPoint(x: c.x - wallHalf, y: eaveY))
        house.addLine(to: CGPoint(x: c.x - eaveHalf, y: eaveY))
        house.close()
        UIColor.white.setFill()
        house.fill()

        // Garage door: red cutout in the lower half of the body.
        let doorHalf: CGFloat = 3.3
        let doorTop = c.y + 1.2
        let door = UIBezierPath(rect: CGRect(
            x: c.x - doorHalf, y: doorTop,
            width: doorHalf * 2, height: baseY - doorTop))
        FireWireTheme.red.setFill()
        door.fill()

        // Two thin white slat lines across the door.
        UIColor.white.setFill()
        for lineY in [doorTop + 1.4, doorTop + 3.0] {
            UIBezierPath(rect: CGRect(
                x: c.x - doorHalf, y: lineY,
                width: doorHalf * 2, height: 0.6)).fill()
        }
    }
}
