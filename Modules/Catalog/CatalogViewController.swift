import UIKit

final class CatalogViewController: UIViewController, CatalogView {
    private var presenter: CatalogPresenterProtocol
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let greetingLabel = UILabel()
    private let titleLabel = UILabel()
    private let categoriesLabel = UILabel()
    private let productsLabel = UILabel()
    private let statusLabel = UILabel()
    private let logoutButton = UIButton(type: .system)

    init(presenter: CatalogPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Список фич"
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
        case .initial(let viewModel), .loading(let viewModel), .content(let viewModel), .empty(let viewModel):
            apply(viewModel: viewModel, statusText: state.statusText, isError: false)
        case .error(let viewModel, let message):
            apply(viewModel: viewModel, statusText: message, isError: true)
        }
    }

    private func configureAppearance() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [greetingLabel, titleLabel, categoriesLabel, productsLabel, statusLabel].forEach {
            $0.numberOfLines = 0
            $0.adjustsFontForContentSizeCategory = true
        }

        greetingLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        categoriesLabel.font = .preferredFont(forTextStyle: .body)
        productsLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel

        logoutButton.configuration = .bordered()
        logoutButton.configuration?.title = "Выйти"
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        [greetingLabel, titleLabel, categoriesLabel, productsLabel, statusLabel, logoutButton].forEach {
            stackView.addArrangedSubview($0)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func apply(viewModel: CatalogScreenViewModel, statusText: String?, isError: Bool) {
        greetingLabel.text = viewModel.greeting
        titleLabel.text = "Заглушка после успешного входа"
        categoriesLabel.text = viewModel.categories.isEmpty
            ? "Категории: пока не выбраны"
            : "Категории: " + viewModel.categories.map(\.title).joined(separator: ", ")
        productsLabel.text = viewModel.products.isEmpty
            ? "Фичи: список пока пуст"
            : "Фичи: " + viewModel.products.map(\.title).joined(separator: ", ")

        statusLabel.text = statusText
        statusLabel.textColor = isError ? .systemRed : .secondaryLabel
        statusLabel.isHidden = statusText == nil
    }

    @objc
    private func didTapLogout() {
        presenter.didTapLogout()
    }
}

private extension CatalogViewState {
    var statusText: String? {
        switch self {
        case .initial:
            return nil
        case .loading:
            return "Загрузка списка фич..."
        case .content:
            return "Вход выполнен успешно"
        case .empty:
            return "Список фич пуст"
        case .error(_, let message):
            return message
        }
    }
}
