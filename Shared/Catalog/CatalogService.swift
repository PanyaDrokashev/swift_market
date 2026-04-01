import Foundation

struct RemoteCatalogService: CatalogService {
    private let repository: CatalogRepository

    init(repository: CatalogRepository = RemoteCatalogRepository()) {
        self.repository = repository
    }

    func loadCatalog(session: UserSession, categoryID: CategoryID?) async throws -> CatalogContent {
        try await repository.fetchCatalog(session: session, categoryID: categoryID)
    }
}
