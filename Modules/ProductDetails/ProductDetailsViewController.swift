import UIKit

final class ProductDetailsViewController: UIViewController, ProductDetailsView {
    private var presenter: ProductDetailsPresenterProtocol

    init(presenter: ProductDetailsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Товар"
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

    func inject(presenter: ProductDetailsPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: ProductDetailsViewState) {
    }
}
