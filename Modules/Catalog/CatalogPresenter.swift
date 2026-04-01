import Foundation

@MainActor
final class CatalogPresenter: CatalogPresenterProtocol {
    private weak var view: CatalogView?
    private let input: CatalogModuleInput
    private let router: CatalogRouter
    private let catalogService: CatalogService
    private var loadTask: Task<Void, Never>?
    private var selectedCategoryID: CategoryID?
    private var lastViewModel: CatalogScreenViewModel

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
        self.selectedCategoryID = input.selectedCategoryID
        self.lastViewModel = CatalogScreenViewModel(
            title: "Каталог",
            greeting: "Здравствуйте, \(input.session.displayName)",
            categories: [],
            products: [],
            cartBadge: nil
        )
    }

    func didLoad() {
        view?.render(.idle(lastViewModel))
        loadCatalog(selectedCategoryID: selectedCategoryID)
    }

    func didPullToRefresh() {
        loadCatalog(selectedCategoryID: selectedCategoryID)
    }

    func didSelectCategory(_ categoryID: CategoryID) {
        selectedCategoryID = categoryID
        loadCatalog(selectedCategoryID: categoryID)
    }

    func didSelectProduct(_ productID: ProductID) {
        router.openProductDetails(productID: productID)
    }

    func didTapLogout() {
        router.openAuth()
    }

    private func loadCatalog(selectedCategoryID: CategoryID?) {
        loadTask?.cancel()
        let loadingViewModel = makeLoadingViewModel(selectedCategoryID: selectedCategoryID)
        lastViewModel = loadingViewModel
        view?.render(.loading(loadingViewModel))

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let content = try await catalogService.loadCatalog(
                    session: input.session,
                    categoryID: selectedCategoryID
                )
                let viewModel = makeViewModel(content: content)
                self.lastViewModel = viewModel
                if content.products.isEmpty {
                    self.view?.render(.empty(viewModel))
                } else {
                    self.view?.render(.content(viewModel))
                }
            } catch let error as MarketError {
                guard error != .cancelled else { return }
                let errorViewModel = makeLoadingViewModel(selectedCategoryID: selectedCategoryID)
                self.lastViewModel = errorViewModel
                self.view?.render(.error(errorViewModel, message: error.catalogMessage))
            } catch is CancellationError {
                return
            } catch {
                let errorViewModel = makeLoadingViewModel(selectedCategoryID: selectedCategoryID)
                self.lastViewModel = errorViewModel
                self.view?.render(.error(errorViewModel, message: "Не удалось загрузить каталог"))
            }
        }
    }

    private func makeLoadingViewModel(selectedCategoryID: CategoryID?) -> CatalogScreenViewModel {
        CatalogScreenViewModel(
            title: lastViewModel.title,
            greeting: lastViewModel.greeting,
            categories: lastViewModel.categories.map {
                CatalogCategoryViewModel(
                    id: $0.id,
                    title: $0.title,
                    isSelected: $0.id == selectedCategoryID
                )
            },
            products: lastViewModel.products,
            cartBadge: lastViewModel.cartBadge
        )
    }

    deinit {
        loadTask?.cancel()
    }

    private func formattedPrice(_ money: Money) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let amountText = formatter.string(from: NSDecimalNumber(decimal: money.amount)) ?? "\(money.amount)"
        switch money.currencyCode {
        case "RUB":
            return "\(amountText) ₽"
        case "USD":
            return "\(amountText) $"
        default:
            return "\(amountText) \(money.currencyCode)"
        }
    }

    private func makeGreeting(prefix: String) -> String {
        "\(prefix), \(input.session.displayName)"
    }

    private func resolveSelectedCategoryID(
        selectedCategoryID: CategoryID?,
        categories: [ProductCategory]
    ) -> CategoryID? {
        if let selectedCategoryID, categories.contains(where: { $0.id == selectedCategoryID }) {
            return selectedCategoryID
        }
        return categories.first?.id
    }

    private func makeCategories(
        categories: [ProductCategory],
        selectedCategoryID: CategoryID?
    ) -> [CatalogCategoryViewModel] {
        let resolvedCategoryID = resolveSelectedCategoryID(
            selectedCategoryID: selectedCategoryID,
            categories: categories
        )

        return categories.map {
            CatalogCategoryViewModel(
                id: $0.id,
                title: $0.title,
                isSelected: $0.id == resolvedCategoryID
            )
        }
    }

    private func makeProducts(_ products: [ProductListItem]) -> [CatalogProductCardViewModel] {
        products.map {
            CatalogProductCardViewModel(
                id: $0.id,
                title: $0.title,
                subtitle: $0.subtitle,
                priceText: formattedPrice($0.price),
                badgeText: $0.badgeText
            )
        }
    }

    private func makeViewModel(content: CatalogContent) -> CatalogScreenViewModel {
        let resolvedCategoryID = resolveSelectedCategoryID(
            selectedCategoryID: content.selectedCategoryID,
            categories: content.categories
        )
        self.selectedCategoryID = resolvedCategoryID

        return CatalogScreenViewModel(
            title: content.title,
            greeting: makeGreeting(prefix: content.greetingPrefix),
            categories: makeCategories(
                categories: content.categories,
                selectedCategoryID: resolvedCategoryID
            ),
            products: makeProducts(content.products),
            cartBadge: content.cartItemsCount > 0 ? "\(content.cartItemsCount)" : nil
        )
    }
}
