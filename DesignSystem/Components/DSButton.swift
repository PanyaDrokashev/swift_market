import UIKit

final class DSButton: UIButton {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    private let style: Style
    private var configuredTitle: String?

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleLabel?.adjustsFontForContentSizeCategory = true
        applyStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isEnabled: Bool {
        didSet {
            applyStyle()
        }
    }

    func setTitle(_ title: String) {
        configuredTitle = title
        applyStyle()
    }

    private func applyStyle() {
        var configuration: UIButton.Configuration

        switch style {
        case .primary:
            configuration = .filled()
            configuration.baseBackgroundColor = DS.Colors.primary
            configuration.baseForegroundColor = .white
        case .secondary:
            configuration = .tinted()
            configuration.baseBackgroundColor = DS.Colors.secondary
            configuration.baseForegroundColor = DS.Colors.primary
        case .destructive:
            configuration = .borderedTinted()
            configuration.baseForegroundColor = DS.Colors.error
            configuration.baseBackgroundColor = DS.Colors.error.withAlphaComponent(0.08)
        }

        configuration.title = configuredTitle

        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = DS.CornerRadius.button
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = DS.Typography.bodyMedium()
            return updated
        }

        if !isEnabled {
            configuration.baseBackgroundColor = configuration.baseBackgroundColor?.withAlphaComponent(0.45)
            configuration.baseForegroundColor = configuration.baseForegroundColor?.withAlphaComponent(0.6)
        }

        self.configuration = configuration
    }
}
