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
    func tokenExpired()
}

class IncidentsViewController: UIViewController {
    @IBOutlet var mapHConstraint: NSLayoutConstraint!
    @IBOutlet var incidentContainerView: FWView!
    @IBOutlet var mapContentView: UIView!
    @IBOutlet var incidentTableView: UITableView!
    @IBOutlet var incidentsCountLabel: UILabel!
    @IBOutlet var noIncidentsLabel: UILabel!
    @IBOutlet var changeViewButton: FWRoundedButton!

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

    var isMapViewExpanded: Bool = false
    var isListViewExpanded: Bool = false

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
        setupMap()
        setupIncidentList()
        setupUI()

        NotificationCenter.default.addObserver(self, selector: #selector(selectAreaDidChange(_:)), name: .selectAreaDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showLoader()
        incidentsViewModel.getIncidentList()

        if isMapViewExpanded {
            incidentContainerView.isHidden = true
        }

        if isListViewExpanded {
            incidentContainerView.isHidden = false
        }

        mapView.frame = mapContentView.bounds // refresh the map view margins
        self.view.layoutIfNeeded()
    }

    //MARK: - View setup
    func setupUI() {
        changeViewButton.setupShadow()
        changeViewButton.isHidden = true
    }

    func setupMap() {
        mapManager = MapManager()
        mapView = mapManager.setupMapView(frame: mapContentView.bounds)
        mapView.delegate = self
        mapContentView.addSubview(mapView)
    }

    func setupIncidentList() {
        // incidentContainerView.setTopCornersRadius(radius: 20)
        incidentTableView.dataSource = self
        incidentTableView.delegate = self

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        incidentTableView.addGestureRecognizer(panGestureRecognizer)

        incidentTableView.register(IncidentListViewCell.nib(), forCellReuseIdentifier: IncidentListViewCell.identifier)
    }

    func loadIncidentList() {
        incidentsCountLabel.text = "\(incidentsViewModel.totalPages) posts are listed"
        if incidentsViewModel.items.count > 0 {
            noIncidentsLabel.isHidden = true
            incidentTableView.isHidden = false
            incidentTableView.reloadData()
        } else {
            incidentTableView.isHidden = true
            noIncidentsLabel.isHidden = false
        }
    }

    func addMapMarkers() {
        mapManager.addMarkers(mapModel: incidentsViewModel.markersList)

        // focus on first marker
        guard !incidentsViewModel.markersList.isEmpty else { return }
        let firstLocation = incidentsViewModel.markersList[0].coordinates
        let camera = GMSCameraPosition.camera(withTarget: firstLocation, zoom: 18.0)
        mapView.animate(to: camera)
    }

    // MARK: - Actions
    @IBAction func filterButtonTap(_ sender: UIButton) {
        coordinator?.navigateToSelectAreaListView()
    }

    @objc func selectAreaDidChange(_ notification: Notification) {
        showLoader()
        incidentsViewModel.currentPage = 1
        incidentsViewModel.items.removeAll()
        incidentsViewModel.getIncidentList()
    }

    @IBAction func changeViewButtonTap(_ sender: UIButton) {
        updateChangeViewButton()

        if sender.currentTitle == "View list" {
            expandList()
        } else {
            expandMap()
        }
    }

    func expandMap() {
        incidentContainerView.isHidden = true
        mapContentView.isHidden = false
        mapView.frame = view.bounds
        if mapHConstraint != nil {
            mapHConstraint.isActive = false
        }

        incidentListExpanded?(false)
        isListViewExpanded = false
        isMapViewExpanded = true
        updateChangeViewButton()
    }

    func expandList() {
        let topConstraint = incidentContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60)
        NSLayoutConstraint.activate([topConstraint])

        incidentContainerView.isHidden = false
        mapContentView.isHidden = true

        incidentListExpanded?(true)
        isListViewExpanded = true
        isMapViewExpanded = false
        updateChangeViewButton()
        incidentTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    func updateChangeViewButton() {
        if isListViewExpanded {
            changeViewButton.isHidden = false
            changeViewButton.setTitle("View map", for: .normal)
            changeViewButton.setImage(FWImage.viewMapIcon, for: .normal)
        }

        if isMapViewExpanded {
            changeViewButton.isHidden = false
            changeViewButton.setTitle("View list", for: .normal)
            changeViewButton.setImage(FWImage.menuIconRed, for: .normal)
        }
    }

    // MARK: - pan gesture

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
            isListViewExpanded = true
            updateChangeViewButton()
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

        present(activityViewController, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .selectAreaDidChange, object: nil)
    }
}

extension IncidentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        incidentsViewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncidentListViewCell.identifier, for: indexPath) as! IncidentListViewCell

        let selectedIncident = incidentsViewModel.items[indexPath.row]

        cell.favAction = { [weak self] in
            self?.showLoader()
            self?.incidentsViewModel.favouriteIncident(incidentId: selectedIncident.id, like: selectedIncident.isLiked) { result in
                self?.hideLoader()
                if result {
                    self?.incidentsViewModel.items[indexPath.row].isLiked = !selectedIncident.isLiked
                    self?.incidentTableView.reloadData()
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

extension IncidentsViewController: IncidentsViewViewDelegate, GMSMapViewDelegate {
    func tokenExpired() {
        appCoordinator?.backToParentCoordinator()
    }

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

    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let markerTitle = marker.title,
           let selectedIncidentID = incidentsViewModel.getSelectedIncidentIdFromMapTitle(title: markerTitle)
        {
            coordinator?.navigateToIncidentDetail(selectedIncidentID)
        }
    }
}
