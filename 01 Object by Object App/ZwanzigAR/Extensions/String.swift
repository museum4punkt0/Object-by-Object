import UIKit

extension NSAttributedString {
	func height(withConstrainedWidth width: CGFloat) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect,
											options: .usesLineFragmentOrigin,
											context: nil)

		return ceil(boundingBox.height)
	}

	func width(withConstrainedHeight height: CGFloat) -> CGFloat {
		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
		let boundingBox = self.boundingRect(with: constraintRect,
											options: .usesLineFragmentOrigin,
											context: nil)

		return ceil(boundingBox.width)
	}
}

extension String {
	mutating func removePrefixString(_ maxLength: Int) -> String {
		var prefixString = ""
		let length = min(count, maxLength)
		for _ in 0..<length {
			prefixString += String(self.removeFirst())
		}
		return prefixString
	}

	mutating func removeSuffixString(maxLength: Int) -> String {
		var suffixString = ""
		let length = min(count, maxLength)
		for _ in 0..<length {
			suffixString = String(self.removeLast()) + suffixString
		}
		return suffixString
	}

	func height(withConstrainedWidth width: CGFloat,
				font: UIFont,
				lineHeightMultiple: CGFloat = 1.0,
				kerning: CGFloat = 0.0) -> CGFloat {
		let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect,
											options: .usesLineFragmentOrigin,
											attributes: [NSAttributedString.Key.font: font,
														 NSAttributedString.Key.paragraphStyle: paragraphStyle,NSAttributedString.Key.kern: kerning],
											context: nil)

		return ceil(boundingBox.height)
	}

	func width(withConstrainedHeight height: CGFloat,
			   font: UIFont,
			   kerning: CGFloat = 0.0) -> CGFloat {
		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
		let boundingBox = self.boundingRect(with: constraintRect,
											options: .usesLineFragmentOrigin,
											attributes: [NSAttributedString.Key.font: font,
														 NSAttributedString.Key.kern: kerning],
											context: nil)

		return ceil(boundingBox.width)
	}

	// MARK: - Hyphenation

	func hyphenated(languageCode: String = "de_DE") -> String {
		let locale = Locale(identifier: languageCode)
		return self.hyphenated(locale: locale)
	}

	func hyphenated(locale: Locale) -> String {
		guard CFStringIsHyphenationAvailableForLocale(locale as CFLocale) else { return self }

		var s = self

		let fullRange = CFRangeMake(0, s.utf16.count)
		var hyphenationLocations = [CFIndex]()
		for (i, _) in s.utf16.enumerated() {
			let location: CFIndex = CFStringGetHyphenationLocationBeforeIndex(s as CFString, i, fullRange, 0, locale as CFLocale, nil)
			if hyphenationLocations.last != location {
				hyphenationLocations.append(location)
			}
		}

		for l in hyphenationLocations.reversed() {
			guard l > 0 else { continue }
			//            let strIndex = String.UTF16View.Index(encodedOffset: l)
			let strIndex = String.Index(utf16Offset: l, in: s)
			// insert soft hyphen:
			s.insert("\u{00AD}", at: strIndex)
			// or insert a regular hyphen to debug:
			// s.insert("-", at: strIndex)
		}

		return s
	}

	func withLineBreaksAfterWords(lineLength: Int) -> String {
		let words = self.components(separatedBy: .whitespacesAndNewlines)
		var lines = [String]()
		var currentLine = [String]()
		for word in words {
			if (currentLine + [word]).joined(separator: " ").count > lineLength {
				if currentLine.count > 0 {
					lines.append(currentLine.joined(separator: " "))
				}
				currentLine = [word]
			}
			else {
				currentLine.append(word)
			}
		}
		lines.append(currentLine.joined(separator: " "))
		return lines.joined(separator: "\n")
	}
	
	func uppercasedAttributedString() -> NSMutableAttributedString {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineHeightMultiple = 1.3
		paragraphStyle.alignment = .center

		let attributedString = NSMutableAttributedString(string: self.uppercased())
		attributedString.addAttribute(NSAttributedString.Key.kern, value: 1, range: NSMakeRange(0, attributedString.length))
		attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

		return attributedString
	}
}
