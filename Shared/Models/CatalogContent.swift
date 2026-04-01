import Foundation

struct CatalogContent: Equatable, Sendable {
    let title: String
    let greetingPrefix: String
    let categories: [ProductCategory]
    let selectedCategoryID: CategoryID?
    let products: [ProductListItem]
    let cartItemsCount: Int
}
