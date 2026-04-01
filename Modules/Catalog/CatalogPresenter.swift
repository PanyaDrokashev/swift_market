import Foundation

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
