import UIKit

final class BDUIViewController: UIViewController, BDUIView {
    private var presenter: BDUIPresenterProtocol
    private let mapper: BDUIMapper
    private let actionHandler: DefaultBDUIActionHandler

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    private lazy var contentContainer = UIView()
    private lazy var stateView = DSStateView()

    init(
        presenter: BDUIPresenterProtocol,
        mapper: BDUIMapper,
        actionHandler: DefaultBDUIActionHandler
    ) {
        self.presenter = presenter
        self.mapper = mapper
        self.actionHandler = actionHandler
        super.init(nibName: nil, bundle: nil)
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

    func inject(presenter: BDUIPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: BDUIViewState) {
        switch state {
        case .idle(let title):
            self.title = title
            stateView.configure(.init(state: .hidden))
        case .loading(let title):
            self.title = title
            stateView.configure(.init(state: .loading(message: "Загрузка...")))
        case .content(let title, let node):
            self.title = title
            stateView.configure(.init(state: .hidden))
            renderNode(node)
        case .error(let title, let message):
            self.title = title
            stateView.configure(.init(state: .error(message: message, retryTitle: "Повторить")))
        }
    }

    private func configureAppearance() {
        view.backgroundColor = DS.Colors.background
        actionHandler.onReload = { [weak self] in
            self?.presenter.didTapRetry()
        }
        actionHandler.onRoute = { [weak self] route in
            self?.presenter.didRequestRoute(route)
        }
        mapper.actionHandler = actionHandler

        stateView.onRetry = { [weak self] in
            self?.presenter.didTapRetry()
        }
    }

    private func setupLayout() {
        [scrollView, contentView, contentContainer, stateView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentContainer)
        view.addSubview(stateView)

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

            contentContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stateView.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: DS.Spacing.m),
            stateView.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -DS.Spacing.m)
        ])
    }

    private func renderNode(_ node: BDUINode) {
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        let rendered = mapper.makeView(from: node)
        rendered.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(rendered)

        NSLayoutConstraint.activate([
            rendered.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            rendered.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            rendered.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            rendered.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }
}
