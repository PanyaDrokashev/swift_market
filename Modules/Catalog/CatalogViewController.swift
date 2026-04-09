import UIKit

final class CatalogViewController: UIViewController, CatalogView {
    private enum ScreenState {
        case idle
        case loading
        case content
        case empty
        case error
    }

    private var presenter: CatalogPresenterProtocol
    private lazy var greetingLabel = UILabel()
    private lazy var titleLabel = UILabel()
    private lazy var cartInfoLabel = UILabel()
    private lazy var categoriesTitleLabel = UILabel()
    private lazy var categoriesScrollView = UIScrollView()
    private lazy var categoriesStackView = UIStackView()
    private lazy var productsTitleLabel = UILabel()
    private lazy var productsTableView = UITableView(frame: .zero, style: .plain)
    private lazy var statusLabel = UILabel()
    private lazy var logoutButton = UIButton(type: .system)
    private lazy var refreshControl = UIRefreshControl()
    private lazy var stateContainer = UIStackView()
    private lazy var stateActivityIndicator = UIActivityIndicatorView(style: .large)
    private lazy var stateLabel = UILabel()
    private lazy var retryButton = UIButton(type: .system)
    private lazy var searchController = UISearchController(searchResultsController: nil)
    private lazy var listManager: CatalogProductsListManager = {
        let manager = CatalogProductsListManager()
        manager.delegate = self
        return manager
    }()
    private var categoryButtons: [CategoryID: UIButton] = [:]
    private var renderedCategories: [CatalogCategoryViewModel] = []

    init(presenter: CatalogPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Каталог"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupLayout()
        presenter.didLoad()
    }

    func inject(presenter: CatalogPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: CatalogViewState) {
        switch state {
        case .idle(let viewModel):
            apply(viewModel: viewModel, screenState: .idle, statusText: nil, isError: false)
        case .loading(let viewModel):
            apply(
                viewModel: viewModel,
                screenState: .loading,
                statusText: "Обновляем каталог...",
                isError: false
            )
        case .content(let viewModel):
            apply(viewModel: viewModel, screenState: .content, statusText: nil, isError: false)
        case .empty(let viewModel):
            apply(
                viewModel: viewModel,
                screenState: .empty,
                statusText: "Список товаров пуст",
                isError: false
            )
        case .error(let viewModel, let message):
            apply(viewModel: viewModel, screenState: .error, statusText: message, isError: true)
        }
    }

    private func configureAppearance() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        greetingLabel.font = .preferredFont(forTextStyle: .subheadline)
        greetingLabel.textColor = .secondaryLabel
        greetingLabel.numberOfLines = 0
        greetingLabel.adjustsFontForContentSizeCategory = true

        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        cartInfoLabel.font = .preferredFont(forTextStyle: .caption1)
        cartInfoLabel.textColor = .secondaryLabel
        cartInfoLabel.adjustsFontForContentSizeCategory = true

        categoriesTitleLabel.font = .preferredFont(forTextStyle: .headline)
        categoriesTitleLabel.text = "Категории"

        categoriesScrollView.showsHorizontalScrollIndicator = false
        categoriesStackView.axis = .horizontal
        categoriesStackView.spacing = 12
        categoriesStackView.translatesAutoresizingMaskIntoConstraints = false

        productsTitleLabel.font = .preferredFont(forTextStyle: .headline)
        productsTitleLabel.text = "Товары"

        productsTableView.backgroundColor = .clear
        productsTableView.separatorStyle = .none
        productsTableView.allowsSelection = true
        productsTableView.refreshControl = refreshControl

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.adjustsFontForContentSizeCategory = true

        logoutButton.configuration = .bordered()
        logoutButton.configuration?.title = "Выйти"
        logoutButton.configuration?.baseForegroundColor = UIColor(red: 0.64, green: 0.14, blue: 0.12, alpha: 1)
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)

        stateContainer.axis = .vertical
        stateContainer.spacing = 12
        stateContainer.alignment = .center
        stateContainer.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stateContainer.isLayoutMarginsRelativeArrangement = true
        stateContainer.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        stateContainer.layer.cornerRadius = 16
        stateContainer.isHidden = true

        stateLabel.font = .preferredFont(forTextStyle: .body)
        stateLabel.textColor = .secondaryLabel
        stateLabel.textAlignment = .center
        stateLabel.numberOfLines = 0

        retryButton.configuration = .filled()
        retryButton.configuration?.title = "Повторить"
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск по товарам"
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no

        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        listManager.bind(to: productsTableView)
    }

    private func setupLayout() {
        let guide = view.safeAreaLayoutGuide
        [
            greetingLabel,
            titleLabel,
            cartInfoLabel,
            categoriesTitleLabel,
            categoriesScrollView,
            categoriesStackView,
            productsTitleLabel,
            productsTableView,
            statusLabel,
            logoutButton,
            stateContainer
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(greetingLabel)
        view.addSubview(titleLabel)
        view.addSubview(cartInfoLabel)
        view.addSubview(categoriesTitleLabel)
        view.addSubview(categoriesScrollView)
        categoriesScrollView.addSubview(categoriesStackView)
        view.addSubview(productsTitleLabel)
        view.addSubview(productsTableView)
        view.addSubview(statusLabel)
        view.addSubview(logoutButton)
        view.addSubview(stateContainer)

        stateContainer.addArrangedSubview(stateActivityIndicator)
        stateContainer.addArrangedSubview(stateLabel)
        stateContainer.addArrangedSubview(retryButton)

        categoriesScrollView.heightAnchor.constraint(equalToConstant: 38).isActive = true

        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 6),
            greetingLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            greetingLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            cartInfoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            cartInfoLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            cartInfoLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            categoriesTitleLabel.topAnchor.constraint(equalTo: cartInfoLabel.bottomAnchor, constant: 16),
            categoriesTitleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            categoriesTitleLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            categoriesScrollView.topAnchor.constraint(equalTo: categoriesTitleLabel.bottomAnchor, constant: 10),
            categoriesScrollView.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            categoriesScrollView.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            categoriesStackView.topAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.topAnchor),
            categoriesStackView.leadingAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.leadingAnchor),
            categoriesStackView.trailingAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.trailingAnchor),
            categoriesStackView.bottomAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.bottomAnchor),
            categoriesStackView.heightAnchor.constraint(equalTo: categoriesScrollView.frameLayoutGuide.heightAnchor),

            productsTitleLabel.topAnchor.constraint(equalTo: categoriesScrollView.bottomAnchor, constant: 20),
            productsTitleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            productsTitleLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            productsTableView.topAnchor.constraint(equalTo: productsTitleLabel.bottomAnchor, constant: 10),
            productsTableView.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            productsTableView.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: productsTableView.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            logoutButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            logoutButton.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            logoutButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),

            productsTableView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -8),
            productsTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),

            stateContainer.centerXAnchor.constraint(equalTo: productsTableView.centerXAnchor),
            stateContainer.centerYAnchor.constraint(equalTo: productsTableView.centerYAnchor),
            stateContainer.leadingAnchor.constraint(greaterThanOrEqualTo: productsTableView.leadingAnchor, constant: 24),
            stateContainer.trailingAnchor.constraint(lessThanOrEqualTo: productsTableView.trailingAnchor, constant: -24)
        ])
    }

    private func apply(
        viewModel: CatalogScreenViewModel,
        screenState: ScreenState,
        statusText: String?,
        isError: Bool
    ) {
        greetingLabel.text = viewModel.greeting
        titleLabel.text = viewModel.title
        cartInfoLabel.text = viewModel.cartBadge.map { "В корзине: \($0)" }
        cartInfoLabel.isHidden = viewModel.cartBadge == nil
        updateCategories(viewModel.categories)
        listManager.setItems(viewModel.products, in: productsTableView)
        updateStateOverlay(
            for: screenState,
            hasItems: !viewModel.products.isEmpty,
            message: statusText
        )

        statusLabel.text = statusText
        statusLabel.textColor = isError ? .systemRed : .secondaryLabel
        statusLabel.isHidden = statusText == nil || screenState == .content || screenState == .idle
        refreshControl.endRefreshing()
    }

    private func updateStateOverlay(for state: ScreenState, hasItems: Bool, message: String?) {
        switch state {
        case .loading:
            stateContainer.isHidden = hasItems
            stateLabel.text = message ?? "Загрузка..."
            retryButton.isHidden = true
            stateActivityIndicator.startAnimating()
        case .empty:
            stateContainer.isHidden = false
            stateLabel.text = "В этой категории пока нет товаров"
            retryButton.isHidden = true
            stateActivityIndicator.stopAnimating()
        case .error:
            stateContainer.isHidden = hasItems
            stateLabel.text = message ?? "Не удалось загрузить каталог"
            retryButton.isHidden = false
            stateActivityIndicator.stopAnimating()
        case .idle, .content:
            stateContainer.isHidden = true
            retryButton.isHidden = true
            stateActivityIndicator.stopAnimating()
        }
    }

    private func updateCategories(_ categories: [CatalogCategoryViewModel]) {
        guard !shouldRebuildCategories(new: categories) else {
            renderCategories(categories)
            renderedCategories = categories
            return
        }

        for category in categories {
            guard let button = categoryButtons[category.id] else { continue }
            applyCategoryStyle(button, category: category)
        }
        renderedCategories = categories
    }

    private func shouldRebuildCategories(new categories: [CatalogCategoryViewModel]) -> Bool {
        guard renderedCategories.count == categories.count else { return true }
        for (oldCategory, newCategory) in zip(renderedCategories, categories) {
            if oldCategory.id != newCategory.id || oldCategory.title != newCategory.title {
                return true
            }
        }
        return false
    }

    private func renderCategories(_ categories: [CatalogCategoryViewModel]) {
        categoriesStackView.arrangedSubviews.forEach {
            categoriesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        categoryButtons.removeAll()

        for category in categories {
            let button = UIButton(type: .system)
            applyCategoryStyle(button, category: category)
            button.accessibilityIdentifier = category.id
            button.addTarget(self, action: #selector(didTapCategory(_:)), for: .touchUpInside)
            categoriesStackView.addArrangedSubview(button)
            categoryButtons[category.id] = button
        }
    }

    private func applyCategoryStyle(_ button: UIButton, category: CatalogCategoryViewModel) {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        configuration.title = category.title
        configuration.baseForegroundColor = category.isSelected ? .white : UIColor(red: 0.20, green: 0.28, blue: 0.40, alpha: 1)
        configuration.baseBackgroundColor = category.isSelected
            ? UIColor(red: 0.12, green: 0.35, blue: 0.64, alpha: 1)
            : .white
        button.configuration = configuration
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = category.isSelected ? 0.14 : 0.06
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
    }

    @objc
    private func didTapLogout() {
        presenter.didTapLogout()
    }

    @objc
    private func didPullToRefresh() {
        presenter.didPullToRefresh()
    }

    @objc
    private func didTapRetry() {
        presenter.didPullToRefresh()
    }

    @objc
    private func didTapCategory(_ sender: UIButton) {
        guard let categoryID = sender.accessibilityIdentifier else { return }
        presenter.didSelectCategory(categoryID)
    }
}

extension CatalogViewController: CatalogProductsListManagerDelegate {
    func catalogProductsListManager(
        _ manager: CatalogProductsListManager,
        didSelectProductWithID productID: ProductID
    ) {
        presenter.didSelectProduct(productID)
    }
}

extension CatalogViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        presenter.didUpdateSearchQuery(searchController.searchBar.text ?? "")
    }
}
