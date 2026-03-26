import UIKit

final class AuthModuleBuilder: AuthModuleBuilding {
    func build(
        input: AuthModuleInput,
        output: AuthModuleOutput,
        authService: AuthService
    ) -> UIViewController {
        let router = AuthRouterImpl()
        router.output = output

        let viewController = AuthViewController(presenter: AuthPresenterPlaceholder())
        let presenter = AuthPresenter(
            view: viewController,
            input: input,
            router: router,
            authService: authService
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class AuthPresenterPlaceholder: AuthPresenterProtocol {
    func didLoad() {}
    func didTapLogin(email: String, password: String) {}
}
