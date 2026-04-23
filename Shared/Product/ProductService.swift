import Foundation

struct RemoteProductDetailsService: ProductDetailsService {
    private let repository: ProductRepository

    init(repository: ProductRepository = RemoteProductRepository()) {
        self.repository = repository
    }

    func loadDetails(productID: ProductID) async throws -> ProductDetails {
        try await repository.fetchProductDetails(productID: productID)
    }
}
