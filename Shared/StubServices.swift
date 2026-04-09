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
        guard
            request.email == DemoCredentials.email,
            request.password == DemoCredentials.password
        else {
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
    func fetchCatalog(session: UserSession) async throws -> CatalogResponseDTO {
        CatalogResponseDTO(
            title: "Swift Market",
            greetingPrefix: "Здравствуйте",
            cartItemsCount: 2,
            categories: [
                CatalogResponseDTO.CategoryDTO(id: "groceries", title: "Продукты"),
                CatalogResponseDTO.CategoryDTO(id: "home", title: "Для дома"),
                CatalogResponseDTO.CategoryDTO(id: "electronics", title: "Электроника")
            ],
            products: [
                CatalogResponseDTO.ProductDTO(
                    id: "coffee",
                    categoryID: "groceries",
                    title: "Кофе в зернах",
                    subtitle: "1 кг, арабика",
                    price: CatalogResponseDTO.PriceDTO(amount: "1790", currencyCode: "RUB"),
                    badgeText: "Хит",
                    imageName: "Image",
                    info: [
                        CatalogResponseDTO.InfoDTO(name: "Вес", value: "1 кг"),
                        CatalogResponseDTO.InfoDTO(name: "Сорт", value: "Арабика"),
                        CatalogResponseDTO.InfoDTO(name: "Обжарка", value: "Средняя")
                    ]
                ),
                CatalogResponseDTO.ProductDTO(
                    id: "lamp",
                    categoryID: "home",
                    title: "Настольная лампа",
                    subtitle: "Теплый свет, LED",
                    price: CatalogResponseDTO.PriceDTO(amount: "2490", currencyCode: "RUB"),
                    badgeText: nil,
                    imageName: "Image",
                    info: [
                        CatalogResponseDTO.InfoDTO(name: "Тип", value: "LED"),
                        CatalogResponseDTO.InfoDTO(name: "Цвет света", value: "Теплый"),
                        CatalogResponseDTO.InfoDTO(name: "Питание", value: "220В")
                    ]
                )
            ]
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

enum DemoCredentials {
    static let email = "test@mail.ru"
    static let password = "password"
}

struct StubCatalogService: CatalogService {
    private let repository: CatalogRepository

    init(repository: CatalogRepository = StubCatalogRepository()) {
        self.repository = repository
    }

    func loadCatalog(session: UserSession) async throws -> CatalogResponseDTO {
        try await repository.fetchCatalog(session: session)
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
