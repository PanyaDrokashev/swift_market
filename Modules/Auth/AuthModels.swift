import Foundation

struct AuthModuleInput: Equatable {
    let prefilledEmail: String?
}

enum AuthViewState: Equatable {
    case initial(AuthInitialViewModel)
    case loading(AuthInitialViewModel)
    case content(AuthInitialViewModel)
    case error(AuthInitialViewModel, message: String)
}

struct AuthInitialViewModel: Equatable {
    let title: String
    let subtitle: String
    let prefilledEmail: String?
    let isLoginEnabled: Bool
}

struct LoginRequest: Equatable, Sendable {
    let email: String
    let password: String
}
