import Foundation

struct Money: Equatable, Sendable {
    let amount: Decimal
    let currencyCode: String
}
