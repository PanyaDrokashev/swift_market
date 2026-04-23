import Foundation

enum ProductDetailsSource: Equatable {
    case catalog
    case deeplink
}

struct ProductDetailsModuleInput: Equatable {
    let productID: ProductID
    let source: ProductDetailsSource
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
    let imageURLString: String?
}

struct ProductAttributeViewModel: Equatable {
    let title: String
    let value: String
}
