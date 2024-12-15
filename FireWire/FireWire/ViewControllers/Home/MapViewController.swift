//
//  MapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit
import MapKit
import GoogleMaps

class MapViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    
    var coordinator: HomeCoordinator?
    var mapView: GMSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI(){
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapOptions = GMSMapViewOptions()
        mapOptions.camera = camera

        mapView = GMSMapView(options: mapOptions)
        mapView.frame = self.contentView.bounds
        mapView.mapType = .normal

        self.contentView.addSubview(mapView)
        loadMapStyle()
    }

    func loadMapStyle() {

        if let path = Bundle.main.path(forResource: "mapStyle", ofType: "json"){
            do{
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                if let jsonString = String(data: data, encoding: .utf8) {
                    mapView.mapStyle = try GMSMapStyle(jsonString: jsonString)
                }

            }catch{
                NSLog("Unable to load data")
            }
        }
    }

    @IBAction func viewListTap(_ sender: UIButton) {
        coordinator?.navigateToIncidentList()
        ///Note: Native way to show bottom sheet, but it has customisation issue
        ///if custom bottom sheet satisfies the requirement, this code should be removed later.
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
