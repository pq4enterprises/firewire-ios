//
//  IncidentsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 09/02/25.
//

import GoogleMaps
import MaterialShowcase
import UIKit
import FirebaseAnalytics

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
    @IBOutlet var feedAreasButton: UIButton!

    var coordinator: HomeCoordinator?
    var appCoordinator: AppCoordinator?
    var incidentsViewModel: IncidentsViewModel!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var paginationHandler: PaginationHandler<IncidentsViewModel>!

    var mapView: GMSMapView!
    var mapManager: MapManager!

    var incidentListExpanded: ((Bool) -> Void)?

    var initialMapViewHeight: CGFloat = 400
    var minMapViewHeight: CGFloat = 50

    var isMapViewExpanded: Bool = false
    var isListViewExpanded: Bool = false

    private let footerActivityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = FWColor.red
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()

    var sequence = MaterialShowcaseSequence()

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .selectAreaDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_incident_feed"
        ])

        showLoader()

        incidentsViewModel?.validateIfAreaSelected(forType: .area) { result in
            self.hideLoader()
            if !result { self.coordinator?.navigateToSelectArea() }
        }

        incidentsViewModel.getIncidentList()

        if isMapViewExpanded {
            incidentContainerView.isHidden = true
        }

        if isListViewExpanded {
            incidentContainerView.isHidden = false
        }
    }

    func reloadIncidentsView(){
        showLoader()
        incidentsViewModel.getIncidentList()
        if isMapViewExpanded {
            incidentContainerView.isHidden = true
        }

        if isListViewExpanded {
            incidentContainerView.isHidden = false
        }
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
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapContentView.addSubview(mapView)

        // Force layout update after adding the subview
        DispatchQueue.main.async {
            self.mapView.frame = self.mapContentView.bounds
        }
    }

    func setupIncidentList() {
        incidentTableView.dataSource = self
        incidentTableView.delegate = self

        incidentTableView.showsHorizontalScrollIndicator = false
        incidentTableView.showsVerticalScrollIndicator = false

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        incidentTableView.addGestureRecognizer(panGestureRecognizer)

        incidentTableView.register(IncidentListViewCell.nib(), forCellReuseIdentifier: IncidentListViewCell.identifier)

        incidentTableView.tableFooterView = footerActivityIndicator
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
        let camera = GMSCameraPosition.camera(withTarget: firstLocation, zoom: 15.0)
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
        incidentsViewModel.markersList.removeAll()
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
        centerMapOnFirstMarker()
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

    func centerMapOnFirstMarker() {
        guard let marker = incidentsViewModel.markersList.first else { return }

        let originalPoint = mapView.projection.point(for: marker.coordinates)
        let offsetPoint = CGPoint(x: originalPoint.x, y: originalPoint.y + 300)
        let offsetCoordinate = mapView.projection.coordinate(for: offsetPoint)

        let camera = GMSCameraPosition.camera(withTarget: offsetCoordinate, zoom: 15)
        mapView.animate(to: camera)
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

    func showFooterLoader() {
        footerActivityIndicator.startAnimating()
        incidentTableView.tableFooterView?.isHidden = false
    }

    func hideFooterLoader() {
        footerActivityIndicator.stopAnimating()
        incidentTableView.tableFooterView?.isHidden = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        guard contentHeight > screenHeight else { return }

        if contentHeight - scrollOffset - screenHeight < 50 {
            // Load the next page when the user scrolls to the bottom
            paginationHandler.loadNextPage()
            showFooterLoader()
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
                    self?.incidentsViewModel.items[indexPath.row].likeCount += !selectedIncident.isLiked ? 1 : -1
                    self?.incidentTableView.reloadData()
                }
            }
        }
        cell.commentAction = {
            self.coordinator?.navigateToIncidentDetail(selectedIncident.id, openComments: true)
        }
        cell.shareAction = {
            let shareContent = "\(selectedIncident.field1Value) \n\(selectedIncident.address)"
            self.shareContentToSocialMedia(text: shareContent, url: URL(string: String.appStoreUrl))
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
        hideFooterLoader()
        hideLoader()
        loadIncidentList()
        addMapMarkers()

        if let parentVC = self.parent as? HomeViewController {
            parentVC.showTutorial()
        }
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

extension IncidentsViewController: MaterialShowcaseDelegate {
    func showTutorial() {
        if let cell = incidentTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? IncidentListViewCell {
            let titleView = cell.incidentTitle
            let showcase1 = createMaterialShowcase(
                primaryText: "Incident",
                secondaryText: "Click to view incident details",
                targetView: titleView!
            )

            let likesView = cell.favouriteButton
            let showcase2 = createMaterialShowcase(
                primaryText: "Like",
                secondaryText: "Tap to like incidents",
                targetView: likesView!
            )

            let commentsView = cell.commentButton
            let showcase3 = createMaterialShowcase(
                primaryText: "Comment",
                secondaryText: "Comment and Share photos",
                targetView: commentsView!
            )

            let shareView = cell.shareButton
            let showcase4 = createMaterialShowcase(
                primaryText: "Share",
                secondaryText: "Share incidents with friends",
                targetView: shareView!
            )

            let showcase5 = createMaterialShowcase(
                primaryText: "Feed Areas",
                secondaryText: "Select Areas to appear on your feed",
                targetView: feedAreasButton
            )

            showcase1.delegate = self
            showcase2.delegate = self
            showcase3.delegate = self
            showcase4.delegate = self
            showcase5.delegate = self

            ShowcaseManager.shared.startSequence([showcase1, showcase2, showcase3, showcase4, showcase5])
            FWUserDefaults.setBoolForKey(key: UserDefaultKeys.onBoardingSequence, value: true)
        }
    }
    
    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        ShowcaseManager.shared.markNext()
    }
}
