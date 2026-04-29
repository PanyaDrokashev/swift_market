import UIKit

final class BDUIModuleBuilder: BDUIModuleBuilding {
    func build(
        input: BDUIModuleInput,
        output: BDUIModuleOutput,
        service: BDUIService
    ) -> UIViewController {
        let router = BDUIRouterImpl()
        router.output = output

        let mapper = BDUIMapper()
        let actionHandler = DefaultBDUIActionHandler()

        let viewController = BDUIViewController(
            presenter: BDUIPresenterPlaceholder(),
            mapper: mapper,
            actionHandler: actionHandler
        )

        let presenter = BDUIPresenter(
            view: viewController,
            input: input,
            router: router,
            service: service
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class BDUIPresenterPlaceholder: BDUIPresenterProtocol {
    func didLoad() {}
    func didTapRetry() {}
    func didRequestRoute(_ route: String) {}
}
