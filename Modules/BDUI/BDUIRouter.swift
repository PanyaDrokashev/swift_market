import Foundation

final class BDUIRouterImpl: BDUIRouter {
    weak var output: BDUIModuleOutput?

    func openRoute(config: BDUIConfig) {
        output?.bduiModuleDidRequestOpen(config: config)
    }
}
