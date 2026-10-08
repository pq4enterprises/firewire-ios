//
//  FWAuthComponents.swift
//  FireWire
//
//  Shared building blocks for the auth cluster (sign in, register, reset
//  password, verify email, session expired). Everything here is built on
//  FireWireTheme tokens and mirrors Android's fw_* auth layouts so the two
//  platforms read as one design. All type goes through UIFontMetrics so
//  Dynamic Type is honoured with a sane ceiling.
//

import AuthenticationServices
import FirebaseAnalytics
import UIKit

// MARK: - Type scale

enum FWAuthFont {
    /// System font scaled with Dynamic Type, capped so layouts never explode.
    static func scaled(_ size: CGFloat, weight: UIFont.Weight, maximum: CGFloat? = nil) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base, maximumPointSize: maximum ?? size * 1.6)
    }

    static func mono(_ size: CGFloat, weight: UIFont.Weight, maximum: CGFloat? = nil) -> UIFont {
        let base = UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base, maximumPointSize: maximum ?? size * 1.5)
    }

    static var display: UIFont { scaled(30, weight: .black, maximum: 38) }
    static var screenTitle: UIFont { scaled(18, weight: .black, maximum: 24) }
    static var caption: UIFont { scaled(12, weight: .semibold, maximum: 18) }
    static var body: UIFont { scaled(13, weight: .medium, maximum: 20) }
    static var bodyStrong: UIFont { scaled(13, weight: .heavy, maximum: 20) }
    static var input: UIFont { scaled(15, weight: .semibold, maximum: 22) }
    static var button: UIFont { scaled(15, weight: .heavy, maximum: 20) }
    static var link: UIFont { scaled(12, weight: .heavy, maximum: 18) }
    static var monoCaption: UIFont { mono(11, weight: .bold, maximum: 15) }
    static var code: UIFont { mono(26, weight: .bold, maximum: 34) }
}

// MARK: - Labels

enum FWAuthLabel {
    static func make(
        _ text: String? = nil,
        font: UIFont,
        color: UIColor = FireWireTheme.text,
        alignment: NSTextAlignment = .natural,
        uppercase: Bool = false,
        kern: CGFloat = 0
    ) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setStyledText(text, uppercase: uppercase, kern: kern)
        return label
    }

    /// Field caption: EMAIL, PASSWORD… (Android TextAppearance.FireWire.Subtitle)
    static func caption(_ text: String) -> UILabel {
        make(text, font: FWAuthFont.caption, color: FireWireTheme.muted, uppercase: true, kern: 1.0)
    }

    /// Monospace divider caption: CONNECT WITH / OR / STEP 1 OF 3
    static func monoCaption(_ text: String, color: UIColor = FireWireTheme.muted, alignment: NSTextAlignment = .center) -> UILabel {
        make(text, font: FWAuthFont.monoCaption, color: color, alignment: alignment, uppercase: true, kern: 1.6)
    }

    static func body(_ text: String, color: UIColor = FireWireTheme.text, alignment: NSTextAlignment = .natural) -> UILabel {
        make(text, font: FWAuthFont.body, color: color, alignment: alignment)
    }
}

extension UILabel {
    func setStyledText(_ text: String?, uppercase: Bool = false, kern: CGFloat = 0) {
        guard let text else { self.text = nil; return }
        let value = uppercase ? text.uppercased() : text
        if kern == 0 {
            self.text = value
        } else {
            attributedText = NSAttributedString(string: value, attributes: [.kern: kern])
        }
    }

    /// "Don't have an account? REGISTER" — muted sentence with a red, heavy call to action.
    func setLinkSentence(_ sentence: String, link: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let result = NSMutableAttributedString(
            string: sentence + " ",
            attributes: [.font: FWAuthFont.body, .foregroundColor: FireWireTheme.muted, .paragraphStyle: paragraph])
        result.append(NSAttributedString(
            string: link.uppercased(),
            attributes: [.font: FWAuthFont.link, .foregroundColor: FireWireTheme.red, .kern: 0.6, .paragraphStyle: paragraph]))
        attributedText = result
    }
}

// MARK: - Text field

final class FWAuthTextField: UITextField {
    var insets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: insets) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: insets) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: insets) }
}

/// Caption + rounded input (+ optional show/hide toggle) + inline error.
final class FWAuthField: UIView {

    enum Kind {
        case email          // sign-in username
        case newEmail       // registration
        case password       // existing password
        case newPassword    // register / reset
        case givenName, familyName, phone, jobTitle
        case code           // 6-digit one-time code
        case readOnly
    }

    let captionLabel: UILabel
    let textField = FWAuthTextField()
    let errorLabel = FWAuthLabel.make(font: FWAuthFont.caption, color: FireWireTheme.darkRed)
    private var toggleButton: UIButton?
    private let kind: Kind

    var text: String { (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }

    init(caption: String, placeholder: String? = nil, kind: Kind) {
        self.kind = kind
        captionLabel = FWAuthLabel.caption(caption)
        super.init(frame: .zero)
        build(placeholder: placeholder)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func build(placeholder: String?) {
        textField.font = FWAuthFont.input
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = FireWireTheme.text
        textField.backgroundColor = FireWireTheme.surface2
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 0
        textField.tintColor = FireWireTheme.red
        textField.clearButtonMode = .never
        textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        if let placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: FireWireTheme.muted, .font: FWAuthFont.input])
        }

        switch kind {
        case .email:
            textField.keyboardType = .emailAddress
            textField.textContentType = .username
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        case .newEmail:
            textField.keyboardType = .emailAddress
            textField.textContentType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        case .password:
            textField.isSecureTextEntry = true
            textField.textContentType = .password
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            addVisibilityToggle()
        case .newPassword:
            textField.isSecureTextEntry = true
            textField.textContentType = .newPassword
            textField.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 8;")
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            addVisibilityToggle()
        case .givenName:
            textField.textContentType = .givenName
            textField.autocapitalizationType = .words
        case .familyName:
            textField.textContentType = .familyName
            textField.autocapitalizationType = .words
        case .phone:
            textField.keyboardType = .phonePad
            textField.textContentType = .telephoneNumber
        case .jobTitle:
            textField.textContentType = .jobTitle
            textField.autocapitalizationType = .words
        case .code:
            textField.keyboardType = .numberPad
            textField.textContentType = .oneTimeCode
            textField.font = FWAuthFont.code
            textField.textAlignment = .center
            textField.defaultTextAttributes.updateValue(8.0, forKey: .kern)
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        case .readOnly:
            textField.isEnabled = false
            textField.textColor = FireWireTheme.muted
        }

        errorLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [captionLabel, textField, errorLabel])
        stack.axis = .vertical
        stack.spacing = 7
        stack.setCustomSpacing(6, after: textField)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func addVisibilityToggle() {
        let button = UIButton(type: .system)
        button.tintColor = FireWireTheme.muted
        // Fixed symbol size: the icon should not grow with Dynamic Type.
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular), forImageIn: .normal)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.accessibilityLabel = "Show password"
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addAction(UIAction { [weak self] _ in self?.toggleSecureEntry() }, for: .touchUpInside)
        textField.rightView = button
        textField.rightViewMode = .always
        textField.insets.right = 48
        toggleButton = button
    }

    private func toggleSecureEntry() {
        textField.isSecureTextEntry.toggle()
        let hidden = textField.isSecureTextEntry
        toggleButton?.setImage(UIImage(systemName: hidden ? "eye.slash" : "eye"), for: .normal)
        toggleButton?.accessibilityLabel = hidden ? "Show password" : "Hide password"
        // Secure-entry toggling resets the caret; keep the text in place.
        if let existing = textField.text {
            textField.text = nil
            textField.insertText(existing)
        }
    }

    /// Inline validation message under the input; nil clears it.
    func setError(_ message: String?) {
        if let message, !message.isEmpty {
            errorLabel.text = message
            errorLabel.isHidden = false
            textField.layer.borderWidth = 1.5
            textField.layer.borderColor = FireWireTheme.red.cgColor
            textField.accessibilityHint = message
        } else {
            errorLabel.isHidden = true
            textField.layer.borderWidth = 0
            textField.accessibilityHint = nil
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection), textField.layer.borderWidth > 0 {
            textField.layer.borderColor = FireWireTheme.red.cgColor
        }
    }
}

// MARK: - Buttons

final class FWPrimaryButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = FireWireTheme.red
        config.baseForegroundColor = .white
        config.cornerStyle = .fixed
        config.background.cornerRadius = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FWAuthFont.button
            outgoing.kern = 1.2
            return outgoing
        }
        config.title = title.uppercased()
        configuration = config
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.numberOfLines = 1
        heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        configurationUpdateHandler = { button in
            button.alpha = button.isEnabled ? 1 : 0.55
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// Red, uppercase text link with a 44pt tap target (FORGOT?, RESEND CODE…).
final class FWLinkButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = FireWireTheme.red
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 4, bottom: 12, trailing: 4)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FWAuthFont.link
            outgoing.kern = 0.6
            return outgoing
        }
        config.title = title.uppercased()
        configuration = config
        titleLabel?.adjustsFontForContentSizeCategory = true
        heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        configurationUpdateHandler = { button in
            button.alpha = button.isEnabled ? 1 : 0.45
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// Google sign-in tile: logo on a surface card (matches Android's cv_google).
final class FWGoogleButton: UIButton {
    init() {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "google_logo")
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12)
        configuration = config
        backgroundColor = FireWireTheme.surface
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = FireWireTheme.hairline.cgColor
        accessibilityLabel = "Continue with Google"
        heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = FireWireTheme.hairline.cgColor
        }
    }
}

/// Hosts Apple's button, rebuilt on appearance change (black on light, white on dark).
final class FWAppleButtonHost: UIView {
    var onTap: (() -> Void)?
    private var button: ASAuthorizationAppleIDButton?

    init() {
        super.init(frame: .zero)
        heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        rebuild()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func rebuild() {
        button?.removeFromSuperview()
        let style: ASAuthorizationAppleIDButton.Style = traitCollection.userInterfaceStyle == .dark ? .white : .black
        let appleButton = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        appleButton.cornerRadius = 12
        appleButton.addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appleButton)
        NSLayoutConstraint.activate([
            appleButton.topAnchor.constraint(equalTo: topAnchor),
            appleButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            appleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            appleButton.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        button = appleButton
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            rebuild()
        }
    }
}

// MARK: - Card

/// Surface card with a vertical content stack (FireWireTheme.cardStyle + 16pt padding).
final class FWAuthCard: UIView {
    let stack = UIStackView()

    init(spacing: CGFloat = 14) {
        super.init(frame: .zero)
        FireWireTheme.cardStyle(self)
        stack.axis = .vertical
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = FireWireTheme.hairline.cgColor
        }
    }
}

// MARK: - Banner

/// Inline notice (error / info / success). Replaces every dead-end alert on the auth screens.
final class FWBanner: UIView {
    enum Style { case error, info, success }

    private let iconView = UIImageView()
    private let label = FWAuthLabel.make(font: FWAuthFont.body)
    private var style: Style = .info

    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        label.font = FWAuthFont.scaled(13, weight: .semibold, maximum: 20)

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
        isHidden = true
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(_ message: String, style: Style) {
        self.style = style
        label.text = message
        accessibilityLabel = message
        applyStyle()
        isHidden = false
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func hide() { isHidden = true }

    private func applyStyle() {
        switch style {
        case .error:
            backgroundColor = FireWireTheme.redTint
            layer.borderColor = FireWireTheme.red.withAlphaComponent(0.25).cgColor
            label.textColor = UIColor(light: FireWireTheme.darkRed, dark: UIColor(rgb: 0xFF8A80))
            iconView.tintColor = label.textColor
            iconView.image = UIImage(systemName: "exclamationmark.circle")
        case .info:
            backgroundColor = FireWireTheme.surface2
            layer.borderColor = UIColor.clear.cgColor
            label.textColor = FireWireTheme.text
            iconView.tintColor = FireWireTheme.muted
            iconView.image = UIImage(systemName: "info.circle")
        case .success:
            backgroundColor = FireWireTheme.successTint
            layer.borderColor = UIColor.clear.cgColor
            label.textColor = UIColor(light: UIColor(rgb: 0x0E7A47), dark: UIColor(rgb: 0x6EDC9F))
            iconView.tintColor = label.textColor
            iconView.image = UIImage(systemName: "checkmark.circle")
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyStyle()
        }
    }
}

// MARK: - Top bar

/// Back chevron + centred uppercase title, like Android's toolbar_secondary_layout.
final class FWAuthTopBar: UIView {
    var onBack: (() -> Void)?
    private let hairline = UIView()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = FireWireTheme.surface

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)), for: .normal)
        back.tintColor = FireWireTheme.text
        back.accessibilityLabel = "Back"
        back.addAction(UIAction { [weak self] _ in self?.onBack?() }, for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = FWAuthLabel.make(title, font: FWAuthFont.screenTitle, alignment: .center, uppercase: true, kern: 0.9)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(back)
        addSubview(hairline)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),
            back.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            back.centerYAnchor.constraint(equalTo: centerYAnchor),
            back.widthAnchor.constraint(equalToConstant: 48),
            back.heightAnchor.constraint(equalToConstant: 48),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 56),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -56),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

// MARK: - Hero

/// Sign-in hero: map photo under a dark scrim, brand mark, GET STARTED, subtitle.
/// Switches to a compact side-by-side layout on short screens (iPhone SE).
final class FWAuthHeroView: UIView {
    private let logoView = UIImageView(image: UIImage(named: "login_logo"))
    private let titleLabel = FWAuthLabel.make("Get Started", font: FWAuthFont.display, color: .white, alignment: .center, uppercase: true, kern: 3)
    private let subtitleLabel = FWAuthLabel.make("Welcome to the Fire Wire App. Please sign in or register below.", font: FWAuthFont.body, color: UIColor(rgb: 0xC8CDD6), alignment: .center)
    private let stack = UIStackView()
    private var logoWidth: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = UIColor(rgb: 0x15161B)

        let background = UIImageView(image: UIImage(named: "login_bg"))
        background.contentMode = .scaleAspectFill
        background.translatesAutoresizingMaskIntoConstraints = false
        let scrim = UIView()
        scrim.backgroundColor = UIColor(light: UIColor.black.withAlphaComponent(0.66), dark: UIColor.black.withAlphaComponent(0.72))
        scrim.translatesAutoresizingMaskIntoConstraints = false

        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoWidth = logoView.widthAnchor.constraint(equalToConstant: 66)
        logoWidth.isActive = true
        logoView.heightAnchor.constraint(equalTo: logoView.widthAnchor, multiplier: 142.0 / 132.0).isActive = true

        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.6

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .center

        stack.addArrangedSubview(logoView)
        stack.addArrangedSubview(textStack)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(background)
        addSubview(scrim)
        addSubview(stack)
        heightConstraint = heightAnchor.constraint(equalToConstant: 236)
        NSLayoutConstraint.activate([
            heightConstraint,
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrim.topAnchor.constraint(equalTo: topAnchor),
            scrim.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrim.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            stack.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: 8),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Compact on short screens / very large text so the form still fits; on tall
    /// phones the panel grows with the screen (about a quarter of its height).
    func setCompact(_ compact: Bool, safeTop: CGFloat, screenHeight: CGFloat = 0) {
        stack.axis = compact ? .horizontal : .vertical
        stack.spacing = compact ? 14 : 12
        logoWidth.constant = compact ? 44 : 66
        subtitleLabel.text = compact ? "Sign in or register below." : "Welcome to the Fire Wire App. Please sign in or register below."
        subtitleLabel.textAlignment = compact ? .natural : .center
        titleLabel.textAlignment = compact ? .natural : .center
        (stack.arrangedSubviews.last as? UIStackView)?.alignment = compact ? .leading : .center
        let regular = min(240, max(182, screenHeight * 0.24))
        heightConstraint.constant = (compact ? 112 : regular) + safeTop
    }
}

// MARK: - Base controller

/// Scrollable auth screen: safe-area aware, keyboard-avoiding, logs screen_view,
/// dismisses the keyboard on tap. Subclasses fill `content` (a vertical stack).
class FWAuthScreenController: UIViewController {
    /// Firebase screen name — uses Android's names so both platforms report alike.
    var analyticsScreenName: String? { nil }

    let scrollView = UIScrollView()
    let content = UIStackView()
    private(set) var topBar: FWAuthTopBar?
    private(set) var footer: UIView?
    private var scrollTopConstraint: NSLayoutConstraint!
    private var scrollBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FireWireTheme.background
        buildScaffold()
        hideKeyboardWhenTappedAround()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let analyticsScreenName {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: analyticsScreenName
            ])
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func buildScaffold() {
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        content.axis = .vertical
        content.spacing = 0
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        scrollTopConstraint = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
        scrollBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            scrollTopConstraint,
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollBottomConstraint,
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    /// Adds the back/title bar above the scroll view (sub-screens only).
    func installTopBar(title: String, onBack: @escaping () -> Void) {
        let bar = FWAuthTopBar(title: title)
        bar.onBack = onBack
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        // Paint the status-bar area in the bar colour too.
        let statusFill = UIView()
        statusFill.backgroundColor = FireWireTheme.surface
        statusFill.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(statusFill, belowSubview: bar)
        NSLayoutConstraint.activate([
            statusFill.topAnchor.constraint(equalTo: view.topAnchor),
            statusFill.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusFill.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusFill.bottomAnchor.constraint(equalTo: bar.topAnchor),
        ])
        scrollTopConstraint.isActive = false
        scrollTopConstraint = scrollView.topAnchor.constraint(equalTo: bar.bottomAnchor)
        scrollTopConstraint.isActive = true
        topBar = bar
    }

    /// Pins a surface footer (hairline on top) under the scroll view (register's sign-up bar).
    func installFooter(_ footerContent: UIView) {
        let bar = UIView()
        bar.backgroundColor = FireWireTheme.surface
        bar.translatesAutoresizingMaskIntoConstraints = false
        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        footerContent.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(hairline)
        bar.addSubview(footerContent)
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hairline.topAnchor.constraint(equalTo: bar.topAnchor),
            hairline.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
            footerContent.topAnchor.constraint(equalTo: bar.topAnchor, constant: 12),
            footerContent.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 16),
            footerContent.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
            footerContent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
        scrollBottomConstraint.isActive = false
        scrollBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: bar.topAnchor)
        scrollBottomConstraint.isActive = true
        footer = bar
    }

    // MARK: Keyboard

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardInView = view.convert(frame, from: nil)
        let scrollFrame = scrollView.frame
        var bottomInset = max(0, scrollFrame.maxY - keyboardInView.minY) + 12
        // Lift the pinned footer above the keyboard as well; it then covers the
        // bottom of the scroll view, so the inset has to clear it too.
        if let footer {
            let footerOverlap = max(0, footer.frame.maxY - keyboardInView.minY)
            footer.transform = CGAffineTransform(translationX: 0, y: -footerOverlap)
            if footerOverlap > 0 { bottomInset += footer.frame.height }
        }
        var inset = scrollView.contentInset
        inset.bottom = bottomInset
        scrollView.contentInset = inset
        scrollView.verticalScrollIndicatorInsets = inset
        scrollFirstResponderIntoView()
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        var inset = scrollView.contentInset
        inset.bottom = 0
        scrollView.contentInset = inset
        scrollView.verticalScrollIndicatorInsets = inset
        footer?.transform = .identity
    }

    func scrollFirstResponderIntoView() {
        guard let responder = view.firstResponderView else { return }
        let rect = responder.convert(responder.bounds, to: scrollView).insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

extension UIView {
    var firstResponderView: UIView? {
        if isFirstResponder { return self }
        for sub in subviews {
            if let found = sub.firstResponderView { return found }
        }
        return nil
    }
}

// MARK: - Validation helpers

enum FWAuthValidation {
    static func emailError(_ email: String) -> String? {
        if email.isEmpty { return "Enter your email address." }
        if !email.isValidEmail() { return "Enter a valid email address." }
        return nil
    }

    static func passwordError(_ password: String, minimum: Int = 8) -> String? {
        if password.isEmpty { return "Enter your password." }
        if password.count < minimum { return "Password must be at least \(minimum) characters." }
        return nil
    }

    /// Server message that means the network, not the user, failed.
    static func isNetworkError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("internet") || lower.contains("network") || lower.contains("offline") || lower.contains("timed out") || lower.contains("connection")
    }

    static func friendly(_ message: String) -> String {
        isNetworkError(message) ? "No connection. Check your network and try again." : message
    }
}
