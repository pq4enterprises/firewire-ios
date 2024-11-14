//
//  MapViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class MapViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func viewListTap(_ sender: UIButton) {
        let mapListView = MapListViewController()
        let navVC = UINavigationController(rootViewController: mapListView)
        navVC.isModalInPresentation = true

        if let sheet = navVC.sheetPresentationController {
            sheet.detents = [.medium(), .custom(resolver: {context in
                0.9 * context.maximumDetentValue
            })]
            sheet.prefersGrabberVisible = true
        }
        self.present(navVC, animated: true, completion: nil)
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
