//
//  IncidentsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 09/02/25.
//

import GoogleMaps
import UIKit

protocol IncidentsViewViewDelegate: AnyObject {
    func incidentDataLoaded()
    func noIncidentData()
    func error(message: String)
}

class IncidentsViewController: UIViewController {
    @IBOutlet weak var mapHConstraint: NSLayoutConstraint!
    @IBOutlet weak var incidentContainerView: FWView!
    @IBOutlet weak var mapContentView: UIView!
    @IBOutlet weak var incidentTableView: UITableView!
    @IBOutlet weak var incidentsCountLabel: UILabel!
    
    var coordinator: HomeCoordinator?
    var appCoordinator: AppCoordinator?
    var incidentsViewModel: IncidentsViewModel!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var paginationHandler: PaginationHandler<IncidentsViewModel>!

    var mapView: GMSMapView!
    var mapManager: MapManager!

    var incidentView: IncidentListViewController!
    
    var initialMapViewHeight: CGFloat = 500
    var minMapViewHeight: CGFloat = 60

    init(viewModel: IncidentsViewModel) {
        self.incidentsViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        incidentsViewModel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        paginationHandler = PaginationHandler(viewModel: incidentsViewModel)
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        panGestureRecognizer.isEnabled = true
        incidentTableView.isScrollEnabled = false
    }

    func setupUI() {
        mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: mapContentView.bounds)
        mapContentView.addSubview(mapView)

        incidentContainerView.setTopCornersRadius(radius: 20)
        incidentTableView.dataSource = self
        incidentTableView.delegate = self

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        incidentTableView.addGestureRecognizer(panGestureRecognizer)

        incidentTableView.register(IncidentListViewCell.nib(), forCellReuseIdentifier: IncidentListViewCell.identifier)
    }

    func loadIncidentList(){
        incidentsCountLabel.text = "\(incidentsViewModel.items.count) posts are listed"
        if incidentsViewModel.items.count > 0 {
            //noIncidentsLabel.isHidden = true
            incidentTableView.isHidden = false
            incidentTableView.reloadData()
        }else{
            incidentTableView.isHidden = true
            //noIncidentsLabel.isHidden = false
        }
    }

    func addMapMarkers() {
        mapManager.addMarkers(coordinates: incidentsViewModel.markersList)

        // focus on first marker
        guard !incidentsViewModel.markersList.isEmpty else { return }
        let firstLocation = incidentsViewModel.markersList[0]
        let camera = GMSCameraPosition.camera(withTarget: firstLocation, zoom: 15.0)
        mapView.animate(to: camera)
    }

    @IBAction func filterButtonTap(_ sender: UIButton) {
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: incidentTableView)

        let newHeight = initialMapViewHeight + translation.y
        let finalHeight = max(newHeight, minMapViewHeight)

        mapHConstraint.constant = finalHeight

        if mapHConstraint.constant == minMapViewHeight {
            gesture.isEnabled = false
            incidentTableView.isScrollEnabled = true
        }

        if gesture.state == .ended || gesture.state == .cancelled {
            initialMapViewHeight = finalHeight
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        if contentHeight - scrollOffset <= screenHeight {
            // Load the next page when the user scrolls to the bottom
            paginationHandler.loadNextPage()
        }

        print("scroll view offset \(scrollOffset)")

        if scrollOffset <= 1 {
            panGestureRecognizer.isEnabled = true
            incidentTableView.isScrollEnabled = false
        }
    }
}

extension IncidentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        incidentsViewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncidentListViewCell.identifier, for: indexPath) as! IncidentListViewCell

        let selectedIncident = incidentsViewModel.items[indexPath.row]

        cell.favAction = {
            let value = selectedIncident.likeCount > 0 ? false : true
            self.incidentsViewModel.favouriteIncident(incidentId: selectedIncident.id, like: value) { result in
                if result {
                    tableView.reloadData()
                }
            }
        }
        cell.shareAction = {
            self.showToast(message: "share action")
        }
        cell.setupView(selectedIncident)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.dismissView(animated: true)
        let selectedIncidentID = incidentsViewModel.items[indexPath.row].id
        coordinator?.navigateToIncidentDetail(selectedIncidentID)
    }
}

extension IncidentsViewController: IncidentsViewViewDelegate{
    func incidentDataLoaded() {
        loadIncidentList()
        addMapMarkers()
    }

    func noIncidentData() {

    }

    func error(message: String) {
        
    }
}
