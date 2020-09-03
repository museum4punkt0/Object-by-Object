import UIKit

// Implement styled fonts using NSAttributedString

enum FontName: String {
	case light = "JosefinSans-Light"
	case lightItalic = "JosefinSans-LightItalic"
    case regular = "JosefinSans-Regular"
	case regularItalic = "JosefinSans-Italic"
	case semiBold = "JosefinSans-SemiBold"
	case semiBoldItalic = "JosefinSans-SemiBoldItalic"
	case bold = "JosefinSans-Bold"
	case boldItalic = "JosefinSans-BoldItalic"
}

extension UIFont {
	enum Style {
		case body
		case fatBody
		case heading1
		case heading2
		case headline2Big
		case headline4
		case subtitleBig
		case subtitleSmaller
		case subtitleSmall
		case button
		case portalAnnotation
		case hugeNumber
		case portalHeaderNumber
		case portalHeaderNumberCollection
		case annotation
		case sessionProgressNumber
		case billboard
		case comment

		var name: String { return font.rawValue }

		private var font: FontName {
			switch self {
			case .body, .hugeNumber, .portalHeaderNumberCollection, .headline2Big/*, .billboard*/:
				return .light
			case .heading1:
				return .semiBoldItalic
			case .heading2, .annotation:
				return .semiBold
			case .comment:
				return .lightItalic
			default:
				return .regular
			}
		}

		var size: CGFloat {
			switch self {
			case .annotation, .subtitleSmaller:
				return 12
			case .headline4, .subtitleSmall:
				return 14
			case .body, .subtitleBig, .button, .heading2, .fatBody:
				return 18
			case .portalAnnotation:
				return 21
			case .sessionProgressNumber, .comment:
				return 24
			case .heading1, .headline2Big:
				return 36
			case .portalHeaderNumberCollection:
				return 48
			case .portalHeaderNumber:
				return 60
			case .billboard:
				return 64
			case .hugeNumber:
				return 300
			}
		}
	}

	static func font(for style: UIFont.Style) -> UIFont {
        return UIFont(name: style.name, size: style.size)!
    }

    static func font(_ name: FontName, size: CGFloat) -> UIFont {
        return UIFont(name: name.rawValue, size: size)!
    }
}
