import Foundation

struct CatalogResponseDTO: Decodable, CustomStringConvertible {
    let title: String
    let greetingPrefix: String
    let cartItemsCount: Int
    let categories: [CategoryDTO]
    let products: [ProductDTO]

    enum CodingKeys: String, CodingKey {
        case title
        case greetingPrefix = "greeting_prefix"
        case cartItemsCount = "cart_items_count"
        case categories
        case products
    }

    struct CategoryDTO: Decodable {
        let id: CategoryID
        let title: String
    }

    struct ProductDTO: Decodable {
        let id: ProductID
        let categoryID: CategoryID
        let title: String
        let subtitle: String
        let price: PriceDTO
        let badgeText: String?
        let imageName: String?

        enum CodingKeys: String, CodingKey {
            case id
            case categoryID = "category_id"
            case title
            case subtitle
            case price
            case badgeText = "badge_text"
            case imageName = "image_name"
        }
    }

    struct PriceDTO: Decodable {
        let amount: String
        let currencyCode: String

        enum CodingKeys: String, CodingKey {
            case amount
            case currencyCode = "currency_code"
        }
    }

    var description: String {
        """
        CatalogResponseDTO(title: \(title), greetingPrefix: \(greetingPrefix), cartItemsCount: \(cartItemsCount), categories: \(categories.count), products: \(products.count))
        """
    }
}

extension CatalogResponseDTO {
    func toDomain(selectedCategoryID: CategoryID?) throws -> CatalogContent {
        let domainCategories = categories.map {
            ProductCategory(id: $0.id, title: $0.title)
        }

        let resolvedCategoryID = selectedCategoryID ?? domainCategories.first?.id
        let filteredProducts = try products
            .filter { product in
                guard let resolvedCategoryID else { return true }
                return product.categoryID == resolvedCategoryID
            }
            .map { product in
                ProductListItem(
                    id: product.id,
                    title: product.title,
                    subtitle: product.subtitle,
                    price: Money(
                        amount: try Self.makeDecimal(from: product.price.amount),
                        currencyCode: product.price.currencyCode
                    ),
                    badgeText: product.badgeText,
                    imageName: product.imageName
                )
            }

        return CatalogContent(
            title: title,
            greetingPrefix: greetingPrefix,
            categories: domainCategories,
            selectedCategoryID: resolvedCategoryID,
            products: filteredProducts,
            cartItemsCount: cartItemsCount
        )
    }

    private static func makeDecimal(from value: String) throws -> Decimal {
        guard let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            throw MarketError.decodingFailed
        }
        return amount
    }
}
