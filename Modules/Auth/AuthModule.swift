import UIKit

struct AuthModuleInput: Equatable {
    let prefilledEmail: String?
}

protocol AuthModuleOutput: AnyObject {
    func authModuleDidAuthenticate(_ session: UserSession)
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

protocol AuthView: AnyObject {
    func render(_ state: AuthViewState)
}

protocol AuthPresenterProtocol {
    func didLoad()
    func didTapLogin(email: String, password: String)
}

protocol AuthRouter {
    func openCatalog(with session: UserSession)
}

protocol AuthService {
    func login(request: LoginRequest) async throws -> UserSession
}

final class AuthViewController: UIViewController, AuthView {
    private var presenter: AuthPresenterProtocol

    init(presenter: AuthPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Авторизация"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        presenter.didLoad()
    }

    func inject(presenter: AuthPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: AuthViewState) {
    }
}

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

final class AuthRouterImpl: AuthRouter {
    weak var output: AuthModuleOutput?

    func openCatalog(with session: UserSession) {
        output?.authModuleDidAuthenticate(session)
    }
}

enum AuthModuleBuilder {
    static func build(
        input: AuthModuleInput,
        output: AuthModuleOutput,
        authService: AuthService
    ) -> UIViewController {
        let router = AuthRouterImpl()
        router.output = output

        let placeholderPresenter = AuthPresenterPlaceholder()
        let viewController = AuthViewController(presenter: placeholderPresenter)
        let presenter = AuthPresenter(
            view: viewController,
            input: input,
            router: router,
            authService: authService
        )
        viewController.inject(presenter: presenter)
        return viewController
    }
}

private final class AuthPresenterPlaceholder: AuthPresenterProtocol {
    func didLoad() {}
    func didTapLogin(email: String, password: String) {}
}
