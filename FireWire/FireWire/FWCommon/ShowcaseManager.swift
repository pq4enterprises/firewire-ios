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

    private(set) var sequence: MaterialShowcaseSequence?
    private var showcases: [MaterialShowcase] = []
    private var currentIndex = 0
    private var completion: (() -> Void)?

    private var isShowing = false

    func startSequence(_ showcases: [MaterialShowcase], completion: (() -> Void)? = nil) {
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
