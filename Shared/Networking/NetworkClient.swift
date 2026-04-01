import Foundation

protocol NetworkClient {
    func get<T: Decodable>(_ url: URL, decoder: JSONDecoder) async throws -> T
}

struct URLSessionNetworkClient: NetworkClient {
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 15
    ) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    func get<T: Decodable>(_ url: URL, decoder: JSONDecoder) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        debugLog("GET \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(for: request)
            debugLog("Raw response: \(String(data: data, encoding: .utf8) ?? "<non-utf8 response>")")
            return try decodeResponse(data: data, response: response, decoder: decoder)
        } catch is CancellationError {
            throw MarketError.cancelled
        } catch let error as DecodingError {
            debugLog("DecodingError: \(error)")
            throw mapDecodingError(error)
        } catch let error as URLError {
            debugLog("URLError: \(error)")
            throw mapURLError(error)
        } catch let error as MarketError {
            debugLog("MarketError: \(error)")
            throw error
        } catch {
            debugLog("Unknown error: \(error)")
            throw MarketError.unknown(message: error.localizedDescription)
        }
    }

    private func decodeResponse<T: Decodable>(
        data: Data,
        response: URLResponse,
        decoder: JSONDecoder
    ) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MarketError.invalidResponse
        }

        debugLog("HTTP status: \(httpResponse.statusCode)")

        guard 200..<300 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 404 {
                throw MarketError.resourceNotFound
            }
            throw MarketError.serverStatus(code: httpResponse.statusCode)
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            debugLog("Decoded \(T.self): \(String(describing: decoded))")
            return decoded
        } catch let error as DecodingError {
            throw mapDecodingError(error)
        }
    }

    private func mapURLError(_ error: URLError) -> MarketError {
        switch error.code {
        case .timedOut:
            return .requestTimedOut
        case .cancelled:
            return .cancelled
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .offline
        default:
            return .unknown(message: error.localizedDescription)
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

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[NetworkClient] \(message)")
        #endif
    }
}
