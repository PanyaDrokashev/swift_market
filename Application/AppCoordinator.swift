import UIKit

final class AppCoordinator {
    private let navigationController: UINavigationController
    private let authService: AuthService
    private let catalogService: CatalogService
    private let productDetailsService: ProductDetailsService
    private let authModuleBuilder: AuthModuleBuilding
    private let catalogModuleBuilder: CatalogModuleBuilding
    private let productDetailsModuleBuilder: ProductDetailsModuleBuilding

    init(
        navigationController: UINavigationController = UINavigationController(),
        authService: AuthService = StubAuthService(),
        catalogService: CatalogService = StubCatalogService(),
        productDetailsService: ProductDetailsService = StubProductDetailsService(),
        authModuleBuilder: AuthModuleBuilding = AuthModuleBuilder(),
        catalogModuleBuilder: CatalogModuleBuilding = CatalogModuleBuilder(),
        productDetailsModuleBuilder: ProductDetailsModuleBuilding = ProductDetailsModuleBuilder()
    ) {
        self.navigationController = navigationController
        self.authService = authService
        self.catalogService = catalogService
        self.productDetailsService = productDetailsService
        self.authModuleBuilder = authModuleBuilder
        self.catalogModuleBuilder = catalogModuleBuilder
        self.productDetailsModuleBuilder = productDetailsModuleBuilder
    }

    var rootViewController: UIViewController {
        navigationController
    }

    func start() {
        showAuth()
    }

    private func showAuth() {
        let viewController = authModuleBuilder.build(
            input: AuthModuleInput(prefilledEmail: nil),
            output: self,
            authService: authService
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showCatalog(session: UserSession) {
        let viewController = catalogModuleBuilder.build(
            input: CatalogModuleInput(session: session, selectedCategoryID: nil),
            output: self,
            catalogService: catalogService
        )
        navigationController.setViewControllers([viewController], animated: true)
    }

    private func showProductDetails(productID: ProductID) {
        let viewController = productDetailsModuleBuilder.build(
            input: ProductDetailsModuleInput(productID: productID, source: .catalog),
            output: self,
            productDetailsService: productDetailsService
        )
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension AppCoordinator: AuthModuleOutput {
    func authModuleDidAuthenticate(_ session: UserSession) {
        showCatalog(session: session)
    }
}

extension AppCoordinator: CatalogModuleOutput {
    func catalogModuleDidSelectProduct(_ productID: ProductID) {
        showProductDetails(productID: productID)
    }

    func catalogModuleDidRequestLogout() {
        showAuth()
    }
}

extension AppCoordinator: ProductDetailsModuleOutput {
    func productDetailsModuleDidFinish() {
        navigationController.popViewController(animated: true)
    }
}
