import Foundation

typealias ProductID = String
typealias CategoryID = String
typealias UserID = String

struct Money: Equatable, Sendable {
    let amount: Decimal
    let currencyCode: String
}

struct UserSession: Equatable, Sendable {
    let token: String
    let userID: UserID
    let displayName: String
}

struct ProductCategory: Equatable, Sendable {
    let id: CategoryID
    let title: String
}

struct ProductListItem: Equatable, Sendable {
    let id: ProductID
    let title: String
    let subtitle: String
    let price: Money
    let badgeText: String?
    let imageName: String?
}

struct ProductAttribute: Equatable, Sendable {
    let title: String
    let value: String
}

struct DeliveryInfo: Equatable, Sendable {
    let estimatedDateText: String
    let pickupText: String
}

enum StockStatus: Equatable, Sendable {
    case inStock(quantity: Int)
    case lowStock(quantity: Int)
    case outOfStock
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

struct CatalogContent: Equatable, Sendable {
    let categories: [ProductCategory]
    let selectedCategoryID: CategoryID?
    let products: [ProductListItem]
    let cartItemsCount: Int
}

enum MarketError: Error, Equatable, Sendable {
    case invalidCredentials
    case emptyCatalog
    case productNotFound
    case offline
    case unknown(message: String)
}
