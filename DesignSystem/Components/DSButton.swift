import UIKit

final class DSButton: UIButton {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    struct Props {
        let title: String
        let style: Style
        let isEnabled: Bool

        init(
            title: String,
            style: Style,
            isEnabled: Bool = true
        ) {
            self.title = title
            self.style = style
            self.isEnabled = isEnabled
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ props: Props) {
        var configuration: UIButton.Configuration

        switch props.style {
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

        configuration.title = props.title

        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = DS.CornerRadius.button
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = DS.Typography.bodyMedium()
            return updated
        }

        if !props.isEnabled {
            configuration.baseBackgroundColor = configuration.baseBackgroundColor?.withAlphaComponent(0.45)
            configuration.baseForegroundColor = configuration.baseForegroundColor?.withAlphaComponent(0.6)
        }

        super.isEnabled = props.isEnabled
        self.configuration = configuration
    }
}
