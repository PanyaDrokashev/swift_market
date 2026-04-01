import Foundation

struct CatalogModuleInput: Equatable {
    let session: UserSession
    let selectedCategoryID: CategoryID?
}

enum CatalogViewState: Equatable {
    case idle(CatalogScreenViewModel)
    case loading(CatalogScreenViewModel)
    case content(CatalogScreenViewModel)
    case empty(CatalogScreenViewModel)
    case error(CatalogScreenViewModel, message: String)
}

struct CatalogScreenViewModel: Equatable {
    let title: String
    let greeting: String
    let categories: [CatalogCategoryViewModel]
    let products: [CatalogProductCardViewModel]
    let cartBadge: String?
}

struct CatalogCategoryViewModel: Equatable {
    let id: CategoryID
    let title: String
    let isSelected: Bool
}

struct CatalogProductCardViewModel: Equatable {
    let id: ProductID
    let title: String
    let subtitle: String
    let priceText: String
    let badgeText: String?
}
