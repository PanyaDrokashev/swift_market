import UIKit

protocol CatalogProductsListManagerDelegate: AnyObject {
    func catalogProductsListManager(
        _ manager: CatalogProductsListManager,
        didSelectProductWithID productID: ProductID
    )
}

final class CatalogProductsListManager: NSObject {
    private enum Section: Int {
        case main
    }

    weak var delegate: CatalogProductsListManagerDelegate?
    private var items: [CatalogProductCardViewModel] = []
    private var itemsByID: [ProductID: CatalogProductCardViewModel] = [:]
    private var dataSource: UITableViewDiffableDataSource<Section, ProductID>?

    func bind(to tableView: UITableView) {
        tableView.delegate = self
        tableView.register(CatalogProductTableViewCell.self, forCellReuseIdentifier: CatalogProductTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110

        dataSource = UITableViewDiffableDataSource<Section, ProductID>(tableView: tableView) { [weak self] tableView, indexPath, productID in
            guard
                let self,
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: CatalogProductTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as? CatalogProductTableViewCell
            else {
                return UITableViewCell()
            }

            if let viewModel = self.itemsByID[productID] {
                cell.configure(with: viewModel)
            }
            return cell
        }
        tableView.dataSource = dataSource
    }

    func setItems(_ items: [CatalogProductCardViewModel], in tableView: UITableView) {
        let previousItemsByID = itemsByID
        self.items = items
        self.itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        guard let dataSource else {
            tableView.reloadData()
            return
        }

        let previousIDs = Set(previousItemsByID.keys)
        let currentIDs = Set(itemsByID.keys)
        let changedIDs = currentIDs.intersection(previousIDs).filter {
            previousItemsByID[$0] != itemsByID[$0]
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, ProductID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items.map(\.id), toSection: .main)
        snapshot.reconfigureItems(Array(changedIDs))
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension CatalogProductsListManager: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let productID = dataSource?.itemIdentifier(for: indexPath) else { return }
        delegate?.catalogProductsListManager(self, didSelectProductWithID: productID)
    }
}

private final class CatalogProductTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CatalogProductTableViewCell"

    private lazy var cardView = UIView()
    private lazy var accentView = UIView()
    private lazy var titleLabel = UILabel()
    private lazy var subtitleLabel = UILabel()
    private lazy var priceLabel = UILabel()
    private lazy var badgeLabel = InsetLabel()
    private lazy var arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private lazy var textStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureAppearance()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        priceLabel.text = nil
        badgeLabel.text = nil
        badgeLabel.isHidden = true
    }

    func configure(with viewModel: CatalogProductCardViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        priceLabel.text = viewModel.priceText
        badgeLabel.text = viewModel.badgeText
        badgeLabel.isHidden = viewModel.badgeText == nil
    }

    private func configureAppearance() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 12)
        cardView.layer.shadowRadius = 18

        accentView.backgroundColor = UIColor(red: 0.98, green: 0.66, blue: 0.29, alpha: 1)
        accentView.layer.cornerRadius = 14

        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        priceLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        priceLabel.textColor = UIColor(red: 0.08, green: 0.22, blue: 0.40, alpha: 1)

        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = UIColor(red: 0.55, green: 0.22, blue: 0.02, alpha: 1)
        badgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.94, blue: 0.84, alpha: 1)
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true

        arrowImageView.tintColor = .tertiaryLabel

        textStack.axis = .vertical
        textStack.spacing = 8
        textStack.alignment = .leading
    }

    private func setupLayout() {
        [cardView, accentView, textStack, arrowImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [titleLabel, subtitleLabel, priceLabel, badgeLabel].forEach {
            textStack.addArrangedSubview($0)
        }

        contentView.addSubview(cardView)
        cardView.addSubview(accentView)
        cardView.addSubview(textStack)
        cardView.addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            accentView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            accentView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            accentView.widthAnchor.constraint(equalToConstant: 28),
            accentView.heightAnchor.constraint(equalToConstant: 28),

            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            textStack.leadingAnchor.constraint(equalTo: accentView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),

            arrowImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20)
        ])
    }
}

private final class InsetLabel: UILabel {
    private let insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
