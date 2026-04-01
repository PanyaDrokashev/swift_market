import Foundation

final class AuthPresenter: AuthPresenterProtocol {
    private weak var view: AuthView?
    private let input: AuthModuleInput
    private let router: AuthRouter
    private let authService: AuthService

    init(
        view: AuthView,
        input: AuthModuleInput,
        router: AuthRouter,
        authService: AuthService
    ) {
        self.view = view
        self.input = input
        self.router = router
        self.authService = authService
    }

    func didLoad() {
        view?.render(.initial(makeViewModel(isLoginEnabled: true)))
    }

    func didTapLogin(email: String, password: String) {
        view?.render(.loading(makeViewModel(isLoginEnabled: false)))

        Task {
            do {
                let session = try await authService.login(request: LoginRequest(email: email, password: password))
                await MainActor.run {
                    self.view?.render(.content(self.makeViewModel(isLoginEnabled: true)))
                    self.router.openCatalog(with: session)
                }
            } catch {
                let message = (error as? MarketError).map(Self.message(for:)) ?? "Не удалось войти"
                await MainActor.run {
                    self.view?.render(.error(self.makeViewModel(isLoginEnabled: true), message: message))
                }
            }
        }
    }

    private func makeViewModel(isLoginEnabled: Bool) -> AuthInitialViewModel {
        AuthInitialViewModel(
            title: "Swift Market",
            subtitle: "Вход покупателя в маркетплейс",
            prefilledEmail: input.prefilledEmail,
            isLoginEnabled: isLoginEnabled
        )
    }

    private static func message(for error: MarketError) -> String {
        switch error {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .offline:
            return "Нет сети"
        case .unknown(let message):
            return message
        default:
            return "Не удалось войти"
        }
    }
}
