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
    private lazy var imageContainer = UIView()
    private lazy var productImageView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var priceLabel = UILabel()
    private lazy var stockLabel = UILabel()
    private lazy var descriptionLabel = UILabel()
    private lazy var addToCartButton = DSButton()
    private lazy var removeFromCartButton = DSButton()
    private lazy var deliveryLabel = UILabel()
    private lazy var pickupLabel = UILabel()
    private lazy var attributesTitleLabel = UILabel()
    private lazy var attributesStackView = UIStackView()
    private lazy var statusLabel = UILabel()
    private lazy var stateView = DSStateView()
    private lazy var retryButton = DSButton()
    private lazy var imageLoadingIndicator = UIActivityIndicatorView(style: .medium)
    private var imageLoadTask: Task<Void, Never>?
    private var currentImageURLString: String?
    private var isInCart = false

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
        view.backgroundColor = DS.Colors.background

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = DS.Spacing.s
        stackView.alignment = .fill

        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.backgroundColor = DS.Colors.surface
        imageContainer.layer.cornerRadius = DS.CornerRadius.card
        imageContainer.clipsToBounds = true

        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFill
        productImageView.clipsToBounds = true

        imageLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        imageLoadingIndicator.hidesWhenStopped = true

        titleLabel.font = DS.Typography.title()
        titleLabel.textColor = DS.Colors.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        priceLabel.font = DS.Typography.price()
        priceLabel.textColor = DS.Colors.primary
        priceLabel.adjustsFontForContentSizeCategory = true
        stockLabel.font = DS.Typography.caption()
        stockLabel.textColor = DS.Colors.textSecondary
        stockLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.font = DS.Typography.body()
        descriptionLabel.textColor = DS.Colors.textPrimary
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.numberOfLines = 0

        addToCartButton.configure(
            .init(title: "Добавить в корзину", style: .primary)
        )
        addToCartButton.addTarget(self, action: #selector(didTapAddToCart), for: .touchUpInside)
        addToCartButton.isHidden = true

        removeFromCartButton.configure(
            .init(title: "Удалить из корзины", style: .destructive)
        )
        removeFromCartButton.addTarget(self, action: #selector(didTapRemoveFromCart), for: .touchUpInside)
        removeFromCartButton.isHidden = true

        deliveryLabel.font = DS.Typography.body()
        deliveryLabel.textColor = DS.Colors.textSecondary
        deliveryLabel.adjustsFontForContentSizeCategory = true
        pickupLabel.font = DS.Typography.body()
        pickupLabel.textColor = DS.Colors.textSecondary
        pickupLabel.adjustsFontForContentSizeCategory = true
        attributesTitleLabel.font = DS.Typography.heading()
        attributesTitleLabel.textColor = DS.Colors.textPrimary
        attributesTitleLabel.adjustsFontForContentSizeCategory = true
        attributesTitleLabel.text = "Характеристики"
        attributesStackView.axis = .vertical
        attributesStackView.spacing = DS.Spacing.xs

        statusLabel.font = DS.Typography.footnote()
        statusLabel.textColor = DS.Colors.error
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true

        stateView.onRetry = { [weak self] in
            self?.presenter.didLoad()
        }

        retryButton.configure(
            .init(title: "Повторить", style: .secondary)
        )
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        view.addSubview(addToCartButton)
        view.addSubview(removeFromCartButton)
        view.addSubview(stateView)

        [titleLabel, priceLabel, stockLabel, descriptionLabel, deliveryLabel, pickupLabel, attributesTitleLabel, attributesStackView, statusLabel, retryButton].forEach {
            stackView.addArrangedSubview($0)
        }
        stackView.insertArrangedSubview(imageContainer, at: 0)
        imageContainer.addSubview(productImageView)
        imageContainer.addSubview(imageLoadingIndicator)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addToCartButton.topAnchor, constant: -DS.Spacing.s),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.m),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.m),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.m),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.l),

            imageContainer.heightAnchor.constraint(equalToConstant: 200),

            productImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            productImageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            productImageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            productImageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            imageLoadingIndicator.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            addToCartButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: DS.Spacing.m),
            addToCartButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -DS.Spacing.m),
            addToCartButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -DS.Spacing.s),

            removeFromCartButton.leadingAnchor.constraint(equalTo: addToCartButton.leadingAnchor),
            removeFromCartButton.trailingAnchor.constraint(equalTo: addToCartButton.trailingAnchor),
            removeFromCartButton.topAnchor.constraint(equalTo: addToCartButton.topAnchor),
            removeFromCartButton.bottomAnchor.constraint(equalTo: addToCartButton.bottomAnchor),

            stateView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            stateView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            stateView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: DS.Spacing.l),
            stateView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -DS.Spacing.l)
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
        updateImage(urlString: viewModel.imageURLString)

        statusLabel.text = errorMessage
        statusLabel.isHidden = errorMessage == nil
        retryButton.isHidden = screenState != .error
        updateCartButtons(screenState: screenState)
        updateStateOverlay(for: screenState)
    }

    private func updateStateOverlay(for state: ScreenState) {
        if state == .loading {
            stateView.configure(
                .init(state: .loading(message: "Загрузка карточки товара..."))
            )
        } else {
            stateView.configure(.init(state: .hidden))
        }
    }

    private func updateImage(urlString: String?) {
        guard currentImageURLString != urlString else { return }
        currentImageURLString = urlString
        productImageView.image = nil
        imageLoadTask?.cancel()

        guard let urlString, let url = URL(string: urlString) else {
            imageLoadingIndicator.stopAnimating()
            return
        }

        imageLoadingIndicator.startAnimating()

        imageLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }
                await MainActor.run {
                    guard self.currentImageURLString == urlString else { return }
                    self.productImageView.image = image
                    self.imageLoadingIndicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    self.imageLoadingIndicator.stopAnimating()
                }
            }
        }
    }

    private func makeAttributeView(_ attribute: ProductAttributeViewModel) -> UIView {
        let container = UIView()
        let title = UILabel()
        let value = UILabel()

        title.font = DS.Typography.footnote()
        title.textColor = DS.Colors.textSecondary
        title.adjustsFontForContentSizeCategory = true
        title.text = attribute.title

        value.font = DS.Typography.body()
        value.textColor = DS.Colors.textPrimary
        value.adjustsFontForContentSizeCategory = true
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

            value.topAnchor.constraint(equalTo: title.bottomAnchor, constant: DS.Spacing.xxs),
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

    @objc
    private func didTapAddToCart() {
        isInCart = true
        updateCartButtons(screenState: .content)
    }

    @objc
    private func didTapRemoveFromCart() {
        isInCart = false
        updateCartButtons(screenState: .content)
    }

    private func updateCartButtons(screenState: ScreenState) {
        let shouldShowButtons = screenState == .content
        addToCartButton.isHidden = !shouldShowButtons || isInCart
        removeFromCartButton.isHidden = !shouldShowButtons || !isInCart
    }

    deinit {
        imageLoadTask?.cancel()
    }
}
