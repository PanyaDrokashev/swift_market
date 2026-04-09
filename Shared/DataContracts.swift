import Foundation

protocol AuthRepository {
    func login(request: LoginRequest) async throws -> UserSession
}

protocol CatalogRepository {
    func fetchCatalog(session: UserSession) async throws -> CatalogResponseDTO
}

protocol ProductRepository {
    func fetchProductDetails(productID: ProductID) async throws -> ProductDetails
}

protocol SessionStorage {
    func loadSession() -> UserSession?
    func save(session: UserSession)
    func clearSession()
}
