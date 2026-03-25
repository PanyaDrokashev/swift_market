import Foundation

protocol AuthRepository {
    func login(request: LoginRequest) async throws -> UserSession
}

protocol CatalogRepository {
    func fetchCatalog(session: UserSession, categoryID: CategoryID?) async throws -> CatalogContent
}

protocol ProductRepository {
    func fetchProductDetails(productID: ProductID) async throws -> ProductDetails
}

protocol SessionStorage {
    func loadSession() -> UserSession?
    func save(session: UserSession)
    func clearSession()
}
