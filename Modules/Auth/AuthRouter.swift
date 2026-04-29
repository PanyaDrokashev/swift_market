import Foundation

final class AuthRouterImpl: AuthRouter {
    weak var output: AuthModuleOutput?

    func openCatalog(with session: UserSession) {
        output?.authModuleDidAuthenticate(session)
    }

    func openBDUI(config: BDUIConfig) {
        output?.authModuleDidRequestBDUI(config: config)
    }
}
