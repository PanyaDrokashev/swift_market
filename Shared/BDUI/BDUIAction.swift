import Foundation

enum BDUIActionType: String, Decodable {
    case print
    case reload
    case route
}

struct BDUIAction: Decodable {
    let type: BDUIActionType
    let route: String?
    let message: String?
}
