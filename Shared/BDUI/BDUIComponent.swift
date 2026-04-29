import UIKit

enum BDUIComponentType: String, Decodable {
    case view
    case stack
    case label
    case button
    case textField
    case stateView
    case spacer
}

struct BDUIStyle: Decodable {
    let backgroundColor: BDUIColorToken?
    let cornerRadius: BDUICornerRadiusToken?
    let borderColor: BDUIColorToken?
    let borderWidth: CGFloat?
    let textColor: BDUIColorToken?
    let font: BDUITypographyToken?
    let numberOfLines: Int?
    let alignment: BDUILabelAlignment?
    let isHidden: Bool?
}

struct BDUILayout: Decodable {
    let spacing: BDUISpacingToken?
    let axis: BDUIAxis?
    let alignment: BDUIStackAlignment?
    let distribution: BDUIStackDistribution?
    let contentInsets: BDUIEdgeInsets?
    let width: CGFloat?
    let height: CGFloat?
}

struct BDUIContent: Decodable {
    let text: String?
    let placeholder: String?
    let title: String?
    let isSecureTextEntry: Bool?
    let buttonStyle: BDUIButtonStyleToken?
    let isEnabled: Bool?
    let state: BDUIStateViewToken?
    let retryTitle: String?
    let message: String?
}
