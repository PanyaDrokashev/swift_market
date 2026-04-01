import Foundation

struct ProductAttribute: Equatable, Sendable {
    let title: String
    let value: String
}

struct ProductCategory: Equatable, Sendable {
    let id: CategoryID
    let title: String
}

struct ProductDetails: Equatable, Sendable {
    let id: ProductID
    let title: String
    let description: String
    let price: Money
    let stockStatus: StockStatus
    let attributes: [ProductAttribute]
    let deliveryInfo: DeliveryInfo
    let imageNames: [String]
}

struct ProductListItem: Equatable, Sendable {
    let id: ProductID
    let title: String
    let subtitle: String
    let price: Money
    let badgeText: String?
    let imageName: String?
}

enum StockStatus: Equatable, Sendable {
    case inStock(quantity: Int)
    case lowStock(quantity: Int)
    case outOfStock
}
