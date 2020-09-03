import UIKit

extension UILabel {
	enum Style {
		case body
		case fatBody
		case bodySubtle
		case headline1
		case headline2
		case headline2Big
		case headline4
		case subtitleBig
		case subtitleSmall
		case subtitleSmaller
		case buttonDark
		case buttonLight
		case portalAnnotation(Bool)
		case portalHeaderNumber(Portal?)
		case portalHeaderNumberCollection(Portal?)
		case hugeNumber
		case annotation
		case sessionProgressNumber
		case comment

		var lineHeightMultiple: CGFloat {
			switch self {
			case .body, .bodySubtle, .subtitleBig:
				return 1.3
			case .headline1, .headline4, .headline2, .fatBody, .headline2Big, .subtitleSmall:
				return 1.2
			default:
				return 1.0
			}
		}

		var kerning: CGFloat {
			switch self {
			case .subtitleBig, .subtitleSmall, .subtitleSmaller, .annotation:
				return 1.0
			case .headline2:
				return 0.5
			default:
				return 0.0
			}
		}

		var isUppercased: Bool {
			switch self {
			case .subtitleBig, .subtitleSmall, .subtitleSmaller, .annotation:
				return true
			default:
				return false
			}
		}

		var isHyphenated: Bool {
			switch self {
			case .body:
				return true
			default:
				return false
			}
		}
		
		var font: UIFont {
			switch self {
			case .body, .bodySubtle:
				return UIFont.font(for: .body)
			case .fatBody:
				return UIFont.font(for: .fatBody)
			case .headline1:
				return UIFont.font(for: .heading1)
			case .headline2:
				return UIFont.font(for: .heading2)
			case .headline2Big:
				return UIFont.font(for: .headline2Big)
			case .subtitleBig:
				return UIFont.font(for: .subtitleBig)
			case .subtitleSmall:
				return UIFont.font(for: .subtitleSmall)
			case .subtitleSmaller:
				return UIFont.font(for: .subtitleSmaller)
			case .headline4:
				return UIFont.font(for: .headline4)
			case .buttonDark, .buttonLight:
				return UIFont.font(for: .button)
			case .portalAnnotation:
				return UIFont.font(for: .portalAnnotation)
			case .portalHeaderNumber(_):
				return UIFont.font(for: .portalHeaderNumber)
			case .portalHeaderNumberCollection(_):
				return UIFont.font(for: .portalHeaderNumberCollection)
			case .hugeNumber:
				return UIFont.font(for: .hugeNumber)
			case .annotation:
				return UIFont.font(for: .annotation)
			case .sessionProgressNumber:
				return UIFont.font(for: .sessionProgressNumber)
			case .comment:
				return UIFont.font(for: .comment)
			}
		}

		var numberOfLines: Int {
			switch self {
			default:
				return 0
			}
		}

		var lineBreakMode: NSLineBreakMode {
			switch self {
			default:
				return .byWordWrapping
			}
		}

		var color: UIColor {
			switch self {
			case .body:
				return .whiteBranded
			case .fatBody:
				return .whiteBranded
			case .headline1, .headline2, .headline4, .headline2Big:
				return .whiteBranded
			case .bodySubtle, .subtitleBig, .subtitleSmall, .subtitleSmaller:
				return .grey60Branded
			case .buttonDark:
				return .champagneBranded
			case .buttonLight:
				return .dark80Branded
			case .portalAnnotation(let isCompleted):
				if isCompleted {
					return .lightGoldBranded
				} else {
					return .grey60Branded
				}
			case .portalHeaderNumber(let portal),
				 .portalHeaderNumberCollection(let portal):
				return portal?.story?.color ?? .whiteBranded
			case .hugeNumber:
				return .dark90Branded
			case .annotation:
				return .grey70Branded
			case .sessionProgressNumber:
				return .grey80Branded
			case .comment:
				return .grey60Branded
			}
		}
	}

	static func label(for style: UILabel.Style, text: String = "", alignment: NSTextAlignment = .left, color: UIColor? = nil) -> UILabel {
		let label = UILabel()
		let attributedString = UILabel.attributedString(for: style, text: text, alignment: alignment)

		label.attributedText = attributedString
		label.font = style.font
		label.numberOfLines = style.numberOfLines
		label.lineBreakMode = style.lineBreakMode

		if let color = color {
			label.textColor = color
		} else {
			label.textColor = style.color
		}

		return label
	}

	static func attributedString(for style: UILabel.Style, text: String, alignment: NSTextAlignment = .left) -> NSAttributedString {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineHeightMultiple = style.lineHeightMultiple
		paragraphStyle.alignment = alignment

		// Consider hyphenation
		var updatedString = style.isHyphenated ? text.hyphenated() : text
		// Consider uppercase
		updatedString = style.isUppercased ? updatedString.uppercased() : updatedString

		let attributedString = NSMutableAttributedString(string: updatedString)
		attributedString.addAttribute(NSAttributedString.Key.kern, value: style.kerning, range: NSMakeRange(0, attributedString.length))
		attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

		return attributedString
	}

	public func height(withConstrainedWidth width: CGFloat) -> CGFloat {
		if let attributedString = attributedText {
			return attributedString.height(withConstrainedWidth: width)
		}
		if let string = text {
			return string.height(withConstrainedWidth: width, font: font)
		}
		return 0
	}

	public func width(withConstrainedHeight height: CGFloat) -> CGFloat {
		if let attributedString = attributedText {
			return attributedString.width(withConstrainedHeight: height)
		}
		if let string = text {
			return string.width(withConstrainedHeight: height, font: font)
		}
		return 0
	}
}

extension UILabel {
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        guard let labelText = self.text else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

        // Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        self.attributedText = attributedString
    }
}
