import UIKit

protocol AuthModuleOutput: AnyObject {
    func authModuleDidAuthenticate(_ session: UserSession)
}

protocol AuthView: AnyObject {
    func render(_ state: AuthViewState)
}

protocol AuthPresenterProtocol {
    func didLoad()
    func didTapLogin(email: String, password: String)
}

protocol AuthRouter {
    func openCatalog(with session: UserSession)
}

protocol AuthService {
    func login(request: LoginRequest) async throws -> UserSession
}

protocol AuthEmailValidating {
    func validate(email: String) -> AuthEmailValidationResult
}

protocol AuthModuleBuilding {
    func build(
        input: AuthModuleInput,
        output: AuthModuleOutput,
        authService: AuthService
    ) -> UIViewController
}
