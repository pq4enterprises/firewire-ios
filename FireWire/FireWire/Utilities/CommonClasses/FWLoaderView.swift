//
//  FWLoaderView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/03/25.
//
//  2026 redesign: the plain UIActivityIndicator visuals were replaced by
//  FWFlameLoaderView — a branded pulsing flame mark — while keeping the
//  existing show/hide APIs untouched.
//

import UIKit

// MARK: - Branded flame loader

/// Reusable branded loading indicator: the FireWire flame mark with a smooth
/// pulse (scale + opacity) CoreAnimation loop. Mirrors the
/// UIActivityIndicatorView API surface (`startAnimating` / `stopAnimating` /
/// `hidesWhenStopped`) so it can drop in wherever a spinner used to live.
final class FWFlameLoaderView: UIView {
    private let flameImageView: UIImageView
    private(set) var isAnimating = false
    var hidesWhenStopped = true

    private static let animationKey = "fwFlamePulse"

    init(pointSize: CGFloat = 36) {
        flameImageView = UIImageView(image: UIImage(
            systemName: "flame.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)))
        super.init(frame: .zero)

        // Brand red reads correctly on both light and dark surfaces.
        flameImageView.tintColor = FireWireTheme.red
        flameImageView.contentMode = .center
        flameImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(flameImageView)

        NSLayoutConstraint.activate([
            flameImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            flameImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        isHidden = true

        // CAAnimations are stripped when the app backgrounds — rebuild them.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reapplyAnimationIfNeeded),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startAnimating() {
        isAnimating = true
        isHidden = false
        applyPulseAnimation()
    }

    func stopAnimating() {
        isAnimating = false
        flameImageView.layer.removeAnimation(forKey: Self.animationKey)
        if hidesWhenStopped {
            isHidden = true
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Animations are removed when the view leaves the window — restore.
        reapplyAnimationIfNeeded()
    }

    @objc private func reapplyAnimationIfNeeded() {
        if window != nil, isAnimating {
            applyPulseAnimation()
        }
    }

    private func applyPulseAnimation() {
        guard flameImageView.layer.animation(forKey: Self.animationKey) == nil else { return }

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.82
        scale.toValue = 1.1

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.45
        fade.toValue = 1.0

        let pulse = CAAnimationGroup()
        pulse.animations = [scale, fade]
        pulse.duration = 0.6
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        flameImageView.layer.add(pulse, forKey: Self.animationKey)
    }
}

// MARK: - Full-screen loader

class FWLoaderView {
    static let shared = FWLoaderView()

    private var loaderView: UIView?

    func showLoader(on view: UIView) {
        // Prevent multiple loaders
        if loaderView != nil { return }

        let loader = UIView(frame: view.bounds)
        loader.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loader.backgroundColor = FireWireTheme.background

        let flameLoader = FWFlameLoaderView(pointSize: 40)
        flameLoader.frame = loader.bounds
        flameLoader.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        flameLoader.startAnimating()

        loader.addSubview(flameLoader)
        view.addSubview(loader)

        loaderView = loader
    }

    func hideLoader() {
        loaderView?.removeFromSuperview()
        loaderView = nil
    }
}
