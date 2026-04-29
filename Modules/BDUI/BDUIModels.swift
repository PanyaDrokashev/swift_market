import Foundation

struct BDUIConfig {
    let title: String
    let endpoint: String
    let key: String
}

struct BDUIModuleInput {
    let config: BDUIConfig
}

enum BDUIViewState {
    case idle(title: String)
    case loading(title: String)
    case content(title: String, node: BDUINode)
    case error(title: String, message: String)
}
