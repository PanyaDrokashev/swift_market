import UIKit

protocol BDUIMapperProtocol {
    func makeView(from node: BDUINode) -> UIView
}

protocol BDUIActionHandling: AnyObject {
    func handle(action: BDUIAction)
}

protocol BDUINodeDecoding {
    func decodeNode(from data: Data) throws -> BDUINode
}

protocol BDUIRendering {
    func render(data: Data) throws -> UIView
}
