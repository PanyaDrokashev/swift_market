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
        clipsToBounds = false
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false

        cardView.backgroundColor = DS.Colors.card
        cardView.layer.cornerRadius = DS.CornerRadius.card
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 12)
        cardView.layer.shadowRadius = 18

        accentView.backgroundColor = DS.Colors.accent
        accentView.layer.cornerRadius = DS.CornerRadius.button

        titleLabel.font = DS.Typography.heading()
        titleLabel.textColor = DS.Colors.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2

        subtitleLabel.font = DS.Typography.caption()
        subtitleLabel.textColor = DS.Colors.textSecondary
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 0

        priceLabel.font = DS.Typography.price()
        priceLabel.textColor = DS.Colors.primary
        priceLabel.adjustsFontForContentSizeCategory = true

        badgeLabel.font = DS.Typography.footnote()
        badgeLabel.textColor = DS.Colors.textPrimary
        badgeLabel.backgroundColor = DS.Colors.secondary
        badgeLabel.layer.cornerRadius = DS.CornerRadius.button
        badgeLabel.clipsToBounds = true
        badgeLabel.adjustsFontForContentSizeCategory = true
        badgeLabel.isHidden = true

        arrowImageView.tintColor = .tertiaryLabel

        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
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
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.xs),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.xs),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.xs),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.xs),

            accentView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: DS.Spacing.m),
            accentView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: DS.Spacing.m),
            accentView.widthAnchor.constraint(equalToConstant: 28),
            accentView.heightAnchor.constraint(equalToConstant: 28),

            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: DS.Spacing.m),
            textStack.leadingAnchor.constraint(equalTo: accentView.trailingAnchor, constant: DS.Spacing.s),
            textStack.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -DS.Spacing.m),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -DS.Spacing.m),

            arrowImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -DS.Spacing.m)
        ])
    }
}

private final class InsetLabel: UILabel {
    private let insets = UIEdgeInsets(
        top: DS.Spacing.xxs + 2,
        left: DS.Spacing.s - 2,
        bottom: DS.Spacing.xxs + 2,
        right: DS.Spacing.s - 2
    )

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
