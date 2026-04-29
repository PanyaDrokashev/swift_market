import Foundation

@MainActor
final class CatalogPresenter: CatalogPresenterProtocol {
    static let allCategoryID: CategoryID = "__all__"

    private weak var view: CatalogView?
    private let input: CatalogModuleInput
    private let router: CatalogRouter
    private let catalogService: CatalogService
    private var loadTask: Task<Void, Never>?
    private var selectedCategoryID: CategoryID?
    private var searchQuery = ""
    private var lastResponse: CatalogResponseDTO?
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
            title: input.session.displayName,
            greeting: "Здравствуйте",
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

    func didUpdateSearchQuery(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastResponse else { return }

        do {
            let viewModel = try makeViewModel(
                response: lastResponse,
                selectedCategoryID: selectedCategoryID
            )
            lastViewModel = viewModel
            if viewModel.products.isEmpty {
                view?.render(.empty(viewModel))
            } else {
                view?.render(.content(viewModel))
            }
        } catch let error as MarketError {
            view?.render(.error(lastViewModel, message: error.catalogMessage))
        } catch {
            view?.render(.error(lastViewModel, message: "Не удалось применить поиск"))
        }
    }

    func didTapLogout() {
        router.openAuth()
    }

    func didTapOpenBDUI() {
        router.openBDUI(
            config: BDUIConfig(
                title: "BDUI Catalog",
                endpoint: "https://alfaitmo.ru/server/echo/409409",
                key: "swift-market/catalog"
            )
        )
    }

    private func loadCatalog(selectedCategoryID: CategoryID?) {
        loadTask?.cancel()
        let loadingViewModel = makeLoadingViewModel(selectedCategoryID: selectedCategoryID)
        lastViewModel = loadingViewModel
        view?.render(.loading(loadingViewModel))

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await catalogService.loadCatalog(session: input.session)
                self.lastResponse = response
                let viewModel = try makeViewModel(response: response, selectedCategoryID: selectedCategoryID)
                self.lastViewModel = viewModel
                if viewModel.products.isEmpty {
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

    private func makeGreeting() -> String {
        "Здравствуйте"
    }

    private func resolveSelectedCategoryID(
        selectedCategoryID: CategoryID?,
        categories: [CatalogResponseDTO.CategoryDTO]
    ) -> CategoryID? {
        if selectedCategoryID == Self.allCategoryID {
            return Self.allCategoryID
        }
        if let selectedCategoryID, categories.contains(where: { $0.id == selectedCategoryID }) {
            return selectedCategoryID
        }
        return Self.allCategoryID
    }

    private func makeCategories(
        categories: [CatalogResponseDTO.CategoryDTO],
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
        .insertingAllCategory(isSelected: resolvedCategoryID == Self.allCategoryID)
    }

    private func makeProducts(
        _ products: [CatalogResponseDTO.ProductDTO],
        selectedCategoryID: CategoryID?
    ) throws -> [CatalogProductCardViewModel] {
        let normalizedQuery = searchQuery.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )

        var viewModels: [CatalogProductCardViewModel] = []
        viewModels.reserveCapacity(products.count)

        for product in products {
            let isAllCategory = selectedCategoryID == nil || selectedCategoryID == Self.allCategoryID
            guard isAllCategory || product.categoryID == selectedCategoryID else {
                continue
            }
            guard normalizedQuery.isEmpty || Self.matchesSearchQuery(query: normalizedQuery, product: product) else {
                continue
            }

            viewModels.append(
                CatalogProductCardViewModel(
                    id: product.id,
                    title: product.title,
                    subtitle: product.subtitle,
                    priceText: formattedPrice(
                        Money(
                            amount: try Self.makeDecimal(from: product.price.amount),
                            currencyCode: product.price.currencyCode
                        )
                    ),
                    badgeText: product.badgeText
                )
            )
        }

        return viewModels
    }

    private func makeViewModel(
        response: CatalogResponseDTO,
        selectedCategoryID: CategoryID?
    ) throws -> CatalogScreenViewModel {
        let resolvedCategoryID = resolveSelectedCategoryID(
            selectedCategoryID: selectedCategoryID,
            categories: response.categories
        )
        self.selectedCategoryID = resolvedCategoryID

        return CatalogScreenViewModel(
            title: input.session.displayName,
            greeting: makeGreeting(),
            categories: makeCategories(
                categories: response.categories,
                selectedCategoryID: resolvedCategoryID
            ),
            products: try makeProducts(
                response.products,
                selectedCategoryID: resolvedCategoryID
            ),
            cartBadge: response.cartItemsCount > 0 ? "\(response.cartItemsCount)" : nil
        )
    }

    private static func makeDecimal(from value: String) throws -> Decimal {
        guard let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            throw MarketError.decodingFailed
        }
        return amount
    }

    private static func matchesSearchQuery(
        query: String,
        product: CatalogResponseDTO.ProductDTO
    ) -> Bool {
        let searchableText = [product.title, product.subtitle, product.badgeText]
            .compactMap { $0?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) }
            .joined(separator: " ")
        return searchableText.contains(query)
    }
}

private extension Array where Element == CatalogCategoryViewModel {
    func insertingAllCategory(isSelected: Bool) -> [CatalogCategoryViewModel] {
        var result: [CatalogCategoryViewModel] = [
            CatalogCategoryViewModel(
                id: CatalogPresenter.allCategoryID,
                title: "Все",
                isSelected: isSelected
            )
        ]
        result.append(contentsOf: self)
        return result
    }
}
