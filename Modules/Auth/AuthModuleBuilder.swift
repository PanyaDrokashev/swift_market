import UIKit

final class AuthModuleBuilder: AuthModuleBuilding {
    func build(
        input: AuthModuleInput,
        output: AuthModuleOutput,
        authService: AuthService
    ) -> UIViewController {
        let router = AuthRouterImpl()
        router.output = output
        let emailValidator = AuthEmailValidator()

        let viewController = AuthViewController(
            presenter: AuthPresenterPlaceholder()
        )
        let presenter = AuthPresenter(
            view: viewController,
            input: input,
            router: router,
            authService: authService,
            emailValidator: emailValidator
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class AuthPresenterPlaceholder: AuthPresenterProtocol {
    func didLoad() {}
    func didChangeCredentials(email: String, password: String) {}
    func didTapLogin(email: String, password: String) {}
    func didTapOpenBDUI() {}
}
