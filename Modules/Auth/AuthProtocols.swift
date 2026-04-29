import UIKit

protocol AuthModuleOutput: AnyObject {
    func authModuleDidAuthenticate(_ session: UserSession)
    func authModuleDidRequestBDUI(config: BDUIConfig)
}

protocol AuthView: AnyObject {
    func render(_ state: AuthViewState)
}

protocol AuthPresenterProtocol {
    func didLoad()
    func didChangeCredentials(email: String, password: String)
    func didTapLogin(email: String, password: String)
    func didTapOpenBDUI()
}

protocol AuthRouter {
    func openCatalog(with session: UserSession)
    func openBDUI(config: BDUIConfig)
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
