import UIKit

struct BDUIEdgeInsets: Decodable {
    let top: CGFloat
    let left: CGFloat
    let bottom: CGFloat
    let right: CGFloat

    var uiInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}

enum BDUILabelAlignment: String, Decodable {
    case left
    case center
    case right
    case natural

    var value: NSTextAlignment {
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        case .natural:
            return .natural
        }
    }
}

enum BDUIAxis: String, Decodable {
    case horizontal
    case vertical

    var value: NSLayoutConstraint.Axis {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}

enum BDUIStackAlignment: String, Decodable {
    case fill
    case leading
    case trailing
    case center

    var value: UIStackView.Alignment {
        switch self {
        case .fill:
            return .fill
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .center:
            return .center
        }
    }
}

enum BDUIStackDistribution: String, Decodable {
    case fill
    case fillEqually
    case fillProportionally
    case equalSpacing
    case equalCentering

    var value: UIStackView.Distribution {
        switch self {
        case .fill:
            return .fill
        case .fillEqually:
            return .fillEqually
        case .fillProportionally:
            return .fillProportionally
        case .equalSpacing:
            return .equalSpacing
        case .equalCentering:
            return .equalCentering
        }
    }
}

enum BDUIColorToken: String, Decodable {
    case background
    case surface
    case primary
    case secondary
    case textPrimary
    case textSecondary
    case error
    case border
    case card
    case accent
    case white
    case black

    var value: UIColor {
        switch self {
        case .background:
            return DS.Colors.background
        case .surface:
            return DS.Colors.surface
        case .primary:
            return DS.Colors.primary
        case .secondary:
            return DS.Colors.secondary
        case .textPrimary:
            return DS.Colors.textPrimary
        case .textSecondary:
            return DS.Colors.textSecondary
        case .error:
            return DS.Colors.error
        case .border:
            return DS.Colors.border
        case .card:
            return DS.Colors.card
        case .accent:
            return DS.Colors.accent
        case .white:
            return .white
        case .black:
            return .black
        }
    }
}

enum BDUITypographyToken: String, Decodable {
    case title
    case heading
    case body
    case bodyMedium
    case caption
    case footnote
    case price

    func font() -> UIFont {
        switch self {
        case .title:
            return DS.Typography.title()
        case .heading:
            return DS.Typography.heading()
        case .body:
            return DS.Typography.body()
        case .bodyMedium:
            return DS.Typography.bodyMedium()
        case .caption:
            return DS.Typography.caption()
        case .footnote:
            return DS.Typography.footnote()
        case .price:
            return DS.Typography.price()
        }
    }
}

enum BDUISpacingToken: String, Decodable {
    case xxs
    case xs
    case s
    case m
    case l
    case xl

    var value: CGFloat {
        switch self {
        case .xxs:
            return DS.Spacing.xxs
        case .xs:
            return DS.Spacing.xs
        case .s:
            return DS.Spacing.s
        case .m:
            return DS.Spacing.m
        case .l:
            return DS.Spacing.l
        case .xl:
            return DS.Spacing.xl
        }
    }
}

enum BDUICornerRadiusToken: String, Decodable {
    case field
    case card
    case button

    var value: CGFloat {
        switch self {
        case .field:
            return DS.CornerRadius.field
        case .card:
            return DS.CornerRadius.card
        case .button:
            return DS.CornerRadius.button
        }
    }
}

enum BDUIButtonStyleToken: String, Decodable {
    case primary
    case secondary
    case destructive

    var value: DSButton.Style {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .destructive:
            return .destructive
        }
    }
}

enum BDUIStateViewToken: String, Decodable {
    case hidden
    case loading
    case empty
    case error
}
