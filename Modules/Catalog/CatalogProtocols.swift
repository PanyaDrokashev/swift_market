import UIKit

protocol CatalogModuleOutput: AnyObject {
    func catalogModuleDidSelectProduct(_ productID: ProductID)
    func catalogModuleDidRequestLogout()
}

protocol CatalogView: AnyObject {
    func render(_ state: CatalogViewState)
}

protocol CatalogPresenterProtocol {
    func didLoad()
    func didPullToRefresh()
    func didSelectCategory(_ categoryID: CategoryID)
    func didSelectProduct(_ productID: ProductID)
    func didTapLogout()
}

protocol CatalogRouter {
    func openProductDetails(productID: ProductID)
    func openAuth()
}

protocol CatalogService {
    func loadCatalog(session: UserSession, categoryID: CategoryID?) async throws -> CatalogContent
}

protocol CatalogModuleBuilding {
    func build(
        input: CatalogModuleInput,
        output: CatalogModuleOutput,
        catalogService: CatalogService
    ) -> UIViewController
}
