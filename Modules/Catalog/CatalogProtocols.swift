import UIKit

protocol CatalogModuleOutput: AnyObject {
    func catalogModuleDidSelectProduct(_ productID: ProductID)
    func catalogModuleDidRequestLogout()
    func catalogModuleDidRequestBDUI(config: BDUIConfig)
}

protocol CatalogView: AnyObject {
    func render(_ state: CatalogViewState)
}

protocol CatalogPresenterProtocol {
    func didLoad()
    func didPullToRefresh()
    func didSelectCategory(_ categoryID: CategoryID)
    func didSelectProduct(_ productID: ProductID)
    func didUpdateSearchQuery(_ query: String)
    func didTapLogout()
    func didTapOpenBDUI()
}

protocol CatalogRouter {
    func openProductDetails(productID: ProductID)
    func openAuth()
    func openBDUI(config: BDUIConfig)
}

protocol CatalogService {
    func loadCatalog(session: UserSession) async throws -> CatalogResponseDTO
}

protocol CatalogModuleBuilding {
    func build(
        input: CatalogModuleInput,
        output: CatalogModuleOutput,
        catalogService: CatalogService
    ) -> UIViewController
}
