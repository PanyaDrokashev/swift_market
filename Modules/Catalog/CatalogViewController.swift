import UIKit

final class CatalogViewController: UIViewController, CatalogView {
    private var presenter: CatalogPresenterProtocol
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let headerView = UIView()
    private let greetingLabel = UILabel()
    private let titleLabel = UILabel()
    private let cartBadgeLabel = PaddingLabel()
    private let categoriesTitleLabel = UILabel()
    private let categoriesScrollView = UIScrollView()
    private let categoriesStackView = UIStackView()
    private let productsTitleLabel = UILabel()
    private let productsStackView = UIStackView()
    private let emptyStateLabel = UILabel()
    private let statusLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let refreshControl = UIRefreshControl()
    private var categoryButtons: [CategoryID: UIButton] = [:]
    private var productViews: [UIView] = []

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
        case .idle(let viewModel), .loading(let viewModel), .content(let viewModel), .empty(let viewModel):
            apply(viewModel: viewModel, statusText: state.statusText, isError: false)
        case .error(let viewModel, let message):
            apply(viewModel: viewModel, statusText: message, isError: true)
        }
    }

    private func configureAppearance() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.prefersLargeTitles = true

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        headerView.backgroundColor = UIColor(red: 0.09, green: 0.17, blue: 0.31, alpha: 1)
        headerView.layer.cornerRadius = 24

        [greetingLabel, titleLabel, categoriesTitleLabel, productsTitleLabel, emptyStateLabel, statusLabel].forEach {
            $0.numberOfLines = 0
            $0.adjustsFontForContentSizeCategory = true
        }

        greetingLabel.font = .preferredFont(forTextStyle: .title3)
        greetingLabel.textColor = UIColor.white.withAlphaComponent(0.84)
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = .white
        cartBadgeLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cartBadgeLabel.textColor = .white
        cartBadgeLabel.backgroundColor = UIColor(red: 0.97, green: 0.48, blue: 0.19, alpha: 1)
        cartBadgeLabel.layer.cornerRadius = 14
        cartBadgeLabel.clipsToBounds = true
        categoriesTitleLabel.font = .preferredFont(forTextStyle: .headline)
        categoriesTitleLabel.text = "Категории"
        productsTitleLabel.font = .preferredFont(forTextStyle: .headline)
        productsTitleLabel.text = "Товары"
        emptyStateLabel.font = .preferredFont(forTextStyle: .body)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.text = "В этой категории пока нет товаров"
        emptyStateLabel.backgroundColor = .white
        emptyStateLabel.layer.cornerRadius = 20
        emptyStateLabel.clipsToBounds = true
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel

        categoriesScrollView.showsHorizontalScrollIndicator = false
        categoriesStackView.axis = .horizontal
        categoriesStackView.spacing = 12
        categoriesStackView.translatesAutoresizingMaskIntoConstraints = false

        productsStackView.axis = .vertical
        productsStackView.spacing = 16

        logoutButton.configuration = .bordered()
        logoutButton.configuration?.title = "Выйти"
        logoutButton.configuration?.baseForegroundColor = UIColor(red: 0.64, green: 0.14, blue: 0.12, alpha: 1)
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)

        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        categoriesScrollView.addSubview(categoriesStackView)

        let headerStack = UIStackView(arrangedSubviews: [greetingLabel, titleLabel, cartBadgeLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .leading
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerStack)

        [headerView, categoriesTitleLabel, categoriesScrollView, productsTitleLabel, productsStackView, emptyStateLabel, statusLabel, logoutButton].forEach {
            stackView.addArrangedSubview($0)
        }

        categoriesScrollView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        emptyStateLabel.heightAnchor.constraint(equalToConstant: 76).isActive = true

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            headerStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20),
            headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20),

            categoriesStackView.topAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.topAnchor),
            categoriesStackView.leadingAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.leadingAnchor),
            categoriesStackView.trailingAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.trailingAnchor),
            categoriesStackView.bottomAnchor.constraint(equalTo: categoriesScrollView.contentLayoutGuide.bottomAnchor),
            categoriesStackView.heightAnchor.constraint(equalTo: categoriesScrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    private func apply(viewModel: CatalogScreenViewModel, statusText: String?, isError: Bool) {
        greetingLabel.text = viewModel.greeting
        titleLabel.text = viewModel.title
        cartBadgeLabel.text = viewModel.cartBadge.map { "\($0) в корзине" }
        cartBadgeLabel.isHidden = viewModel.cartBadge == nil
        renderCategories(viewModel.categories)
        renderProducts(viewModel.products)
        emptyStateLabel.isHidden = !viewModel.products.isEmpty

        statusLabel.text = statusText
        statusLabel.textColor = isError ? .systemRed : .secondaryLabel
        statusLabel.isHidden = statusText == nil
        refreshControl.endRefreshing()
    }

    private func renderCategories(_ categories: [CatalogCategoryViewModel]) {
        categoriesStackView.arrangedSubviews.forEach {
            categoriesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        categoryButtons.removeAll()

        for category in categories {
            let button = UIButton(type: .system)
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
            button.accessibilityIdentifier = category.id
            button.addTarget(self, action: #selector(didTapCategory(_:)), for: .touchUpInside)
            categoriesStackView.addArrangedSubview(button)
            categoryButtons[category.id] = button
        }
    }

    private func renderProducts(_ products: [CatalogProductCardViewModel]) {
        productViews.forEach {
            productsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        productViews.removeAll()

        for product in products {
            let cardView = CatalogProductCardView(viewModel: product)
            cardView.onTap = { [weak self] in
                self?.presenter.didSelectProduct(product.id)
            }
            productsStackView.addArrangedSubview(cardView)
            productViews.append(cardView)
        }
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
}

private extension CatalogViewState {
    var statusText: String? {
        switch self {
        case .idle:
            return nil
        case .loading:
            return "Обновляем каталог..."
        case .content:
            return "Каталог загружен"
        case .empty:
            return "Список товаров пуст"
        case .error(_, let message):
            return message
        }
    }
}

private final class CatalogProductCardView: UIControl {
    private let accentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let priceLabel = UILabel()
    private let badgeLabel = PaddingLabel()
    private let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let textStack = UIStackView()
    var onTap: (() -> Void)?

    init(viewModel: CatalogProductCardViewModel) {
        super.init(frame: .zero)
        configureAppearance()
        setupLayout()
        apply(viewModel: viewModel)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureAppearance() {
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 12)
        layer.shadowRadius = 18

        accentView.backgroundColor = UIColor(red: 0.98, green: 0.66, blue: 0.29, alpha: 1)
        accentView.layer.cornerRadius = 14

        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 2
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        priceLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        priceLabel.textColor = UIColor(red: 0.08, green: 0.22, blue: 0.40, alpha: 1)
        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = UIColor(red: 0.55, green: 0.22, blue: 0.02, alpha: 1)
        badgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.94, blue: 0.84, alpha: 1)
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.clipsToBounds = true
        arrowImageView.tintColor = .tertiaryLabel
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true
        textStack.axis = .vertical
        textStack.spacing = 8
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false

        [accentView, titleLabel, subtitleLabel, priceLabel, badgeLabel, arrowImageView].forEach {
            $0.isUserInteractionEnabled = false
        }
    }

    private func setupLayout() {
        [titleLabel, subtitleLabel, priceLabel, badgeLabel].forEach {
            textStack.addArrangedSubview($0)
        }
        textStack.translatesAutoresizingMaskIntoConstraints = false
        accentView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(accentView)
        addSubview(textStack)
        addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            accentView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            accentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            accentView.widthAnchor.constraint(equalToConstant: 28),
            accentView.heightAnchor.constraint(equalToConstant: 28),

            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            textStack.leadingAnchor.constraint(equalTo: accentView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    private func apply(viewModel: CatalogProductCardViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        priceLabel.text = viewModel.priceText
        badgeLabel.text = viewModel.badgeText
        badgeLabel.isHidden = viewModel.badgeText == nil
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}

private final class PaddingLabel: UILabel {
    private let insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
