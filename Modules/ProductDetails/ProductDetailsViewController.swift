import UIKit

final class ProductDetailsViewController: UIViewController, ProductDetailsView {
    private enum ScreenState {
        case initial
        case loading
        case content
        case error
    }

    private var presenter: ProductDetailsPresenterProtocol
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    private lazy var stackView = UIStackView()
    private lazy var imagePlaceholderContainer = UIView()
    private lazy var imagePlaceholderView = UIView()
    private lazy var titleLabel = UILabel()
    private lazy var priceLabel = UILabel()
    private lazy var stockLabel = UILabel()
    private lazy var descriptionLabel = UILabel()
    private lazy var deliveryLabel = UILabel()
    private lazy var pickupLabel = UILabel()
    private lazy var attributesTitleLabel = UILabel()
    private lazy var attributesStackView = UIStackView()
    private lazy var statusLabel = UILabel()
    private lazy var loadingIndicator = UIActivityIndicatorView(style: .large)
    private lazy var retryButton = UIButton(type: .system)

    init(presenter: ProductDetailsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Товар"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupLayout()
        setupNavigation()
        presenter.didLoad()
    }

    func inject(presenter: ProductDetailsPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: ProductDetailsViewState) {
        switch state {
        case .initial(let viewModel):
            apply(viewModel: viewModel, screenState: .initial, errorMessage: nil)
        case .loading(let viewModel):
            apply(viewModel: viewModel, screenState: .loading, errorMessage: nil)
        case .content(let viewModel):
            apply(viewModel: viewModel, screenState: .content, errorMessage: nil)
        case .error(let viewModel, let message):
            apply(viewModel: viewModel, screenState: .error, errorMessage: message)
        }
    }

    private func configureAppearance() {
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill

        imagePlaceholderContainer.translatesAutoresizingMaskIntoConstraints = false
        imagePlaceholderView.backgroundColor = .systemGray5
        imagePlaceholderView.layer.cornerRadius = 12
        imagePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        imagePlaceholderView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        imagePlaceholderView.heightAnchor.constraint(equalTo: imagePlaceholderView.widthAnchor).isActive = true

        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 0
        priceLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        priceLabel.textColor = UIColor(red: 0.03, green: 0.41, blue: 0.81, alpha: 1)
        stockLabel.font = .preferredFont(forTextStyle: .subheadline)
        stockLabel.textColor = .secondaryLabel
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        deliveryLabel.font = .preferredFont(forTextStyle: .subheadline)
        pickupLabel.font = .preferredFont(forTextStyle: .subheadline)
        attributesTitleLabel.font = .preferredFont(forTextStyle: .headline)
        attributesTitleLabel.text = "Характеристики"
        attributesStackView.axis = .vertical
        attributesStackView.spacing = 8

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .systemRed
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        retryButton.configuration = .filled()
        retryButton.configuration?.title = "Повторить"
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        view.addSubview(loadingIndicator)

        [titleLabel, priceLabel, stockLabel, descriptionLabel, deliveryLabel, pickupLabel, attributesTitleLabel, attributesStackView, statusLabel, retryButton].forEach {
            stackView.addArrangedSubview($0)
        }
        stackView.insertArrangedSubview(imagePlaceholderContainer, at: 0)
        imagePlaceholderContainer.addSubview(imagePlaceholderView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            imagePlaceholderView.topAnchor.constraint(equalTo: imagePlaceholderContainer.topAnchor),
            imagePlaceholderView.leadingAnchor.constraint(equalTo: imagePlaceholderContainer.leadingAnchor),
            imagePlaceholderView.bottomAnchor.constraint(equalTo: imagePlaceholderContainer.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
    }

    private func apply(
        viewModel: ProductDetailsScreenViewModel,
        screenState: ScreenState,
        errorMessage: String?
    ) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        priceLabel.text = viewModel.priceText
        stockLabel.text = viewModel.stockText
        stockLabel.isHidden = viewModel.stockText.isEmpty

        if viewModel.deliveryText.isEmpty {
            deliveryLabel.isHidden = true
            deliveryLabel.text = nil
        } else {
            deliveryLabel.isHidden = false
            deliveryLabel.text = "Доставка: \(viewModel.deliveryText)"
        }

        if viewModel.pickupText.isEmpty {
            pickupLabel.isHidden = true
            pickupLabel.text = nil
        } else {
            pickupLabel.isHidden = false
            pickupLabel.text = "Самовывоз: \(viewModel.pickupText)"
        }

        attributesStackView.arrangedSubviews.forEach {
            attributesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for attribute in viewModel.attributes {
            attributesStackView.addArrangedSubview(makeAttributeView(attribute))
        }

        let hasAttributes = !viewModel.attributes.isEmpty
        attributesTitleLabel.isHidden = !hasAttributes
        attributesStackView.isHidden = !hasAttributes

        statusLabel.text = errorMessage
        statusLabel.isHidden = errorMessage == nil
        retryButton.isHidden = screenState != .error

        if screenState == .loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func makeAttributeView(_ attribute: ProductAttributeViewModel) -> UIView {
        let container = UIView()
        let title = UILabel()
        let value = UILabel()

        title.font = .preferredFont(forTextStyle: .footnote)
        title.textColor = .secondaryLabel
        title.text = attribute.title

        value.font = .preferredFont(forTextStyle: .body)
        value.textColor = .label
        value.text = attribute.value
        value.numberOfLines = 0

        [title, value].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            value.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
            value.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            value.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            value.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    @objc
    private func didTapBack() {
        presenter.didTapBack()
    }

    @objc
    private func didTapRetry() {
        presenter.didLoad()
    }
}
