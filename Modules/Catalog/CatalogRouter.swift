import Foundation

final class CatalogRouterImpl: CatalogRouter {
    weak var output: CatalogModuleOutput?

    func openProductDetails(productID: ProductID) {
        output?.catalogModuleDidSelectProduct(productID)
    }

    func openAuth() {
        output?.catalogModuleDidRequestLogout()
    }

    func openBDUI(config: BDUIConfig) {
        output?.catalogModuleDidRequestBDUI(config: config)
    }
}
