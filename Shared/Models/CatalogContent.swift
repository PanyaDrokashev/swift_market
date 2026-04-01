import Foundation

struct CatalogContent: Equatable, Sendable {
    let categories: [ProductCategory]
    let selectedCategoryID: CategoryID?
    let products: [ProductListItem]
    let cartItemsCount: Int
}
