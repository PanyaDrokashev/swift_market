import UIKit

protocol BDUIView: AnyObject {
    func render(_ state: BDUIViewState)
}

protocol BDUIPresenterProtocol {
    func didLoad()
    func didTapRetry()
    func didRequestRoute(_ route: String)
}

protocol BDUIRouter {
    func openRoute(config: BDUIConfig)
}

protocol BDUIService {
    func loadNode(config: BDUIConfig) async throws -> BDUINode
}

protocol BDUIModuleBuilding {
    func build(
        input: BDUIModuleInput,
        output: BDUIModuleOutput,
        service: BDUIService
    ) -> UIViewController
}

protocol BDUIModuleOutput: AnyObject {
    func bduiModuleDidRequestOpen(config: BDUIConfig)
}
