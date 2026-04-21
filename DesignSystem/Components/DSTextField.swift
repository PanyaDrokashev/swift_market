import UIKit

final class DSTextField: UIView {
    struct Content {
        let title: String
        let placeholder: String
        var textContentType: UITextContentType?
        var keyboardType: UIKeyboardType = .default
        var returnKeyType: UIReturnKeyType = .default
        var isSecureTextEntry: Bool = false

        init(
            title: String,
            placeholder: String,
            textContentType: UITextContentType? = nil,
            keyboardType: UIKeyboardType = .default,
            returnKeyType: UIReturnKeyType = .default,
            isSecureTextEntry: Bool = false
        ) {
            self.title = title
            self.placeholder = placeholder
            self.textContentType = textContentType
            self.keyboardType = keyboardType
            self.returnKeyType = returnKeyType
            self.isSecureTextEntry = isSecureTextEntry
        }
    }

    struct Props {
        let content: Content
        let errorMessage: String?
        let isEnabled: Bool

        init(
            content: Content,
            errorMessage: String? = nil,
            isEnabled: Bool = true
        ) {
            self.content = content
            self.errorMessage = errorMessage
            self.isEnabled = isEnabled
        }
    }

    let textField = UITextField()

    private let titleLabel = UILabel()
    private let fieldContainer = UIView()
    private let errorLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    func configure(_ props: Props) {
        titleLabel.text = props.content.title
        textField.placeholder = props.content.placeholder
        textField.textContentType = props.content.textContentType
        textField.keyboardType = props.content.keyboardType
        textField.returnKeyType = props.content.returnKeyType
        textField.isSecureTextEntry = props.content.isSecureTextEntry

        errorLabel.text = props.errorMessage
        errorLabel.isHidden = props.errorMessage == nil
        let hasError = props.errorMessage != nil
        fieldContainer.layer.borderColor = hasError ? DS.Colors.error.cgColor : DS.Colors.border.cgColor
        fieldContainer.layer.borderWidth = hasError ? 1.2 : 1

        textField.isEnabled = props.isEnabled
        alpha = props.isEnabled ? 1 : 0.7
    }

    private func configureAppearance() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = DS.Typography.caption()
        titleLabel.textColor = DS.Colors.textSecondary
        titleLabel.adjustsFontForContentSizeCategory = true

        fieldContainer.backgroundColor = DS.Colors.surface
        fieldContainer.layer.cornerRadius = DS.CornerRadius.field
        fieldContainer.layer.borderColor = DS.Colors.border.cgColor
        fieldContainer.layer.borderWidth = 1

        textField.font = DS.Typography.body()
        textField.textColor = DS.Colors.textPrimary
        textField.adjustsFontForContentSizeCategory = true
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing

        errorLabel.font = DS.Typography.footnote()
        errorLabel.textColor = DS.Colors.error
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
    }

    private func setupLayout() {
        [titleLabel, fieldContainer, errorLabel, textField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(titleLabel)
        addSubview(fieldContainer)
        fieldContainer.addSubview(textField)
        addSubview(errorLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            fieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DS.Spacing.xs),
            fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            fieldContainer.heightAnchor.constraint(equalToConstant: 48),

            textField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: DS.Spacing.s),
            textField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -DS.Spacing.s),
            textField.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            textField.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),

            errorLabel.topAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: DS.Spacing.xs),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
