import Foundation

final class ProductDetailsRouterImpl: ProductDetailsRouter {
    weak var output: ProductDetailsModuleOutput?

    func close() {
        output?.productDetailsModuleDidFinish()
    }
}
