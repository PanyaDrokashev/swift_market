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
    let emailValidationMessage: String?
    let serviceErrorMessage: String?
    let isFieldsEnabled: Bool
    let isLoginEnabled: Bool
}

struct LoginRequest: Equatable, Sendable {
    let email: String
    let password: String
}

enum AuthEmailValidationResult: Equatable {
    case valid
    case invalid(message: String)
}
