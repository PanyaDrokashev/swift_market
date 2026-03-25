import UIKit

enum ProductDetailsSource: Equatable {
    case catalog
    case deeplink
}

struct ProductDetailsModuleInput: Equatable {
    let productID: ProductID
    let source: ProductDetailsSource
}

protocol ProductDetailsModuleOutput: AnyObject {
    func productDetailsModuleDidFinish()
}

enum ProductDetailsViewState: Equatable {
    case initial(ProductDetailsScreenViewModel)
    case loading(ProductDetailsScreenViewModel)
    case content(ProductDetailsScreenViewModel)
    case error(ProductDetailsScreenViewModel, message: String)
}

struct ProductDetailsScreenViewModel: Equatable {
    let title: String
    let description: String
    let priceText: String
    let stockText: String
    let deliveryText: String
    let pickupText: String
    let attributes: [ProductAttributeViewModel]
    let imageNames: [String]
}

struct ProductAttributeViewModel: Equatable {
    let title: String
    let value: String
}

protocol ProductDetailsView: AnyObject {
    func render(_ state: ProductDetailsViewState)
}

protocol ProductDetailsPresenterProtocol {
    func didLoad()
    func didTapBack()
}

protocol ProductDetailsRouter {
    func close()
}

protocol ProductDetailsService {
    func loadDetails(productID: ProductID) async throws -> ProductDetails
}

final class ProductDetailsViewController: UIViewController, ProductDetailsView {
    private var presenter: ProductDetailsPresenterProtocol

    init(presenter: ProductDetailsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Товар"
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

    func inject(presenter: ProductDetailsPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: ProductDetailsViewState) {
        // Детальный экран проектируется через view state без UIKit-зависимостей ниже view-слоя.
    }
}

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
            imageNames: details.imageNames
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
            imageNames: []
        )
    }
}

final class ProductDetailsRouterImpl: ProductDetailsRouter {
    weak var output: ProductDetailsModuleOutput?

    func close() {
        output?.productDetailsModuleDidFinish()
    }
}

enum ProductDetailsModuleBuilder {
    static func build(
        input: ProductDetailsModuleInput,
        output: ProductDetailsModuleOutput,
        productDetailsService: ProductDetailsService
    ) -> UIViewController {
        let router = ProductDetailsRouterImpl()
        router.output = output

        let viewController = ProductDetailsViewController(presenter: ProductDetailsPresenterPlaceholder())
        let presenter = ProductDetailsPresenter(
            view: viewController,
            input: input,
            router: router,
            productDetailsService: productDetailsService
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class ProductDetailsPresenterPlaceholder: ProductDetailsPresenterProtocol {
    func didLoad() {}
    func didTapBack() {}
}
