import UIKit

enum DS {
    enum Colors {
        static var background: UIColor { .systemBackground }
        static var surface: UIColor { .secondarySystemBackground }
        static var primary: UIColor {
            UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(red: 0.45, green: 0.68, blue: 0.95, alpha: 1)
                }
                return UIColor(red: 0.12, green: 0.35, blue: 0.64, alpha: 1)
            }
        }
        static var secondary: UIColor {
            UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(red: 0.20, green: 0.28, blue: 0.38, alpha: 1)
                }
                return UIColor(red: 0.86, green: 0.91, blue: 0.97, alpha: 1)
            }
        }
        static var textPrimary: UIColor { .label }
        static var textSecondary: UIColor { .secondaryLabel }
        static var error: UIColor { .systemRed }
        static var border: UIColor { .separator }
        static var card: UIColor { .systemBackground }
        static var accent: UIColor {
            UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor(red: 0.90, green: 0.58, blue: 0.22, alpha: 1)
                }
                return UIColor(red: 0.98, green: 0.66, blue: 0.29, alpha: 1)
            }
        }
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum CornerRadius {
        static let field: CGFloat = 12
        static let card: CGFloat = 20
        static let button: CGFloat = 14
    }

    enum Typography {
        static func title() -> UIFont {
            UIFontMetrics(forTextStyle: .title2)
                .scaledFont(for: UIFont.systemFont(ofSize: 28, weight: .bold))
        }

        static func heading() -> UIFont {
            UIFont.preferredFont(forTextStyle: .headline)
        }

        static func body() -> UIFont {
            UIFont.preferredFont(forTextStyle: .body)
        }

        static func bodyMedium() -> UIFont {
            UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .medium))
        }

        static func caption() -> UIFont {
            UIFont.preferredFont(forTextStyle: .caption1)
        }

        static func footnote() -> UIFont {
            UIFont.preferredFont(forTextStyle: .footnote)
        }

        static func price() -> UIFont {
            UIFontMetrics(forTextStyle: .title3)
                .scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        }
    }
}
