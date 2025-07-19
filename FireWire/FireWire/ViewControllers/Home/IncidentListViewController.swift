//
//  IncidentListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 17/07/25.
//

import UIKit
import Pulley
import MaterialShowcase

protocol IncidentsListViewDelegate: AnyObject {
    func loadNextPage()
    func filterUpdate()
}

class IncidentListViewController: UIViewController {
    var coordinator: HomeCoordinator?
    var delegate: IncidentsListViewDelegate?

    var items: [IncidentDataModel] = [] {
        didSet {
            if items.isEmpty {
                noIncidentLabel.isHidden = false
                incidentTableView.isHidden = true
            }else{
                noIncidentLabel.isHidden = true
                incidentTableView.isHidden = false
                incidentTableView.reloadData()
                hideFooterLoader()

                if let parentVC = parent as? IncidentHomeViewController {
                    parentVC.showTutorial()
                }
            }
        }
    }

    var totalPages: Int = 0 {
        didSet {
            totalPostLabel.text = "\(totalPages) posts are listed"
        }
    }

    let viewModel = IncidentListViewModel()
    var forceRefresh: Bool = false {
        didSet {
            if forceRefresh {
                incidentTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                forceRefresh = false
            }
        }
    }

    private let footerActivityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = FWColor.red
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()

    @IBOutlet weak var totalPostLabel: UILabel!
    @IBOutlet weak var noIncidentLabel: UILabel!
    @IBOutlet weak var incidentTableView: UITableView!
    @IBOutlet var feedAreaButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self

        incidentTableView.dataSource = self
        incidentTableView.delegate = self

        incidentTableView.register(IncidentListViewCell.nib(), forCellReuseIdentifier: IncidentListViewCell.identifier)
        incidentTableView.tableFooterView = footerActivityIndicator
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.size.height

        guard contentHeight > screenHeight else { return }

        if contentHeight - scrollOffset - screenHeight < 50 {
            showFooterLoader()
            delegate?.loadNextPage()
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

    @IBAction func feedAreaTapped(_ sender: UIButton) {
        coordinator?.navigateToSelectAreaListView(self)
    }
    
}

extension IncidentListViewController: PulleyDrawerViewControllerDelegate {
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 68.0 + (pulleyViewController?.currentDisplayMode == .drawer ? bottomSafeArea : 0.0)
    }

    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let halfScreenHeight = screenHeight / 2

        let isDrawerMode = pulleyViewController?.currentDisplayMode == .drawer
        return halfScreenHeight + (isDrawerMode ? bottomSafeArea : 0.0)
    }

    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all
    }

    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        incidentTableView.isScrollEnabled = drawer.drawerPosition == .open || drawer.currentDisplayMode == .panel
    }
}


extension IncidentListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IncidentListViewCell.identifier, for: indexPath) as! IncidentListViewCell

        let selectedIncident = items[indexPath.row]

        cell.favAction = { [weak self] in
            self?.showLoader()
            self?.viewModel.favouriteIncident(incidentId: selectedIncident.id, like: selectedIncident.isLiked) { result in
                self?.hideLoader()
                if result {
                    self?.items[indexPath.row].isLiked = !selectedIncident.isLiked
                    self?.items[indexPath.row].likeCount += !selectedIncident.isLiked ? 1 : -1
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
        let selectedIncidentID = items[indexPath.row].id
        coordinator?.navigateToIncidentDetail(selectedIncidentID)
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

extension IncidentListViewController: FilterAreaDelegate {
    func filterUpdate() {
        delegate?.filterUpdate()
    }
}

extension IncidentListViewController: APIDelegate {
    func error(message: String) {
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel){_ in
            self.coordinator?.popView()
        }])
    }
}

extension IncidentListViewController: MaterialShowcaseDelegate {
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
                targetView: feedAreaButton
            )
            showcase5.primaryTextAlignment = .right
            showcase5.secondaryTextAlignment = .right

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
