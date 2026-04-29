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
    private lazy var logoutButton = DSButton()
    private lazy var refreshControl = UIRefreshControl()
    private lazy var stateView = DSStateView()
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
            apply(viewModel: viewModel, screenState: .idle, statusText: nil)
        case .loading(let viewModel):
            apply(
                viewModel: viewModel,
                screenState: .loading,
                statusText: "Обновляем каталог..."
            )
        case .content(let viewModel):
            apply(viewModel: viewModel, screenState: .content, statusText: nil)
        case .empty(let viewModel):
            apply(
                viewModel: viewModel,
                screenState: .empty,
                statusText: "В этой категории пока нет товаров"
            )
        case .error(let viewModel, let message):
            apply(viewModel: viewModel, screenState: .error, statusText: message)
        }
    }

    private func configureAppearance() {
        view.backgroundColor = DS.Colors.background
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "BDUI",
            style: .plain,
            target: self,
            action: #selector(didTapOpenBDUI)
        )
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        greetingLabel.font = DS.Typography.body()
        greetingLabel.textColor = DS.Colors.textSecondary
        greetingLabel.numberOfLines = 0
        greetingLabel.adjustsFontForContentSizeCategory = true

        titleLabel.font = DS.Typography.title()
        titleLabel.textColor = DS.Colors.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        cartInfoLabel.font = DS.Typography.caption()
        cartInfoLabel.textColor = DS.Colors.textSecondary
        cartInfoLabel.adjustsFontForContentSizeCategory = true

        categoriesTitleLabel.font = DS.Typography.heading()
        categoriesTitleLabel.textColor = DS.Colors.textPrimary
        categoriesTitleLabel.text = "Категории"

        categoriesScrollView.showsHorizontalScrollIndicator = false
        categoriesStackView.axis = .horizontal
        categoriesStackView.spacing = DS.Spacing.s
        categoriesStackView.translatesAutoresizingMaskIntoConstraints = false

        productsTitleLabel.font = DS.Typography.heading()
        productsTitleLabel.textColor = DS.Colors.textPrimary
        productsTitleLabel.text = "Товары"

        productsTableView.backgroundColor = .clear
        productsTableView.separatorStyle = .none
        productsTableView.allowsSelection = true
        productsTableView.refreshControl = refreshControl

        logoutButton.configure(
            .init(title: "Выйти", style: .destructive)
        )
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)

        stateView.onRetry = { [weak self] in
            self?.presenter.didPullToRefresh()
        }

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
            logoutButton,
            stateView
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
        view.addSubview(stateView)
        view.addSubview(logoutButton)

        categoriesScrollView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        logoutButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true

        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: DS.Spacing.xs),
            greetingLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: DS.Spacing.m),
            greetingLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -DS.Spacing.m),

            titleLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: DS.Spacing.xs),
            titleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: logoutButton.leadingAnchor, constant: -DS.Spacing.s),

            cartInfoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DS.Spacing.xxs),
            cartInfoLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            cartInfoLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            categoriesTitleLabel.topAnchor.constraint(equalTo: cartInfoLabel.bottomAnchor, constant: DS.Spacing.m),
            categoriesTitleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            categoriesTitleLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            categoriesScrollView.topAnchor.constraint(equalTo: categoriesTitleLabel.bottomAnchor, constant: DS.Spacing.xs),
            categoriesScrollView.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            categoriesScrollView.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            categoriesStackView.topAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.topAnchor),
            categoriesStackView.leadingAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.leadingAnchor),
            categoriesStackView.trailingAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.trailingAnchor),
            categoriesStackView.bottomAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.bottomAnchor),
            categoriesStackView.heightAnchor.constraint(equalTo: categoriesScrollView.frameLayoutGuide.heightAnchor),

            productsTitleLabel.topAnchor.constraint(equalTo: categoriesScrollView.bottomAnchor, constant: DS.Spacing.l),
            productsTitleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            productsTitleLabel.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            productsTableView.topAnchor.constraint(equalTo: productsTitleLabel.bottomAnchor, constant: DS.Spacing.xs),
            productsTableView.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            productsTableView.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),
            productsTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -DS.Spacing.m),
            productsTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),

            logoutButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: greetingLabel.trailingAnchor),

            stateView.centerXAnchor.constraint(equalTo: productsTableView.centerXAnchor),
            stateView.centerYAnchor.constraint(equalTo: productsTableView.centerYAnchor),
            stateView.leadingAnchor.constraint(greaterThanOrEqualTo: productsTableView.leadingAnchor, constant: DS.Spacing.l),
            stateView.trailingAnchor.constraint(lessThanOrEqualTo: productsTableView.trailingAnchor, constant: -DS.Spacing.l)
        ])
    }

    private func apply(
        viewModel: CatalogScreenViewModel,
        screenState: ScreenState,
        statusText: String?
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
        refreshControl.endRefreshing()
    }

    private func updateStateOverlay(for state: ScreenState, hasItems: Bool, message: String?) {
        switch state {
        case .loading:
            stateView.configure(
                .init(
                    state: .loading(message: message ?? "Загрузка..."),
                    hidesWhenContentExists: hasItems
                )
            )
        case .empty:
            stateView.configure(
                .init(
                    state: .empty(message: message ?? "Список товаров пуст"),
                    hidesWhenContentExists: false
                )
            )
        case .error:
            stateView.configure(
                .init(
                    state: .error(
                        message: message ?? "Не удалось загрузить каталог",
                        retryTitle: "Повторить"
                    ),
                    hidesWhenContentExists: hasItems
                )
            )
        case .idle, .content:
            stateView.configure(.init(state: .hidden))
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
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: DS.Spacing.xs,
            leading: DS.Spacing.m,
            bottom: DS.Spacing.xs,
            trailing: DS.Spacing.m
        )
        configuration.title = category.title
        configuration.baseForegroundColor = category.isSelected ? .white : DS.Colors.textPrimary
        configuration.baseBackgroundColor = category.isSelected ? DS.Colors.primary : DS.Colors.card
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = DS.Typography.bodyMedium()
            return updated
        }
        button.configuration = configuration
        button.layer.shadowOpacity = 0
        button.layer.borderColor = DS.Colors.border.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
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
    private func didTapCategory(_ sender: UIButton) {
        guard let categoryID = sender.accessibilityIdentifier else { return }
        presenter.didSelectCategory(categoryID)
    }

    @objc
    private func didTapOpenBDUI() {
        presenter.didTapOpenBDUI()
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
