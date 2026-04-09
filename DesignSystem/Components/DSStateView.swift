import UIKit

final class DSStateView: UIView {
    enum State: Equatable {
        case hidden
        case loading(message: String)
        case empty(message: String)
        case error(message: String, retryTitle: String)
    }

    var onRetry: (() -> Void)?

    private let containerView = UIView()
    private let stackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let retryButton = DSButton(style: .secondary)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ state: State, hidesWhenContentExists: Bool = false) {
        switch state {
        case .hidden:
            isHidden = true
            retryButton.isHidden = true
            activityIndicator.stopAnimating()
        case .loading(let message):
            isHidden = hidesWhenContentExists
            messageLabel.text = message
            retryButton.isHidden = true
            activityIndicator.startAnimating()
        case .empty(let message):
            isHidden = false
            messageLabel.text = message
            retryButton.isHidden = true
            activityIndicator.stopAnimating()
        case .error(let message, let retryTitle):
            isHidden = hidesWhenContentExists
            messageLabel.text = message
            retryButton.isHidden = false
            retryButton.setTitle(retryTitle)
            activityIndicator.stopAnimating()
        }
    }

    private func configureAppearance() {
        translatesAutoresizingMaskIntoConstraints = false

        containerView.backgroundColor = DS.Colors.surface
        containerView.layer.cornerRadius = DS.CornerRadius.card

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = DS.Spacing.s

        messageLabel.font = DS.Typography.body()
        messageLabel.textColor = DS.Colors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)
    }

    private func setupLayout() {
        [containerView, stackView, activityIndicator, messageLabel, retryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(containerView)
        containerView.addSubview(stackView)

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(retryButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: DS.Spacing.m),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.m),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.m),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -DS.Spacing.m),

            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }

    @objc
    private func didTapRetry() {
        onRetry?()
    }
}
