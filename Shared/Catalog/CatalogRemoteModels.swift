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
        let info: [InfoDTO]?

        enum CodingKeys: String, CodingKey {
            case id
            case categoryID = "category_id"
            case title
            case subtitle
            case price
            case badgeText = "badge_text"
            case imageName = "image_name"
            case info
        }
    }

    struct InfoDTO: Decodable {
        let name: String
        let value: String
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
