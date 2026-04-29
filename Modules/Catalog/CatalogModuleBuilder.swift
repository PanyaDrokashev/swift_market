import UIKit

final class CatalogModuleBuilder: CatalogModuleBuilding {
    func build(
        input: CatalogModuleInput,
        output: CatalogModuleOutput,
        catalogService: CatalogService
    ) -> UIViewController {
        let router = CatalogRouterImpl()
        router.output = output

        let viewController = CatalogViewController(presenter: CatalogPresenterPlaceholder())
        let presenter = CatalogPresenter(
            view: viewController,
            input: input,
            router: router,
            catalogService: catalogService
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class CatalogPresenterPlaceholder: CatalogPresenterProtocol {
    func didLoad() {}
    func didPullToRefresh() {}
    func didSelectCategory(_ categoryID: CategoryID) {}
    func didSelectProduct(_ productID: ProductID) {}
    func didUpdateSearchQuery(_ query: String) {}
    func didTapLogout() {}
    func didTapOpenBDUI() {}
}
