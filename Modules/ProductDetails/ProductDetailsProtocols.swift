import UIKit

protocol ProductDetailsModuleOutput: AnyObject {
    func productDetailsModuleDidFinish()
    func productDetailsModuleDidRequestBDUI(config: BDUIConfig)
}

protocol ProductDetailsView: AnyObject {
    func render(_ state: ProductDetailsViewState)
}

protocol ProductDetailsPresenterProtocol {
    func didLoad()
    func didTapBack()
    func didTapOpenBDUI()
}

protocol ProductDetailsRouter {
    func close()
    func openBDUI(config: BDUIConfig)
}

protocol ProductDetailsService {
    func loadDetails(productID: ProductID) async throws -> ProductDetails
}

protocol ProductDetailsModuleBuilding {
    func build(
        input: ProductDetailsModuleInput,
        output: ProductDetailsModuleOutput,
        productDetailsService: ProductDetailsService
    ) -> UIViewController
}
