import Foundation

final class InMemorySessionStorage: SessionStorage {
    private var session: UserSession?

    func loadSession() -> UserSession? {
        session
    }

    func save(session: UserSession) {
        self.session = session
    }

    func clearSession() {
        session = nil
    }
}

struct StubAuthRepository: AuthRepository {
    func login(request: LoginRequest) async throws -> UserSession {
        guard !request.email.isEmpty, !request.password.isEmpty else {
            throw MarketError.invalidCredentials
        }

        return UserSession(
            token: "stub-token",
            userID: "user-1",
            displayName: "Demo User"
        )
    }
}

struct StubCatalogRepository: CatalogRepository {
    func fetchCatalog(session: UserSession, categoryID: CategoryID?) async throws -> CatalogContent {
        let categories = [
            ProductCategory(id: "groceries", title: "Продукты"),
            ProductCategory(id: "home", title: "Для дома"),
            ProductCategory(id: "electronics", title: "Электроника")
        ]

        let products = [
            ProductListItem(
                id: "coffee",
                title: "Кофе в зернах",
                subtitle: "1 кг, арабика",
                price: Money(amount: Decimal(string: "1790") ?? 0, currencyCode: "RUB"),
                badgeText: "Хит",
                imageName: "Image"
            ),
            ProductListItem(
                id: "lamp",
                title: "Настольная лампа",
                subtitle: "Теплый свет, LED",
                price: Money(amount: Decimal(string: "2490") ?? 0, currencyCode: "RUB"),
                badgeText: nil,
                imageName: "Image"
            )
        ]

        return CatalogContent(
            categories: categories,
            selectedCategoryID: categoryID ?? categories.first?.id,
            products: products,
            cartItemsCount: 2
        )
    }
}

struct StubProductRepository: ProductRepository {
    func fetchProductDetails(productID: ProductID) async throws -> ProductDetails {
        ProductDetails(
            id: productID,
            title: "Кофе в зернах",
            description: "Набор контрактов рассчитан на показ карточки товара, доставки и статуса наличия.",
            price: Money(amount: Decimal(string: "1790") ?? 0, currencyCode: "RUB"),
            stockStatus: .inStock(quantity: 12),
            attributes: [
                ProductAttribute(title: "Обжарка", value: "Средняя"),
                ProductAttribute(title: "Вес", value: "1 кг")
            ],
            deliveryInfo: DeliveryInfo(
                estimatedDateText: "Доставка завтра",
                pickupText: "Самовывоз через 15 минут"
            ),
            imageNames: ["Image"]
        )
    }
}

struct StubAuthService: AuthService {
    private let repository: AuthRepository
    private let sessionStorage: SessionStorage

    init(
        repository: AuthRepository = StubAuthRepository(),
        sessionStorage: SessionStorage = InMemorySessionStorage()
    ) {
        self.repository = repository
        self.sessionStorage = sessionStorage
    }

    func login(request: LoginRequest) async throws -> UserSession {
        let session = try await repository.login(request: request)
        sessionStorage.save(session: session)
        return session
    }
}

struct StubCatalogService: CatalogService {
    private let repository: CatalogRepository

    init(repository: CatalogRepository = StubCatalogRepository()) {
        self.repository = repository
    }

    func loadCatalog(session: UserSession, categoryID: CategoryID?) async throws -> CatalogContent {
        try await repository.fetchCatalog(session: session, categoryID: categoryID)
    }
}

struct StubProductDetailsService: ProductDetailsService {
    private let repository: ProductRepository

    init(repository: ProductRepository = StubProductRepository()) {
        self.repository = repository
    }

    func loadDetails(productID: ProductID) async throws -> ProductDetails {
        try await repository.fetchProductDetails(productID: productID)
    }
}
