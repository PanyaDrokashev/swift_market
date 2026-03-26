import UIKit

final class ProductDetailsModuleBuilder: ProductDetailsModuleBuilding {
    func build(
        input: ProductDetailsModuleInput,
        output: ProductDetailsModuleOutput,
        productDetailsService: ProductDetailsService
    ) -> UIViewController {
        let router = ProductDetailsRouterImpl()
        router.output = output

        let viewController = ProductDetailsViewController(presenter: ProductDetailsPresenterPlaceholder())
        let presenter = ProductDetailsPresenter(
            view: viewController,
            input: input,
            router: router,
            productDetailsService: productDetailsService
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class ProductDetailsPresenterPlaceholder: ProductDetailsPresenterProtocol {
    func didLoad() {}
    func didTapBack() {}
}
