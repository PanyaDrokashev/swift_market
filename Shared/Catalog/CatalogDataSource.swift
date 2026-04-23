import Foundation

protocol CatalogEndpointProviding {
    var catalogURL: URL { get }
}

struct AlfaITMOCatalogEndpointProvider: CatalogEndpointProviding {
    let baseURL: URL
    let path: String

    init(
        baseURL: URL = URL(string: "https://alfaitmo.ru")!,
        path: String = "409409/catalog"
    ) {
        self.baseURL = baseURL
        self.path = path
    }

    var catalogURL: URL {
        baseURL
            .appendingPathComponent("server")
            .appendingPathComponent("echo")
            .appendingPathComponent(path)
    }
}

protocol CatalogFallbackLoading {
    func loadCatalog() throws -> CatalogResponseDTO
}

struct BundleCatalogFallbackLoader: CatalogFallbackLoading {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(
        bundle: Bundle = .main,
        decoder: JSONDecoder = CatalogResponseDTO.makeDecoder()
    ) {
        self.bundle = bundle
        self.decoder = decoder
    }

    func loadCatalog() throws -> CatalogResponseDTO {
        guard let url = bundle.url(forResource: "CatalogFallback", withExtension: "json") else {
            throw MarketError.resourceNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(CatalogResponseDTO.self, from: data)
        } catch let error as DecodingError {
            throw mapDecodingError(error)
        } catch let error as MarketError {
            throw error
        } catch {
            throw MarketError.unknown(message: error.localizedDescription)
        }
    }

    private func mapDecodingError(_ error: DecodingError) -> MarketError {
        switch error {
        case .dataCorrupted, .keyNotFound, .typeMismatch, .valueNotFound:
            return .decodingFailed
        @unknown default:
            return .unknown(message: error.localizedDescription)
        }
    }
}

extension CatalogResponseDTO {
    static func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }
}

struct RemoteCatalogRepository: CatalogRepository {
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

    func fetchCatalog(session: UserSession) async throws -> CatalogResponseDTO {
        do {
            let response: CatalogResponseDTO = try await networkClient.get(
                endpointProvider.catalogURL,
                decoder: decoder
            )
            debugLog("DTO after decode: \(response)")
            return response
        } catch let error as MarketError {
            debugLog("Repository MarketError: \(error)")
            guard shouldUseFallback(for: error), let fallbackLoader else {
                throw error
            }
            debugLog("Using fallback catalog")
            let response = try fallbackLoader.loadCatalog()
            debugLog("Fallback DTO: \(response)")
            return response
        } catch {
            debugLog("Repository unknown error: \(error)")
            throw MarketError.unknown(message: error.localizedDescription)
        }
    }

    private func shouldUseFallback(for error: MarketError) -> Bool {
        switch error {
        case .offline, .requestTimedOut, .resourceNotFound, .serverStatus:
            return true
        case .invalidCredentials, .emptyCatalog, .productNotFound, .invalidResponse, .decodingFailed, .cancelled, .unknown:
            return false
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[RemoteCatalogRepository] \(message)")
        #endif
    }
}
