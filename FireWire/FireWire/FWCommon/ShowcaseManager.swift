//
//  ShowcaseManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/05/25.
//

import MaterialShowcase
import Foundation

class ShowcaseManager {
    static let shared = ShowcaseManager()

    /// Onboarding showcase tours are DISABLED in all builds as of 2026-08-18.
    ///
    /// They target views inside table-view cells, which is fragile, and the
    /// Home sequence force-unwraps an optional showcase (`showCase2!`) that is
    /// nil whenever the segment view can't be resolved — a latent crash.
    ///
    /// Every `showTutorial()` guards on this before building any showcase, so
    /// nothing is constructed while it is false. Declared `var` rather than
    /// `let` so the guards don't trip unreachable-code warnings.
    static var toursEnabled = false

    private(set) var sequence: MaterialShowcaseSequence?
    private var showcases: [MaterialShowcase] = []
    private var currentIndex = 0
    private var completion: (() -> Void)?

    private var isShowing = false

    func startSequence(_ showcases: [MaterialShowcase], completion: (() -> Void)? = nil) {
        guard ShowcaseManager.toursEnabled else { return }
        guard !isShowing else { return }

        guard !UserDefaults.standard.bool(forKey: UserDefaultKeys.onBoardingSequence.rawValue) else {
            return
        }

        isShowing = true
        self.completion = completion
        self.showcases = showcases
        self.currentIndex = 0

        var sequence = MaterialShowcaseSequence()
        for showcase in showcases {
            sequence = sequence.temp(showcase)
        }

        self.sequence = sequence
        sequence.start()
    }

    func markNext() {
        currentIndex += 1
        if currentIndex >= showcases.count {
            // Sequence finished
            sequence = nil
            isShowing = false
            completion?()
            completion = nil
        } else {
            sequence?.showCaseWillDismis()
        }
    }
}
