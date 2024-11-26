//
//  MapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.overrideUserInterfaceStyle = .dark
    }

    @IBAction func viewListTap(_ sender: UIButton) {
        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: MapListViewController())
        bottomSheet.modalPresentationStyle = .overCurrentContext
        self.present(bottomSheet, animated: true)

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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
