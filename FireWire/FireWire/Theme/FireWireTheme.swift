//
//  FireWireTheme.swift
//  FireWire
//
//  Shared design-system foundation (2026 redesign).
//  Extracted from the incident detail redesign so every screen can share the
//  same tokens. Do not hardcode hex values in view controllers — add a token
//  here instead.
//

import UIKit

// MARK: - Design tokens

enum FireWireTheme {

    // MARK: Brand

    static let red = UIColor(rgb: 0xE5342A)
    static let darkRed = UIColor(rgb: 0xC42A20)

    // MARK: Surfaces & text (light/dark adaptive)

    static let background = UIColor(light: 0xEFEFF2, dark: 0x0D0E12)
    static let surface = UIColor(light: 0xFFFFFF, dark: 0x181A21)
    static let surface2 = UIColor(light: 0xE7E8ED, dark: 0x252833)
    static let text = UIColor(light: 0x15161B, dark: 0xF4F5F8)
    static let muted = UIColor(light: 0x6C6F78, dark: 0x9AA0AC)
    static let hairline = UIColor(
        light: UIColor(white: 0, alpha: 0.09),
        dark: UIColor(white: 1, alpha: 0.11))
    static let redTint = UIColor(
        light: UIColor(rgb: 0xFDECEA),
        dark: FireWireTheme.red.withAlphaComponent(0.20))

    // MARK: Semantic accents

    static let success = UIColor(rgb: 0x17B26A)
    static let warning = UIColor(rgb: 0xF5B93C)
    static let orange = UIColor(rgb: 0xE0842F)
    static let info = UIColor(rgb: 0x2F6FE0)

    // MARK: Unit-category chip palette

    // NOTE: product wants these colors admin-configurable from the portal
    // eventually; until then the mapping is hardcoded here and must stay in
    // sync with the Android UnitCategory implementation. The classifier
    // itself currently lives in IncidentDetailViewController (UnitCategory).

    static let unitEngineBackground = UIColor(rgb: 0x1C1C1E)
    static let unitEngineText = UIColor.white

    static let unitTruckRescueBackground = FireWireTheme.red
    static let unitTruckRescueText = UIColor.black

    static let unitMarineBackground = UIColor(rgb: 0x17B26A)
    static let unitMarineText = UIColor.black

    static let unitChiefBackground = UIColor(rgb: 0xF7C948)
    static let unitChiefText = UIColor.black

    static let unitSOCBackground = UIColor(
        light: UIColor(rgb: 0xFCF0E4),
        dark: UIColor(rgb: 0xE0842F).withAlphaComponent(0.20))
    static let unitSOCText = UIColor(light: 0xB5661F, dark: 0xF2B47C)
    /// Solid swatch used in the map legend (chip background is tinted).
    static let unitSOCLegend = UIColor(rgb: 0xE0842F)

    static let unitOtherBackground = FireWireTheme.surface2
    static let unitOtherText = FireWireTheme.muted

    // MARK: Card style

    static func cardStyle(_ view: UIView) {
        view.backgroundColor = surface
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = hairline.cgColor
    }

    // MARK: Typography (design system is all-uppercase; set text uppercased)

    /// Large screen/address title — 22pt heavy.
    static func screenTitleFont() -> UIFont {
        .systemFont(ofSize: 22, weight: .heavy)
    }

    /// Section header title — 15pt heavy.
    static func sectionTitleFont() -> UIFont {
        .systemFont(ofSize: 15, weight: .heavy)
    }

    /// Body copy — 13.5pt semibold.
    static func bodyFont() -> UIFont {
        .systemFont(ofSize: 13.5, weight: .semibold)
    }

    /// Caption / muted secondary text — 12pt semibold.
    static func captionFont() -> UIFont {
        .systemFont(ofSize: 12, weight: .semibold)
    }

    /// Badge/chip text — 12pt heavy.
    static func chipFont() -> UIFont {
        .systemFont(ofSize: 12, weight: .heavy)
    }

    /// Small chip text — 11pt heavy.
    static func chipSmallFont() -> UIFont {
        .systemFont(ofSize: 11, weight: .heavy)
    }

    /// Timestamps — monospaced 11pt semibold.
    static func monoTimestampFont() -> UIFont {
        .monospacedSystemFont(ofSize: 11, weight: .semibold)
    }
}

// MARK: - UIColor helpers

extension UIColor {
    convenience init(rgb: Int) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0)
    }

    convenience init(light: Int, dark: Int) {
        self.init(light: UIColor(rgb: light), dark: UIColor(rgb: dark))
    }

    convenience init(light: UIColor, dark: UIColor) {
        self.init { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

// MARK: - FWPaddedLabel

/// UILabel with content insets — used for badges and chips.
final class FWPaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}

/// Legacy name used by earlier screens.
typealias PaddedLabel = FWPaddedLabel
