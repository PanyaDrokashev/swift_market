import Foundation

struct RemoteCatalogService: CatalogService {
    private let repository: CatalogRepository

    init(repository: CatalogRepository = RemoteCatalogRepository()) {
        self.repository = repository
    }

    func loadCatalog(session: UserSession) async throws -> CatalogResponseDTO {
        try await repository.fetchCatalog(session: session)
    }
}
