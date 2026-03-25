import UIKit

struct CatalogModuleInput: Equatable {
    let session: UserSession
    let selectedCategoryID: CategoryID?
}

protocol CatalogModuleOutput: AnyObject {
    func catalogModuleDidSelectProduct(_ productID: ProductID)
    func catalogModuleDidRequestLogout()
}

enum CatalogViewState: Equatable {
    case initial(CatalogScreenViewModel)
    case loading(CatalogScreenViewModel)
    case content(CatalogScreenViewModel)
    case empty(CatalogScreenViewModel)
    case error(CatalogScreenViewModel, message: String)
}

struct CatalogScreenViewModel: Equatable {
    let title: String
    let greeting: String
    let categories: [CatalogCategoryViewModel]
    let products: [CatalogProductCardViewModel]
    let cartBadge: String?
}

struct CatalogCategoryViewModel: Equatable {
    let id: CategoryID
    let title: String
    let isSelected: Bool
}

struct CatalogProductCardViewModel: Equatable {
    let id: ProductID
    let title: String
    let subtitle: String
    let priceText: String
    let badgeText: String?
}

protocol CatalogView: AnyObject {
    func render(_ state: CatalogViewState)
}

protocol CatalogPresenterProtocol {
    func didLoad()
    func didPullToRefresh()
    func didSelectCategory(_ categoryID: CategoryID)
    func didSelectProduct(_ productID: ProductID)
    func didTapLogout()
}

protocol CatalogRouter {
    func openProductDetails(productID: ProductID)
    func openAuth()
}

protocol CatalogService {
    func loadCatalog(session: UserSession, categoryID: CategoryID?) async throws -> CatalogContent
}

final class CatalogViewController: UIViewController, CatalogView {
    private var presenter: CatalogPresenterProtocol

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
        view.backgroundColor = .systemBackground
        presenter.didLoad()
    }

    func inject(presenter: CatalogPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: CatalogViewState) {
        // Экран не реализуется, но контракт рендера зафиксирован.
    }
}

final class CatalogPresenter: CatalogPresenterProtocol {
    private weak var view: CatalogView?
    private let input: CatalogModuleInput
    private let router: CatalogRouter
    private let catalogService: CatalogService

    init(
        view: CatalogView,
        input: CatalogModuleInput,
        router: CatalogRouter,
        catalogService: CatalogService
    ) {
        self.view = view
        self.input = input
        self.router = router
        self.catalogService = catalogService
    }

    func didLoad() {
        loadCatalog(selectedCategoryID: input.selectedCategoryID)
    }

    func didPullToRefresh() {
        loadCatalog(selectedCategoryID: input.selectedCategoryID)
    }

    func didSelectCategory(_ categoryID: CategoryID) {
        loadCatalog(selectedCategoryID: categoryID)
    }

    func didSelectProduct(_ productID: ProductID) {
        router.openProductDetails(productID: productID)
    }

    func didTapLogout() {
        router.openAuth()
    }

    private func loadCatalog(selectedCategoryID: CategoryID?) {
        view?.render(.loading(emptyViewModel))

        Task {
            do {
                let content = try await catalogService.loadCatalog(
                    session: input.session,
                    categoryID: selectedCategoryID
                )
                let viewModel = makeViewModel(content: content)
                await MainActor.run {
                    if content.products.isEmpty {
                        self.view?.render(.empty(viewModel))
                    } else {
                        self.view?.render(.content(viewModel))
                    }
                }
            } catch {
                await MainActor.run {
                    self.view?.render(.error(self.emptyViewModel, message: "Не удалось загрузить каталог"))
                }
            }
        }
    }

    private func makeViewModel(content: CatalogContent) -> CatalogScreenViewModel {
        CatalogScreenViewModel(
            title: "Маркет",
            greeting: "Здравствуйте, \(input.session.displayName)",
            categories: content.categories.map {
                CatalogCategoryViewModel(
                    id: $0.id,
                    title: $0.title,
                    isSelected: content.selectedCategoryID == $0.id
                )
            },
            products: content.products.map {
                CatalogProductCardViewModel(
                    id: $0.id,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    priceText: "\($0.price.amount) \($0.price.currencyCode)",
                    badgeText: $0.badgeText
                )
            },
            cartBadge: content.cartItemsCount > 0 ? "\(content.cartItemsCount)" : nil
        )
    }

    private var emptyViewModel: CatalogScreenViewModel {
        CatalogScreenViewModel(
            title: "Маркет",
            greeting: "Здравствуйте, \(input.session.displayName)",
            categories: [],
            products: [],
            cartBadge: nil
        )
    }
}

final class CatalogRouterImpl: CatalogRouter {
    weak var output: CatalogModuleOutput?

    func openProductDetails(productID: ProductID) {
        output?.catalogModuleDidSelectProduct(productID)
    }

    func openAuth() {
        output?.catalogModuleDidRequestLogout()
    }
}

enum CatalogModuleBuilder {
    static func build(
        input: CatalogModuleInput,
        output: CatalogModuleOutput,
        catalogService: CatalogService
    ) -> UIViewController {
        let router = CatalogRouterImpl()
        router.output = output

        let viewController = CatalogViewController(presenter: CatalogPresenterPlaceholder())
        let presenter = CatalogPresenter(
            view: viewController,
            input: input,
            router: router,
            catalogService: catalogService
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class CatalogPresenterPlaceholder: CatalogPresenterProtocol {
    func didLoad() {}
    func didPullToRefresh() {}
    func didSelectCategory(_ categoryID: CategoryID) {}
    func didSelectProduct(_ productID: ProductID) {}
    func didTapLogout() {}
}
