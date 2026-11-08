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
    static let ember = UIColor(rgb: 0xEA5A1F)
    static let info = UIColor(rgb: 0x2F6FE0)

    /// Feed-card level badge tint (mockup: 1st alarm amber, working fire
    /// ember, everything else — all hands, 2nd alarm+ — brand red).
    static func severityColor(forLevel level: String) -> UIColor {
        let normalized = level.uppercased()
        if normalized.contains("1ST ALARM") || normalized.contains("STILL") {
            return orange
        }
        if normalized.contains("WORKING") {
            return ember
        }
        return red
    }

    // MARK: Accent tints (icon-circle backgrounds — menu shortcut tiles)

    static let orangeTint = UIColor(
        light: UIColor(rgb: 0xFCE3C4),
        dark: FireWireTheme.orange.withAlphaComponent(0.20))
    static let infoTint = UIColor(
        light: UIColor(rgb: 0xDDEBFF),
        dark: FireWireTheme.info.withAlphaComponent(0.20))
    static let successTint = UIColor(
        light: UIColor(rgb: 0xD6F2DF),
        dark: FireWireTheme.success.withAlphaComponent(0.20))

    // MARK: Unit-category chip palette

    // NOTE: product wants these colors admin-configurable from the portal
    // eventually; until then the mapping is hardcoded here and must stay in
    // sync with the Android UnitCategory implementation. The classifier
    // itself currently lives in IncidentDetailViewController (UnitCategory).

    // Chip TEXT is never hardcoded: UnitCategory.chipText derives it from the
    // background with contrastingText(on:) so every chip reads in light and dark.

    static let unitEngineBackground = UIColor(rgb: 0x1C1C1E)
    static let unitTruckRescueBackground = FireWireTheme.red
    static let unitMarineBackground = UIColor(rgb: 0x17B26A)
    static let unitChiefBackground = UIColor(rgb: 0xF7C948)
    static let unitSOCBackground = UIColor(
        light: UIColor(rgb: 0xFCF0E4),
        dark: UIColor(rgb: 0xE0842F).withAlphaComponent(0.20))
    /// Solid swatch used in the map legend (chip background is tinted).
    static let unitSOCLegend = UIColor(rgb: 0xE0842F)

    // MARK: Contrast (WCAG 2.x) — pure helpers first, UIColor wrappers after

    /// Relative luminance of an opaque sRGB color, components 0...1. Pure.
    static func relativeLuminance(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        func lin(_ c: CGFloat) -> CGFloat { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(red) + 0.7152 * lin(green) + 0.0722 * lin(blue)
    }

    /// Relative luminance of a 0xRRGGBB value. Pure.
    static func relativeLuminance(rgb: Int) -> CGFloat {
        relativeLuminance(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255)
    }

    /// WCAG contrast ratio between two relative luminances (1...21). Pure.
    static func contrastRatio(luminance a: CGFloat, _ b: CGFloat) -> CGFloat {
        let (hi, lo) = a > b ? (a, b) : (b, a)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// True when black text contrasts at least as well as white on a
    /// background of the given luminance (same rule as the server's
    /// autoTextColor, so fallback chips match server-resolved ones). Pure.
    static func prefersBlackText(onLuminance l: CGFloat) -> Bool {
        contrastRatio(luminance: l, 0) >= contrastRatio(luminance: l, 1)
    }

    /// True when black text reads better than white on an opaque 0xRRGGBB. Pure.
    static func prefersBlackText(onRGB rgb: Int) -> Bool {
        prefersBlackText(onLuminance: relativeLuminance(rgb: rgb))
    }

    /// Black or white, whichever reads better on `background`. Dynamic colors
    /// are resolved per trait collection, so the answer is right in light and
    /// dark. A translucent background (the SOC tint) is composited over
    /// `backdrop` — the card surface — before measuring.
    static func contrastingText(on background: UIColor, over backdrop: UIColor = FireWireTheme.surface) -> UIColor {
        UIColor { traits in
            let bg = background.resolvedColor(with: traits).composited(over: backdrop.resolvedColor(with: traits))
            let (r, g, b) = bg.rgbComponents
            return prefersBlackText(onLuminance: relativeLuminance(red: r, green: g, blue: b)) ? .black : .white
        }
    }

    // MARK: Server-resolved unit colors (12.1.2+)

    /// Parses CSS hex (#RRGGBB or #RRGGBBAA). nil for anything else, so a bad
    /// value from the portal can never crash the detail screen.
    static func color(fromHex hex: String?) -> UIColor? {
        guard var h = hex?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6 || h.count == 8, let v = UInt64(h, radix: 16) else { return nil }
        let r, g, b, a: CGFloat
        if h.count == 8 {
            r = CGFloat((v >> 24) & 0xFF) / 255; g = CGFloat((v >> 16) & 0xFF) / 255
            b = CGFloat((v >> 8) & 0xFF) / 255; a = CGFloat(v & 0xFF) / 255
        } else {
            r = CGFloat((v >> 16) & 0xFF) / 255; g = CGFloat((v >> 8) & 0xFF) / 255
            b = CGFloat(v & 0xFF) / 255; a = 1
        }
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Dynamic color from a light hex and an optional dark hex (falls back to light).
    static func color(light: String?, dark: String?, fallback: UIColor) -> UIColor {
        guard let l = color(fromHex: light) else { return fallback }
        let d = color(fromHex: dark) ?? l
        return UIColor(light: l, dark: d)
    }

    /// Chip text for server-resolved colors. An explicit, valid `fg` / `fgDark`
    /// wins; anything missing or malformed gets automatic contrast against
    /// `background` (the chip's dynamic bg) instead of a gray fallback. With no
    /// dark background the dark chip is the light chip, so the light `fg` still
    /// applies there.
    static func unitText(light: String?, dark: String?, hasDarkBackground: Bool, on background: UIColor) -> UIColor {
        let l = color(fromHex: light), d = color(fromHex: dark)
        let auto = contrastingText(on: background)
        return UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                if let d { return d }
                if !hasDarkBackground, let l { return l }
            } else if let l {
                return l
            }
            return auto.resolvedColor(with: traits)
        }
    }

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

    /// sRGB components 0...1 (grayscale colors are widened). Alpha is dropped.
    var rgbComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) { return (r, g, b) }
        var w: CGFloat = 0
        if getWhite(&w, alpha: &a) { return (w, w, w) }
        return (0, 0, 0)
    }

    /// Source-over composite of a (possibly translucent) color onto an opaque backdrop.
    func composited(over backdrop: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        getRed(&r, green: &g, blue: &b, alpha: &a)
        if a >= 1 { return self }
        let (br, bg, bb) = backdrop.rgbComponents
        return UIColor(red: r * a + br * (1 - a), green: g * a + bg * (1 - a), blue: b * a + bb * (1 - a), alpha: 1)
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
