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
    @IBOutlet weak var noIncidentsLabel: UILabel!

    var coordinator: HomeCoordinator?
    var appCoordinator: AppCoordinator?
    var incidentsViewModel: IncidentsViewModel!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var paginationHandler: PaginationHandler<IncidentsViewModel>!

    var mapView: GMSMapView!
    var mapManager: MapManager!

    var incidentView: IncidentListViewController!
    var incidentListExpanded: ((Bool) -> Void)?

    var initialMapViewHeight: CGFloat = 500
    var minMapViewHeight: CGFloat = 50


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

        NotificationCenter.default.addObserver(self, selector: #selector(selectAreaDidChange(_:)), name: .selectAreaDidChange, object: nil)

        showLoader()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// Note: Enable to pull down table view feature
        //panGestureRecognizer.isEnabled = true
        //incidentTableView.isScrollEnabled = false
    }

    @objc func selectAreaDidChange(_ notification: Notification) {
        showLoader()
        incidentsViewModel.items.removeAll()
        incidentsViewModel.getIncidentList()
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
            noIncidentsLabel.isHidden = true
            incidentTableView.isHidden = false
            incidentTableView.reloadData()
        }else{
            incidentTableView.isHidden = true
            noIncidentsLabel.isHidden = false
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
        coordinator?.navigateToSelectAreaListView()
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: incidentTableView)

        let newHeight = initialMapViewHeight + translation.y
        let finalHeight = max(newHeight, minMapViewHeight)

        if mapHConstraint.constant != finalHeight {
            mapHConstraint.constant = finalHeight
        }

        mapView.frame = view.bounds

        // When the map is at its minimum height, disable the pan gesture and allow table view scrolling
        if finalHeight == minMapViewHeight && gesture.state != .ended && gesture.state != .cancelled {
            gesture.isEnabled = false
            incidentTableView.isScrollEnabled = true
            incidentListExpanded?(true)
        }

        if gesture.state == .ended || gesture.state == .cancelled {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                self.initialMapViewHeight = finalHeight
                self.incidentTableView.isScrollEnabled = true
                self.view.layoutIfNeeded()
            }, completion: nil)
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

        /// Note: Enable to pull down table view feature
        //        if scrollOffset <= 1 {
        //            panGestureRecognizer.isEnabled = true
        //            incidentTableView.isScrollEnabled = false
        //        }
    }

    func expandMap(){
        self.incidentContainerView.isHidden = true
        self.mapContentView.isHidden = false
        if (self.mapHConstraint != nil) {
            self.mapHConstraint.isActive = false
        }
        self.incidentListExpanded?(false)
    }

    func expandList(){
        let topConstraint = incidentContainerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50)
        NSLayoutConstraint.activate([topConstraint])

        self.incidentContainerView.isHidden = false
        self.mapContentView.isHidden = true
        self.incidentListExpanded?(true)
        self.incidentTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .selectAreaDidChange, object: nil)
    }

    func shareContentToSocialMedia(text: String, image: UIImage? = nil, url: URL? = nil) {
        var items: [Any] = [text]

        if let imageToShare = image {
            items.append(imageToShare)
        }

        if let urlToShare = url {
            items.append("Checkout: \(urlToShare)")
        }

        // Create an instance of UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Exclude certain activity types if needed (optional)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact, .airDrop]

        self.present(activityViewController, animated: true)
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
            let shareContent = "\(selectedIncident.field1Value) \n\(selectedIncident.address)"
            self.shareContentToSocialMedia(text: shareContent, url: URL(string: "https://apps.apple.com/us/app/nyc-fire-wire/id980572369"))
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
        hideLoader()
        loadIncidentList()
        addMapMarkers()
    }

    func noIncidentData() {
        hideLoader()
        incidentsCountLabel.text = "\(incidentsViewModel.items.count) posts are listed"
        incidentTableView.isHidden = true
        noIncidentsLabel.isHidden = false
    }

    func error(message: String) {
        hideLoader()
    }
}
