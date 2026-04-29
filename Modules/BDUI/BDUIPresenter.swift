import Foundation

@MainActor
final class BDUIPresenter: BDUIPresenterProtocol {
    private weak var view: BDUIView?
    private let input: BDUIModuleInput
    private let router: BDUIRouter
    private let service: BDUIService
    private var loadTask: Task<Void, Never>?

    init(
        view: BDUIView,
        input: BDUIModuleInput,
        router: BDUIRouter,
        service: BDUIService
    ) {
        self.view = view
        self.input = input
        self.router = router
        self.service = service
    }

    func didLoad() {
        load()
    }

    func didTapRetry() {
        load()
    }

    func didRequestRoute(_ route: String) {
        let routeConfig = BDUIConfig(
            title: input.config.title,
            endpoint: input.config.endpoint,
            key: route
        )
        router.openRoute(config: routeConfig)
    }

    private func load() {
        loadTask?.cancel()
        view?.render(.loading(title: input.config.title))

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let node = try await service.loadNode(config: input.config)
                view?.render(.content(title: input.config.title, node: node))
            } catch let error as MarketError {
                guard error != .cancelled else { return }
                view?.render(.error(title: input.config.title, message: error.bduiMessage))
            } catch {
                view?.render(.error(title: input.config.title, message: "Не удалось загрузить BDUI экран"))
            }
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

private extension MarketError {
    var bduiMessage: String {
        switch self {
        case .resourceNotFound:
            return "Конфиг не найден"
        case .offline:
            return "Нет сети"
        default:
            return "Не удалось загрузить BDUI экран"
        }
    }
}
