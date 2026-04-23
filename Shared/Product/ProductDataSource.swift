import Foundation

struct RemoteProductRepository: ProductRepository {
    private let networkClient: NetworkClient
    private let endpointProvider: CatalogEndpointProviding
    private let fallbackLoader: CatalogFallbackLoading?
    private let decoder: JSONDecoder

    init(
        networkClient: NetworkClient = URLSessionNetworkClient(),
        endpointProvider: CatalogEndpointProviding = AlfaITMOCatalogEndpointProvider(),
        fallbackLoader: CatalogFallbackLoading? = BundleCatalogFallbackLoader(),
        decoder: JSONDecoder = CatalogResponseDTO.makeDecoder()
    ) {
        self.networkClient = networkClient
        self.endpointProvider = endpointProvider
        self.fallbackLoader = fallbackLoader
        self.decoder = decoder
    }

    func fetchProductDetails(productID: ProductID) async throws -> ProductDetails {
        do {
            let response: CatalogResponseDTO = try await networkClient.get(
                endpointProvider.catalogURL,
                decoder: decoder
            )
            return try makeDetails(from: response, productID: productID)
        } catch let error as MarketError {
            guard shouldUseFallback(for: error), let fallbackLoader else {
                throw error
            }
            let response = try fallbackLoader.loadCatalog()
            return try makeDetails(from: response, productID: productID)
        } catch {
            throw MarketError.unknown(message: error.localizedDescription)
        }
    }

    private func makeDetails(from response: CatalogResponseDTO, productID: ProductID) throws -> ProductDetails {
        guard let product = response.products.first(where: { $0.id == productID }) else {
            throw MarketError.productNotFound
        }

        let attributes = makeAttributes(from: product)
        let imageNames = product.imageName.map { [$0] } ?? []

        return ProductDetails(
            id: product.id,
            title: product.title,
            description: product.subtitle,
            price: Money(
                amount: try Self.makeDecimal(from: product.price.amount),
                currencyCode: product.price.currencyCode
            ),
            stockStatus: .unknown,
            attributes: attributes,
            deliveryInfo: DeliveryInfo(
                estimatedDateText: "",
                pickupText: ""
            ),
            imageNames: imageNames
        )
    }

    private func makeAttributes(
        from product: CatalogResponseDTO.ProductDTO
    ) -> [ProductAttribute] {
        let infoAttributes = (product.info ?? []).map {
            ProductAttribute(title: $0.name, value: $0.value)
        }
        if !infoAttributes.isEmpty {
            return infoAttributes
        }

        var fallbackAttributes: [ProductAttribute] = [
            ProductAttribute(title: "ID", value: product.id),
            ProductAttribute(title: "Категория ID", value: product.categoryID)
        ]
        if let badgeText = product.badgeText, !badgeText.isEmpty {
            fallbackAttributes.append(ProductAttribute(title: "Метка", value: badgeText))
        }
        return fallbackAttributes
    }

    private static func makeDecimal(from value: String) throws -> Decimal {
        guard let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            throw MarketError.decodingFailed
        }
        return amount
    }

    private func shouldUseFallback(for error: MarketError) -> Bool {
        switch error {
        case .offline, .requestTimedOut, .resourceNotFound, .serverStatus:
            return true
        case .invalidCredentials, .emptyCatalog, .productNotFound, .invalidResponse, .decodingFailed, .cancelled, .unknown:
            return false
        }
    }
}
