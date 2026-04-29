import Foundation

final class AuthPresenter: AuthPresenterProtocol {
    private weak var view: AuthView?
    private let input: AuthModuleInput
    private let router: AuthRouter
    private let authService: AuthService
    private let emailValidator: AuthEmailValidating
    private var email: String
    private var password: String = ""
    private var serviceErrorMessage: String?
    private var isLoading = false

    init(
        view: AuthView,
        input: AuthModuleInput,
        router: AuthRouter,
        authService: AuthService,
        emailValidator: AuthEmailValidating
    ) {
        self.view = view
        self.input = input
        self.router = router
        self.authService = authService
        self.emailValidator = emailValidator
        self.email = input.prefilledEmail ?? ""
    }

    func didLoad() {
        view?.render(.initial(makeViewModel()))
    }

    func didChangeCredentials(email: String, password: String) {
        self.email = email
        self.password = password
        serviceErrorMessage = nil

        guard !isLoading else { return }
        view?.render(.content(makeViewModel()))
    }

    func didTapLogin(email: String, password: String) {
        self.email = email
        self.password = password

        guard canSubmitLogin else {
            view?.render(.content(makeViewModel()))
            return
        }

        serviceErrorMessage = nil
        isLoading = true
        view?.render(.loading(makeViewModel()))

        Task {
            do {
                let request = LoginRequest(
                    email: self.email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: self.password
                )
                let session = try await authService.login(request: request)
                await MainActor.run {
                    self.isLoading = false
                    self.view?.render(.content(self.makeViewModel()))
                    self.router.openCatalog(with: session)
                }
            } catch {
                let message = (error as? MarketError).map(Self.message(for:)) ?? "Не удалось войти"
                await MainActor.run {
                    self.isLoading = false
                    self.serviceErrorMessage = message
                    self.view?.render(.error(self.makeViewModel(), message: message))
                }
            }
        }
    }

    func didTapOpenBDUI() {
        router.openBDUI(
            config: BDUIConfig(
                title: "BDUI Auth",
                endpoint: "https://alfaitmo.ru/server/echo/409409",
                key: "swift-market/auth"
            )
        )
    }

    private func makeViewModel() -> AuthInitialViewModel {
        AuthInitialViewModel(
            title: "Swift Market",
            subtitle: "Вход покупателя в маркетплейс",
            prefilledEmail: input.prefilledEmail,
            emailValidationMessage: emailValidationMessage,
            serviceErrorMessage: serviceErrorMessage,
            isFieldsEnabled: !isLoading,
            isLoginEnabled: canSubmitLogin
        )
    }

    private var canSubmitLogin: Bool {
        !isLoading && emailValidationMessage == nil && hasCredentials
    }

    private var hasCredentials: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedEmail.isEmpty && !trimmedPassword.isEmpty
    }

    private var emailValidationMessage: String? {
        switch emailValidator.validate(email: email) {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
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
