//
//  FWBottomSheetViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/11/24.
//

import UIKit

enum BottomSheetDetent {
    case medium
    case large
}

class FWBottomSheetViewController: UIViewController {
    @IBOutlet var dimmedView: UIView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewHeightConstraint: NSLayoutConstraint!

    let maxDimmedAlpha: CGFloat = 0.6

    var defaultHeight: CGFloat = 400
    let dismissibleHeight: CGFloat = 200
    let maximumContainerHeight: CGFloat = UIScreen.main.bounds.height - 150
    // keep current new height, initial is default height
    var currentContainerHeight: CGFloat = 400

    var childView = UIViewController()
    var showDimmedView: Bool = false
    var bottomSheetDetents: [BottomSheetDetent] = [.medium, .large]
    var shouldAddPanGesture: Bool = true

    func configure(
        with childViewController: UIViewController,
        showDimmedBackground: Bool = false,
        isDraggableView: Bool = true,
        bottomSheetDetents: [BottomSheetDetent]
    ) {
        childView = childViewController
        showDimmedView = showDimmedBackground
        shouldAddPanGesture = isDraggableView
        self.bottomSheetDetents = bottomSheetDetents

        childView.view.layer.cornerRadius = 10
        childView.view.layer.masksToBounds = false

        childView.view.frame = view.bounds
        containerView.addSubview(childView.view)
        childView.view.translatesAutoresizingMaskIntoConstraints = false

        // Set constraints for the child view to fill the container
        NSLayoutConstraint.activate([
            childView.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            childView.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            childView.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            childView.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        addChild(childView)
        childView.didMove(toParent: self)

        if showDimmedView {
            setupDimmedView()
        }

        if shouldAddPanGesture {
            setupPanGesture()
        }

        if bottomSheetDetents.count == 1, bottomSheetDetents.contains(.large) {
            //By default open with max container height
            animateContainerHeight(UIScreen.main.bounds.height - 150)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        //setupPanGesture()

        // tap gesture on dimmed view to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCloseAction))
        dimmedView.addGestureRecognizer(tapGesture)
    }

    @objc func handleCloseAction() {
        animateDismissView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if showDimmedView {
            animateShowDimmedView()
        }

        animatePresentContainer()
    }

    func setupDimmedView() {
        dimmedView.backgroundColor = .black
        dimmedView.alpha = maxDimmedAlpha
    }

    func setupConstraints() {
        // Update bottom constraint
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: defaultHeight)
    }

    func setupPanGesture() {
        // add pan gesture recognizer to the view controller's view (the whole screen)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gesture:)))
        // change to false to immediately listen on gesture movement
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }

    // MARK: Pan gesture handler

    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        // Drag to top will be minus value and vice versa
        print("Pan gesture y offset: \(translation.y)")

        // Get drag direction
        let isDraggingDown = translation.y > 0
        print("Dragging direction: \(isDraggingDown ? "going down" : "going up")")

        // New height is based on value of dragging plus current container height
        let newHeight = currentContainerHeight - translation.y

        // Handle based on gesture state
        switch gesture.state {
        case .changed:
            // This state will occur when user is dragging
            if newHeight < maximumContainerHeight {
                // Keep updating the height constraint
                containerViewHeightConstraint?.constant = newHeight
                // refresh layout
                view.layoutIfNeeded()
            }
        case .ended:
            // This happens when user stop drag,
            // so we will get the last height of container

            // Condition 1: If new height is below min, dismiss controller
            if newHeight < dismissibleHeight {
                animateDismissView()
            }
            else if newHeight < defaultHeight {
                // Condition 2: If new height is below default, animate back to default
                animateContainerHeight(defaultHeight)
            }
            else if newHeight < maximumContainerHeight && isDraggingDown {
                // Condition 3: If new height is below max and going down, set to default height
                animateContainerHeight(defaultHeight)
            }
            else if newHeight > defaultHeight && !isDraggingDown {
                // Condition 4: If new height is below max and going up, set to max height at top
                animateContainerHeight(maximumContainerHeight)
                //isSheetFullyExpanded()
            }
        default:
            break
        }
    }

    func animateContainerHeight(_ height: CGFloat) {
        UIView.animate(withDuration: 0.4) {
            // Update container height
            self.containerViewHeightConstraint?.constant = height
            // Call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
        // Save current height
        currentContainerHeight = height
    }

    func animatePresentContainer() {
        // Update bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = 0
            // Call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
    }

    func animateShowDimmedView() {
        dimmedView.alpha = 0
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = self.maxDimmedAlpha
        }
    }

    func animateDismissView() {
        // hide main container view by updating bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = self.defaultHeight
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }

        // hide blur view
        dimmedView.alpha = maxDimmedAlpha
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: true)
        }
    }

    /// To determine sheet is fully expanded
    //    func isSheetFullyExpanded() {
    //        delegate?.isSheetFullyExpanded(currentContainerHeight >= maximumContainerHeight)
    //    }

    static func instantiate() -> FWBottomSheetViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FWBottomSheetViewController") as! FWBottomSheetViewController
        return viewController
    }
}
