import Foundation

enum MarketError: Error, Equatable, Sendable {
    case invalidCredentials
    case emptyCatalog
    case productNotFound
    case offline
    case requestTimedOut
    case invalidResponse
    case resourceNotFound
    case serverStatus(code: Int)
    case decodingFailed
    case cancelled
    case unknown(message: String)
}

extension MarketError {
    var catalogMessage: String {
        switch self {
        case .offline:
            return "Не удалось подключиться к серверу"
        case .requestTimedOut:
            return "Сервер не ответил вовремя"
        case .resourceNotFound:
            return "Каталог на сервере не найден"
        case .serverStatus(let code):
            return "Сервер вернул ошибку (\(code))"
        case .decodingFailed, .invalidResponse:
            return "Не удалось обработать ответ сервера"
        case .cancelled:
            return "Загрузка была отменена"
        case .emptyCatalog:
            return "Каталог пуст"
        case .unknown(let message):
            return message
        case .invalidCredentials:
            return "Неверный логин или пароль"
        case .productNotFound:
            return "Товар не найден"
        }
    }
}
