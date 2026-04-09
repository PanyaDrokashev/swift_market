import Foundation

final class ProductDetailsPresenter: ProductDetailsPresenterProtocol {
    private weak var view: ProductDetailsView?
    private let input: ProductDetailsModuleInput
    private let router: ProductDetailsRouter
    private let productDetailsService: ProductDetailsService

    init(
        view: ProductDetailsView,
        input: ProductDetailsModuleInput,
        router: ProductDetailsRouter,
        productDetailsService: ProductDetailsService
    ) {
        self.view = view
        self.input = input
        self.router = router
        self.productDetailsService = productDetailsService
    }

    func didLoad() {
        view?.render(.initial(emptyViewModel))
        view?.render(.loading(emptyViewModel))

        Task {
            do {
                let details = try await productDetailsService.loadDetails(productID: input.productID)
                await MainActor.run {
                    self.view?.render(.content(self.makeViewModel(details: details)))
                }
            } catch {
                await MainActor.run {
                    self.view?.render(.error(self.emptyViewModel, message: "Не удалось загрузить карточку товара"))
                }
            }
        }
    }

    func didTapBack() {
        router.close()
    }

    private func makeViewModel(details: ProductDetails) -> ProductDetailsScreenViewModel {
        ProductDetailsScreenViewModel(
            title: details.title,
            description: details.description,
            priceText: "\(details.price.amount) \(details.price.currencyCode)",
            stockText: stockText(for: details.stockStatus),
            deliveryText: details.deliveryInfo.estimatedDateText,
            pickupText: details.deliveryInfo.pickupText,
            attributes: details.attributes.map { ProductAttributeViewModel(title: $0.title, value: $0.value) },
            imageNames: details.imageNames,
            imageURLString: resolveImageURLString(from: details.imageNames)
        )
    }

    private func stockText(for status: StockStatus) -> String {
        switch status {
        case .inStock(let quantity):
            return "В наличии: \(quantity)"
        case .lowStock(let quantity):
            return "Осталось мало: \(quantity)"
        case .outOfStock:
            return "Нет в наличии"
        case .unknown:
            return ""
        }
    }

    private var emptyViewModel: ProductDetailsScreenViewModel {
        ProductDetailsScreenViewModel(
            title: "Товар",
            description: "",
            priceText: "",
            stockText: "",
            deliveryText: "",
            pickupText: "",
            attributes: [],
            imageNames: [],
            imageURLString: nil
        )
    }

    private func resolveImageURLString(from imageNames: [String]) -> String? {
        if let first = imageNames.first,
           let url = URL(string: first),
           let scheme = url.scheme,
           !scheme.isEmpty {
            return first
        }
        return nil
    }
}
