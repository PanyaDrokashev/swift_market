import Foundation

enum MarketError: Error, Equatable, Sendable {
    case invalidCredentials
    case emptyCatalog
    case productNotFound
    case offline
    case unknown(message: String)
}
