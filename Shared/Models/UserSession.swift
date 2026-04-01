import Foundation

struct UserSession: Equatable, Sendable {
    let token: String
    let userID: UserID
    let displayName: String
}
