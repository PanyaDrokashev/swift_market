import UIKit

final class AppCoordinator {
    private let navigationController: UINavigationController
    private let authService: AuthService
    private let catalogService: CatalogService
    private let productDetailsService: ProductDetailsService
    private let bduiService: BDUIService
    private let authModuleBuilder: AuthModuleBuilding
    private let catalogModuleBuilder: CatalogModuleBuilding
    private let productDetailsModuleBuilder: ProductDetailsModuleBuilding
    private let bduiModuleBuilder: BDUIModuleBuilding

    init(
        navigationController: UINavigationController = UINavigationController(),
        authService: AuthService = StubAuthService(),
        catalogService: CatalogService = RemoteCatalogService(),
        productDetailsService: ProductDetailsService = RemoteProductDetailsService(),
        bduiService: BDUIService = RemoteBDUIService(),
        authModuleBuilder: AuthModuleBuilding = AuthModuleBuilder(),
        catalogModuleBuilder: CatalogModuleBuilding = CatalogModuleBuilder(),
        productDetailsModuleBuilder: ProductDetailsModuleBuilding = ProductDetailsModuleBuilder(),
        bduiModuleBuilder: BDUIModuleBuilding = BDUIModuleBuilder()
    ) {
        self.navigationController = navigationController
        self.authService = authService
        self.catalogService = catalogService
        self.productDetailsService = productDetailsService
        self.bduiService = bduiService
        self.authModuleBuilder = authModuleBuilder
        self.catalogModuleBuilder = catalogModuleBuilder
        self.productDetailsModuleBuilder = productDetailsModuleBuilder
        self.bduiModuleBuilder = bduiModuleBuilder
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

    private func showBDUI(config: BDUIConfig) {
        let viewController = bduiModuleBuilder.build(
            input: BDUIModuleInput(config: config),
            output: self,
            service: bduiService
        )
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension AppCoordinator: AuthModuleOutput {
    func authModuleDidAuthenticate(_ session: UserSession) {
        showCatalog(session: session)
    }

    func authModuleDidRequestBDUI(config: BDUIConfig) {
        showBDUI(config: config)
    }
}

extension AppCoordinator: CatalogModuleOutput {
    func catalogModuleDidSelectProduct(_ productID: ProductID) {
        showProductDetails(productID: productID)
    }

    func catalogModuleDidRequestLogout() {
        showAuth()
    }

    func catalogModuleDidRequestBDUI(config: BDUIConfig) {
        showBDUI(config: config)
    }
}

extension AppCoordinator: ProductDetailsModuleOutput {
    func productDetailsModuleDidFinish() {
        navigationController.popViewController(animated: true)
    }

    func productDetailsModuleDidRequestBDUI(config: BDUIConfig) {
        showBDUI(config: config)
    }
}

extension AppCoordinator: BDUIModuleOutput {
    func bduiModuleDidRequestOpen(config: BDUIConfig) {
        showBDUI(config: config)
    }
}
