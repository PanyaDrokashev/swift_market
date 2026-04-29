import Foundation

struct RemoteBDUIService: BDUIService {
    func loadNode(config: BDUIConfig) async throws -> BDUINode {
        let normalizedEndpoint = config.endpoint.hasSuffix("/") ? String(config.endpoint.dropLast()) : config.endpoint
        guard let url = URL(string: "\(normalizedEndpoint)/\(config.key)") else {
            throw MarketError.unknown(message: "Некорректный endpoint для BDUI")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MarketError.invalidResponse
            }
            guard 200..<300 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 404 {
                    throw MarketError.resourceNotFound
                }
                throw MarketError.serverStatus(code: httpResponse.statusCode)
            }

            let rawJSON = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
            print("[BDUI] key=\(config.key) JSON: \(rawJSON)")

            do {
                return try JSONDecoder().decode(BDUINode.self, from: data)
            } catch {
                throw MarketError.decodingFailed
            }
        } catch let error as MarketError {
            throw error
        } catch is CancellationError {
            throw MarketError.cancelled
        } catch {
            throw MarketError.unknown(message: error.localizedDescription)
        }
    }
}
