import UIKit

protocol ProductDetailsModuleOutput: AnyObject {
    func productDetailsModuleDidFinish()
}

protocol ProductDetailsView: AnyObject {
    func render(_ state: ProductDetailsViewState)
}

protocol ProductDetailsPresenterProtocol {
    func didLoad()
    func didTapBack()
}

protocol ProductDetailsRouter {
    func close()
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
