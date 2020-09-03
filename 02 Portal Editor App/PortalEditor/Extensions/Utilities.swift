// swiftlint:disable shorthand_operator

import Foundation
import ARKit

extension CGSize {
    func aspectFit(_ aspectRatio: CGSize) -> CGSize {
        let mW = width / aspectRatio.width
        let mH = height / aspectRatio.height

		var boundingSize = self
        if (mH < mW) {
            boundingSize.width = height / aspectRatio.height * aspectRatio.width
        }
        else if (mW < mH) {
            boundingSize.height = width / aspectRatio.width * aspectRatio.height
        }
        
        return boundingSize
    }
    
    func aspectFill(_ aspectRatio: CGSize) -> CGSize {
        let mW = width / aspectRatio.width
        let mH = height / aspectRatio.height

        var minimumSize = self
		if (mH > mW) {
            minimumSize.width = height / aspectRatio.height * aspectRatio.width
        }
        else if (mW > mH) {
            minimumSize.height = width / aspectRatio.width * aspectRatio.height
        }
        
        return minimumSize
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

	func height(withConstrainedWidth width: CGFloat, font: UIFont, lineHeightMultiple: CGFloat = 1.0) -> CGFloat {
		let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle], context: nil)

		return ceil(boundingBox.height)
	}

	func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

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

extension UIBarButtonItem {
	static func systemCloseButton(target: Any?, action: Selector) -> UIBarButtonItem {
		return UIBarButtonItem(barButtonSystemItem: .close, target: target, action: action)
	}
}

extension UIButton {
	static func systemCloseButton() -> UIButton {
		if #available(iOS 13.0, *) {
			return UIButton(type: .close)
		}
		let closeButton: UIButton
		closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
		closeButton.setTitle("×", for: .normal)
		closeButton.titleLabel?.font = .systemFont(ofSize: 30)
		closeButton.setTitleColor(.system(.secondaryLabel), for: .normal)
		closeButton.titleEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0)
		closeButton.backgroundColor = .system(.systemGray5)
		closeButton.addCornerRadius()
		NSLayoutConstraint.activate([
			closeButton.widthAnchor.constraint(equalToConstant: closeButton.frame.size.width),
			closeButton.heightAnchor.constraint(equalToConstant: closeButton.frame.size.height)
		])
		return closeButton
	}
}

extension UIColor {

	public convenience init?(hex: String) {
		var hexColor = hex
        
        if hexColor.first == "#" { hexColor.removeFirst() }
        if hexColor.count == 6 { hexColor.append("FF") }
        
        guard hexColor.count == 8 else { return nil }

		let channel = { CGFloat(UInt8(hexColor.removePrefixString(2), radix: 16) ?? 0)/255 }
		self.init(red: channel(), green: channel(), blue: channel(), alpha: channel())
    }

	// MARK: - Story Colors
	static let storyColor = [
		CFStory.StoryColor.yellow: #colorLiteral(red: 0.9725490196, green: 0.7960784314, blue: 0.1843137255, alpha: 1),
		CFStory.StoryColor.pink: #colorLiteral(red: 0.8392156863, green: 0.4117647059, blue: 0.7019607843, alpha: 1),
		CFStory.StoryColor.red: #colorLiteral(red: 0.9725490196, green: 0.1987878193, blue: 0.0815810691, alpha: 1),
		CFStory.StoryColor.brown: #colorLiteral(red: 0.6970055132, green: 0.3993434245, blue: 0.2237497524, alpha: 1),
		CFStory.StoryColor.ochre: #colorLiteral(red: 0.8759839324, green: 0.5902309763, blue: 0.1456114637, alpha: 1),
		CFStory.StoryColor.cyan: #colorLiteral(red: 0.5705307699, green: 0.8316846012, blue: 0.7945935053, alpha: 1),
		CFStory.StoryColor.champagne: UIColor.champagneBranded
	]
	static let champagneBranded: UIColor = #colorLiteral(red: 0.8705882353, green: 0.7843137255, blue: 0.5568627451, alpha: 1)
	static let dark80Branded: UIColor = #colorLiteral(red: 0.08235294118, green: 0.07843137255, blue: 0.1137254902, alpha: 1)
	
	// MARK: - Light/Dark Mode Compatibility
	
	enum ColorMode {
		case light, dark
	}

	static var colorMode: ColorMode?

	enum SystemPre13: String {
		case label, secondaryLabel, tertiaryLabel, quaternaryLabel, systemFill, secondarySystemFill, tertiarySystemFill, quaternarySystemFill, placeholderText, systemBackground, secondarySystemBackground, tertiarySystemBackground, systemGroupedBackground, secondarySystemGroupedBackground, tertiarySystemGroupedBackground, separator, opaqueSeparator, link, darkText, lightText, systemBlue, systemGreen, systemIndigo, systemOrange, systemPink, systemPurple, systemRed, systemTeal, systemYellow, systemGray, systemGray2, systemGray3, systemGray4, systemGray5, systemGray6
	}
	
	static func system(_ systemColorName: SystemPre13) -> UIColor {
		
		let hexString: String
		
		switch systemColorName {
		case .label:
			if #available(iOS 13.0, *) { return .label }
			hexString = UIColor.colorMode == .light ? "#000000ff" : "#ffffffff"
		case .secondaryLabel:
			if #available(iOS 13.0, *) { return .secondaryLabel }
			hexString = UIColor.colorMode == .light ? "#3c3c4399" : "#ebebf599"
		case .tertiaryLabel:
			if #available(iOS 13.0, *) { return .tertiaryLabel }
			hexString = UIColor.colorMode == .light ? "#3c3c434c" : "#ebebf54c"
		case .quaternaryLabel:
			if #available(iOS 13.0, *) { return .quaternaryLabel }
			hexString = UIColor.colorMode == .light ? "#3c3c432d" : "#ebebf52d"
		case .systemFill:
			if #available(iOS 13.0, *) { return .systemFill }
			hexString = UIColor.colorMode == .light ? "#78788033" : "#7878805b"
		case .secondarySystemFill:
			if #available(iOS 13.0, *) { return .secondarySystemFill }
			hexString = UIColor.colorMode == .light ? "#78788028" : "#78788051"
		case .tertiarySystemFill:
			if #available(iOS 13.0, *) { return .tertiarySystemFill }
			hexString = UIColor.colorMode == .light ? "#7676801e" : "#7676803d"
		case .quaternarySystemFill:
			if #available(iOS 13.0, *) { return .quaternarySystemFill }
			hexString = UIColor.colorMode == .light ? "#74748014" : "#7676802d"
		case .placeholderText:
			if #available(iOS 13.0, *) { return .placeholderText }
			hexString = UIColor.colorMode == .light ? "#3c3c434c" : "#ebebf54c"
		case .systemBackground:
			if #available(iOS 13.0, *) { return .systemBackground }
			hexString = UIColor.colorMode == .light ? "#ffffffff" : "#000000ff"
		case .secondarySystemBackground:
			if #available(iOS 13.0, *) { return .secondarySystemBackground }
			hexString = UIColor.colorMode == .light ? "#f2f2f7ff" : "#1c1c1eff"
		case .tertiarySystemBackground:
			if #available(iOS 13.0, *) { return .tertiarySystemBackground }
			hexString = UIColor.colorMode == .light ? "#ffffffff" : "#2c2c2eff"
		case .systemGroupedBackground:
			if #available(iOS 13.0, *) { return .systemGroupedBackground }
			hexString = UIColor.colorMode == .light ? "#f2f2f7ff" : "#000000ff"
		case .secondarySystemGroupedBackground:
			if #available(iOS 13.0, *) { return .secondarySystemGroupedBackground }
			hexString = UIColor.colorMode == .light ? "#ffffffff" : "#1c1c1eff"
		case .tertiarySystemGroupedBackground:
			if #available(iOS 13.0, *) { return .tertiarySystemGroupedBackground }
			hexString = UIColor.colorMode == .light ? "#f2f2f7ff" : "#2c2c2eff"
		case .separator:
			if #available(iOS 13.0, *) { return .separator }
			hexString = UIColor.colorMode == .light ? "#3c3c4349" : "#54545899"
		case .opaqueSeparator:
			if #available(iOS 13.0, *) { return .opaqueSeparator }
			hexString = UIColor.colorMode == .light ? "#c6c6c8ff" : "#38383aff"
		case .link:
			if #available(iOS 13.0, *) { return .link }
			hexString = UIColor.colorMode == .light ? "#007affff" : "#0984ffff"
		case .darkText:
			if #available(iOS 13.0, *) { return .darkText }
			hexString = UIColor.colorMode == .light ? "#000000ff" : "#000000ff"
		case .lightText:
			if #available(iOS 13.0, *) { return .lightText }
			hexString = UIColor.colorMode == .light ? "#ffffff99" : "#ffffff99"
		case .systemBlue:
			if #available(iOS 13.0, *) { return .systemBlue }
			hexString = UIColor.colorMode == .light ? "#007affff" : "#0a84ffff"
		case .systemGreen:
			if #available(iOS 13.0, *) { return .systemGreen }
			hexString = UIColor.colorMode == .light ? "#34c759ff" : "#30d158ff"
		case .systemIndigo:
			if #available(iOS 13.0, *) { return .systemIndigo }
			hexString = UIColor.colorMode == .light ? "#5856d6ff" : "#5e5ce6ff"
		case .systemOrange:
			if #available(iOS 13.0, *) { return .systemOrange }
			hexString = UIColor.colorMode == .light ? "#ff9500ff" : "#ff9f0aff"
		case .systemPink:
			if #available(iOS 13.0, *) { return .systemPink }
			hexString = UIColor.colorMode == .light ? "#ff2d55ff" : "#ff375fff"
		case .systemPurple:
			if #available(iOS 13.0, *) { return .systemPurple }
			hexString = UIColor.colorMode == .light ? "#af52deff" : "#bf5af2ff"
		case .systemRed:
			if #available(iOS 13.0, *) { return .systemRed }
			hexString = UIColor.colorMode == .light ? "#ff3b30ff" : "#ff453aff"
		case .systemTeal:
			if #available(iOS 13.0, *) { return .systemTeal }
			hexString = UIColor.colorMode == .light ? "#5ac8faff" : "#64d2ffff"
		case .systemYellow:
			if #available(iOS 13.0, *) { return .systemYellow }
			hexString = UIColor.colorMode == .light ? "#ffcc00ff" : "#ffd60aff"
		case .systemGray:
			if #available(iOS 13.0, *) { return .systemGray }
			hexString = UIColor.colorMode == .light ? "#8e8e93ff" : "#8e8e93ff"
		case .systemGray2:
			if #available(iOS 13.0, *) { return .systemGray2 }
			hexString = UIColor.colorMode == .light ? "#aeaeb2ff" : "#636366ff"
		case .systemGray3:
			if #available(iOS 13.0, *) { return .systemGray3 }
			hexString = UIColor.colorMode == .light ? "#c7c7ccff" : "#48484aff"
		case .systemGray4:
			if #available(iOS 13.0, *) { return .systemGray4 }
			hexString = UIColor.colorMode == .light ? "#d1d1d6ff" : "#3a3a3cff"
		case .systemGray5:
			if #available(iOS 13.0, *) { return .systemGray5 }
			hexString = UIColor.colorMode == .light ? "#e5e5eaff" : "#2c2c2eff"
		case .systemGray6:
			if #available(iOS 13.0, *) { return .systemGray6 }
			hexString = UIColor.colorMode == .light ? "#f2f2f7ff" : "#1c1c1eff"
		}
		
		
		return UIColor(hex: hexString) ?? .black
	}
	
	// MARK: - Color Asset Management
	
	enum Asset: String {
		case champagne
		case mediumGrey
		case dark
		case darker
		case active
		case red
		case green
		case proximityBlue
	}
	
	static func asset(_ asset: Asset) -> UIColor {
		return UIColor(named: asset.rawValue) ?? .black
	}
	
	// MARK: -
	
	func withBrightnessAdjusted(by factor: CGFloat = 0.3) -> UIColor {
		var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
			if b < 1 {
				let newB: CGFloat = min(max((1 + factor) * b, 0), 1)
				return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
			} else {
				let newS: CGFloat = min(max((1 - factor) * s, 0), 1)
				return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
			}
		}
		return self
	}

}

extension UIImage {
    func getPixelColor(at point: CGPoint) -> UIColor? {
        guard
            let cgImage = cgImage,
            let pixelData = cgImage.dataProvider?.data
        else { return nil }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let bytesPerPixel = cgImage.bitsPerPixel / 8

        let pixelInfo: Int = ((cgImage.bytesPerRow * Int(point.y)) + (Int(point.x) * bytesPerPixel))

        let b = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let r = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

	func inverted() -> UIImage? {
		guard let ciImage = CIImage(image: self) else {
			return nil
		}
		return UIImage(ciImage: ciImage.applyingFilter("CIColorInvert", parameters: [:]))
	}

	static func composeButtonImage(from thumbImage: UIImage, alpha: CGFloat = 1.0) -> UIImage {
		let maskImage = #imageLiteral(resourceName: "buttonring")
		var thumbnailImage = thumbImage
		if let invertedImage = thumbImage.inverted() {
			thumbnailImage = invertedImage
		}

		// Compose a button image based on a white background and the inverted thumbnail image.
		UIGraphicsBeginImageContextWithOptions(maskImage.size, false, 0.0)
		let maskDrawRect = CGRect(origin: CGPoint.zero,
								  size: maskImage.size)
		let thumbDrawRect = CGRect(origin: CGPoint((maskImage.size - thumbImage.size) / 2),
								   size: thumbImage.size)
		maskImage.draw(in: maskDrawRect, blendMode: .normal, alpha: alpha)
		thumbnailImage.draw(in: thumbDrawRect, blendMode: .normal, alpha: alpha)
		let composedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return composedImage!
	}
}

// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
	var average: CGFloat? {
		guard !isEmpty else {
			return nil
		}

		var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
			var cur = cur
			cur += next
			return cur
		}
		let fcount = CGFloat(count)
		ret /= fcount
		return ret
	}
}

extension Array where Iterator.Element == SCNVector3 {
	var average: SCNVector3? {
		guard !isEmpty else {
			return nil
		}

		var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
			var cur = cur
			cur.x += next.x
			cur.y += next.y
			cur.z += next.z
			return cur
		}
		let fcount = Float(count)
		ret.x /= fcount
		ret.y /= fcount
		ret.z /= fcount

		return ret
	}
}

extension FileManager {
	
	enum DocumentSubfolder: String, CaseIterable {
		case fetchedAssets
		case locallyGenerated
	}
	
	func documentSubfolderURL(_ subfolder: DocumentSubfolder) -> URL {
		let subfolderURL = urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(subfolder.rawValue)
		
		if !fileExists(atPath: subfolderURL.path) {
			try? createDirectory(at: subfolderURL, withIntermediateDirectories: true)
		}
		
		return subfolderURL
	}
	
	func modificationDate(url: URL) -> Date? {
		return try? attributesOfItem(atPath: url.path)[.modificationDate] as? Date
	}
}


extension RangeReplaceableCollection {
	mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

// MARK: - SCNNode extension

extension SCNNode {

	func setUniformScale(_ scale: Float) {
		self.scale = SCNVector3Make(scale, scale, scale)
	}

	func renderOnTop() {
		self.renderingOrder = 2
		if let geom = self.geometry {
			for material in geom.materials {
				material.readsFromDepthBuffer = false
			}
		}
		for child in self.childNodes {
			child.renderOnTop()
		}
	}

	func set(lightingModel: SCNMaterial.LightingModel, recursively: Bool = true) {
		for child in childNodes {
			child.geometry?.firstMaterial?.lightingModel = lightingModel
			if recursively {
				child.set(lightingModel: lightingModel, recursively: recursively)
			}
		}
	}
	
	var allGeometries: [SCNGeometry] {
		var geometries = [SCNGeometry]()
		if let geometry = geometry { geometries.append(geometry) }
		for child in childNodes { geometries += child.allGeometries }
		return geometries
	}
	
	var allMaterials: [SCNMaterial] {
		return allGeometries.flatMap({ $0.materials })
	}

	func nilIfEmpty() -> SCNNode? {
        return childNodes.isEmpty ? nil : self
    }
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {

	init(_ vec: vector_float3) {
		self.init()
		self.x = vec.x
		self.y = vec.y
		self.z = vec.z
	}

	func length() -> Float {
		return sqrtf(x * x + y * y + z * z)
	}

	mutating func setLength(_ length: Float) {
		self.normalize()
		self *= length
	}

	mutating func setMaximumLength(_ maxLength: Float) {
		if self.length() <= maxLength {
			return
		} else {
			self.normalize()
			self *= maxLength
		}
	}

	mutating func normalize() {
		self = self.normalized()
	}

	func normalized() -> SCNVector3 {
		if self.length() == 0 {
			return self
		}

		return self / self.length()
	}

	static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
		return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
	}
	
	static func positionFromTransform(_ transform: simd_float3) -> SCNVector3 {
		return SCNVector3Make(transform.x, transform.y, transform.z)
	}

	func friendlyString(_ digits: UInt = 2) -> String {
		return "(\(String(format: "%.\(digits)f", x)), \(String(format: "%.\(digits)f", y)), \(String(format: "%.\(digits)f", z)))"
	}

	func dot(_ vec: SCNVector3) -> Float {
		return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
	}

	func cross(_ vec: SCNVector3) -> SCNVector3 {
		return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
	}
	
    static func onCircle(origin: SCNVector3, radius: Float, angle: Float) -> SCNVector3 {
        let adjustedAngle = angle + 0.5 * .pi // rotate counter-clockwise by half.PI, so that zero degree angle represents (x: 0, z: 1)
        let x = origin.x + radius * cos(adjustedAngle)
        let z = origin.z + radius * sin(adjustedAngle)
        return SCNVector3(x: x, y: origin.y,  z: z)
    }
}

public let SCNVector3One: SCNVector3 = SCNVector3(1.0, 1.0, 1.0)

func SCNVector3Uniform(_ value: Float) -> SCNVector3 {
	return SCNVector3Make(value, value, value)
}

func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
	return SCNVector3Make(Float(value), Float(value), Float(value))
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
	left = left + right
}

func -= (left: inout SCNVector3, right: SCNVector3) {
	left = left - right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func /= (left: inout SCNVector3, right: Float) {
	left = left / right
}

func *= (left: inout SCNVector3, right: Float) {
	left = left * right
}

// MARK: - SCNMaterial extensions

extension SCNMaterial {
	static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
		let material = SCNMaterial()
		material.diffuse.contents = diffuse
		material.isDoubleSided = true
		if respondsToLighting {
			material.locksAmbientWithDiffuse = true
		} else {
			material.ambient.contents = UIColor.black
			material.lightingModel = .constant
			material.emission.contents = diffuse
		}
		return material
	}
}

// MARK: - CGPoint extensions

extension CGPoint {
	init(_ size: CGSize) {
		self.init()
		self.x = size.width
		self.y = size.height
	}

	init(_ vector: SCNVector3) {
		self.init()
		self.x = CGFloat(vector.x)
		self.y = CGFloat(vector.y)
	}

	func distanceTo(_ point: CGPoint) -> CGFloat {
		return (self - point).length()
	}

	func length() -> CGFloat {
		return sqrt(self.x * self.x + self.y * self.y)
	}

	func midpoint(_ point: CGPoint) -> CGPoint {
		return (self + point) / 2
	}

	func friendlyString(_ digits: UInt = 2) -> String {
		return "(\(String(format: "%.\(digits)f", x)), \(String(format: "%.\(digits)f", y)))"
	}
    
    static func onCircle(origin: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let adjustedAngle = angle + 0.5 * .pi // rotate counter-clockwise by half.PI, so that zero degree angle represents (x: 0, y: 1)
        let x = origin.x + radius * cos(adjustedAngle)
        let y = origin.y + radius * sin(adjustedAngle)
        return CGPoint(x: x, y: y)
    }
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
	left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
	left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x * right, y: left.y * right)
}

func /= (left: inout CGPoint, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
	left = left * right
}

// MARK: - CGSize extensions

extension CGSize {
	init(_ point: CGPoint) {
		self.init()
		self.width = point.x
		self.height = point.y
	}

	func friendlyString(_ digits: UInt = 2) -> String {
		return "(\(String(format: "%.\(digits)f", width)), \(String(format: "%.\(digits)f", height)))"
	}
}

func + (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func += (left: inout CGSize, right: CGSize) {
	left = left + right
}

func -= (left: inout CGSize, right: CGSize) {
	left = left - right
}

func / (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width * right, height: left.height * right)
}

func /= (left: inout CGSize, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGSize, right: CGFloat) {
	left = left * right
}

// MARK: - Float extensions

extension Float {
	func friendlyString(_ digits: UInt = 2) -> String {
		return CGFloat(self).friendlyString(digits)
	}
}

// MARK: - Double extensions

extension Double {
	func friendlyString(_ digits: UInt = 2) -> String {
		return CGFloat(self).friendlyString(digits)
	}
}

// MARK: - CGFloat extensions

extension CGFloat {
	func friendlyString(_ digits: UInt = 2) -> String {
		return "\(String(format: "%.\(digits)f", self))"
	}
}

// MARK: - CGRect extensions

extension CGSize {
	var mid: CGPoint {
		return CGRect(origin: .zero, size: self).mid
	}
}

// MARK: - CGRect extensions

extension CGRect {
	var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {
	let direction = direction.normalized()

	// Special case handling: Check if the ray is horizontal as well.
	if direction.y == 0 {
		if rayOrigin.y == planeY {
			// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
			// Therefore we simply return the ray origin.
			return rayOrigin
		} else {
			// The ray is parallel to the plane and never intersects.
			return nil
		}
	}

	// The distance from the ray's origin to the intersection point on the plane is:
	//   (pointOnPlane - rayOrigin) dot planeNormal
	//  --------------------------------------------
	//          direction dot planeNormal

	// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
	let dist = (planeY - rayOrigin.y) / direction.y

	// Do not return intersections behind the ray's origin.
	if dist < 0 {
		return nil
	}

	// Return the intersection point.
	return rayOrigin + (direction * dist)
}

extension ARSCNView {
	struct HitTestRay {
		let origin: SCNVector3
		let direction: SCNVector3
	}

	func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {

		guard let frame = self.session.currentFrame else {
			return nil
		}

		let cameraPos = SCNVector3.positionFromTransform(frame.camera.transform)

		// Note: z: 1.0 will unproject() the screen position to the far clipping plane.
		let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1.0)
		let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)

		var rayDirection = screenPosOnFarClippingPlane - cameraPos
		rayDirection.normalize()

		return HitTestRay(origin: cameraPos, direction: rayDirection)
	}

	func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: SCNVector3) -> SCNVector3? {

		guard let ray = hitTestRayFromScreenPos(point) else {
			return nil
		}

		// Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
		if ray.direction.y > -0.03 {
			return nil
		}

		// Return the intersection of a ray from the camera through the screen position with a horizontal plane
		// at height (Y axis).
		return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
	}

	struct FeatureHitTestResult {
		let position: SCNVector3
		let distanceToRayOrigin: Float
		let featureHit: SCNVector3
		let featureDistanceToHitResult: Float
	}

	func hitTestWithFeatures(_ point: CGPoint,
							 coneOpeningAngleInDegrees: Float,
							 minDistance: Float = 0,
							 maxDistance: Float = Float.greatestFiniteMagnitude,
							 maxResults: Int = 1) -> [FeatureHitTestResult] {

		var results = [FeatureHitTestResult]()

		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return results
		}

		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}

		let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
		let maxAngle = ((maxAngleInDeg / 180) * Float.pi)

		let points = features.points

		for point in points {
			//		for i in 0...features.count {
			//
			//			let feature = points.advanced(by: Int(i))
			let featurePos = SCNVector3(point)

			let originToFeature = featurePos - ray.origin

			let crossProduct = originToFeature.cross(ray.direction)
			let featureDistanceFromResult = crossProduct.length()

			let hitTestResult = ray.origin + (ray.direction * ray.direction.dot(originToFeature))
			let hitTestResultDistance = (hitTestResult - ray.origin).length()

			if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
				// Skip this feature - it is too close or too far away.
				continue
			}

			let originToFeatureNormalized = originToFeature.normalized()
			let angleBetweenRayAndFeature = acos(ray.direction.dot(originToFeatureNormalized))

			if angleBetweenRayAndFeature > maxAngle {
				// Skip this feature - is is outside of the hit test cone.
				continue
			}

			// All tests passed: Add the hit against this feature to the results.
			results.append(FeatureHitTestResult(position: hitTestResult,
												distanceToRayOrigin: hitTestResultDistance,
												featureHit: featurePos,
												featureDistanceToHitResult: featureDistanceFromResult))
		}

		// Sort the results by feature distance to the ray.
		results = results.sorted(by: { (first, second) -> Bool in
			return first.distanceToRayOrigin < second.distanceToRayOrigin
		})

		// Cap the list to maxResults.
		var cappedResults = [FeatureHitTestResult]()
		var i = 0
		while i < maxResults && i < results.count {
			cappedResults.append(results[i])
			i += 1
		}

		return cappedResults
	}

	func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {

		var results = [FeatureHitTestResult]()

		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}

		if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
			results.append(result)
		}

		return results
	}

	func hitTestFromOrigin(origin: SCNVector3, direction: SCNVector3) -> FeatureHitTestResult? {

		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return nil
		}

		let points = features.points

		// Determine the point from the whole point cloud which is closest to the hit test ray.
		var closestFeaturePoint = origin
		var minDistance = Float.greatestFiniteMagnitude

		for point in points {
			//		for i in 0...features.count {
			//			let feature = points.advanced(by: Int(i))
			let featurePos = SCNVector3(point)

			let originVector = origin - featurePos
			let crossProduct = originVector.cross(direction)
			let featureDistanceFromResult = crossProduct.length()

			if featureDistanceFromResult < minDistance {
				closestFeaturePoint = featurePos
				minDistance = featureDistanceFromResult
			}
		}

		// Compute the point along the ray that is closest to the selected feature.
		let originToFeature = closestFeaturePoint - origin
		let hitTestResult = origin + (direction * direction.dot(originToFeature))
		let hitTestResultDistance = (hitTestResult - origin).length()

		return FeatureHitTestResult(position: hitTestResult,
									distanceToRayOrigin: hitTestResultDistance,
									featureHit: closestFeaturePoint,
									featureDistanceToHitResult: minDistance)
	}
}

// MARK: - Simple geometries

func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
	let quiverThickness = (quiverLength / 50.0) * quiverThickness
	let chamferRadius = quiverThickness / 2.0

	let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness,
							length: quiverThickness, chamferRadius: chamferRadius)
	xQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
	let xQuiverNode = SCNNode(geometry: xQuiverBox)
	xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)

	let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength,
							length: quiverThickness, chamferRadius: chamferRadius)
	yQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.green, respondsToLighting: false)]
	let yQuiverNode = SCNNode(geometry: yQuiverBox)
	yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)

	let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness,
							length: quiverLength, chamferRadius: chamferRadius)
	zQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.blue, respondsToLighting: false)]
	let zQuiverNode = SCNNode(geometry: zQuiverBox)
	zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))

	let quiverNode = SCNNode()
	quiverNode.addChildNode(xQuiverNode)
	quiverNode.addChildNode(yQuiverNode)
	quiverNode.addChildNode(zQuiverNode)
	quiverNode.name = "Axes"
	return quiverNode
}

// swiftlint:disable no_fallthrough_only
func createCrossNode(size: CGFloat = 0.01, color: UIColor = UIColor.green, horizontal: Bool = true, opacity: CGFloat = 1.0) -> SCNNode {

	// Create a size x size m plane and put a grid texture onto it.
	let planeDimension = size

	var fileName = ""
	switch color {
	case UIColor.blue:
		fileName = "crosshair_blue"
	case UIColor.yellow:
		fallthrough
	default:
		fileName = "crosshair_yellow"
	}

	let path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "Models.scnassets")!
	let image = UIImage(contentsOfFile: path)

	let planeNode = SCNNode(geometry: createSquarePlane(size: planeDimension, contents: image))
	if let material = planeNode.geometry?.firstMaterial {
		material.ambient.contents = UIColor.black
		material.lightingModel = .constant
	}

	if horizontal {
		planeNode.eulerAngles = SCNVector3Make(Float.pi / 2.0, 0, Float.pi) // Horizontal.
	} else {
		planeNode.constraints = [SCNBillboardConstraint()] // Facing the screen.
	}

	let cross = SCNNode()
	cross.addChildNode(planeNode)
	cross.opacity = opacity
	return cross
}

func createSquarePlane(size: CGFloat, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size, height: size)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}

func createPlane(size: CGSize, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size.width, height: size.height)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}

extension UIView {
	func addCornerRadius(_ radius: CGFloat? = nil) {
		layer.masksToBounds = true
		layer.cornerRadius = radius ?? min(frame.size.width, frame.size.height) / 2
	}
	
	func addBorder(color: UIColor, width: CGFloat = 1) {
		layer.borderColor = color.cgColor
		layer.borderWidth = width
	}

	func removeBorder() {
		layer.borderColor = nil
		layer.borderWidth = 0
	}
	
	var containingViewController: UIViewController? {
		if let viewController = next as? UIViewController {
			return viewController
		}
		if let view = next as? UIView {
			return view.containingViewController
		}
		return nil
	}

	// MARK: Layout
	
	enum Alignment {
		case allSides
		case allSidesSafeArea
		case leftSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case rightSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case topSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case bottomSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case left(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case right(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case top(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case bottom(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case width(CGFloat? = nil)
		case height(CGFloat? = nil)
		case center, centerX, centerY

		func constraints(for selfView: UIView, with view: UIView) -> [NSLayoutConstraint] {
			switch self {
			case .allSides:
				return [leftConstraint(for: selfView, with: view, constant: 0),
						rightConstraint(for: selfView, with: view, constant: 0),
						topConstraint(for: selfView, with: view, constant: 0),
						bottomConstraint(for: selfView, with: view, constant: 0)]
			case .allSidesSafeArea:
				return [leftConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0),
						rightConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0),
						topConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0),
						bottomConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0)]
			case .leftSafeArea(let constant, let attribute):
				return [leftConstraint(for: selfView, with: view, constant: view.safeAreaInsets.left + constant, to: attribute)]
			case .rightSafeArea(let constant, let attribute):
				return [rightConstraint(for: selfView, with: view, constant: view.safeAreaInsets.right - constant, to: attribute)]
			case .topSafeArea(let constant, let attribute):
				return [topConstraint(for: selfView, with: view, constant: view.safeAreaInsets.top + constant, to: attribute)]
			case .bottomSafeArea(let constant, let attribute):
				return [bottomConstraint(for: selfView, with: view, constant: view.safeAreaInsets.bottom - constant, to: attribute)]
			case .left(let constant, let attribute):
				return [leftConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .right(let constant, let attribute):
				return [rightConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .top(let constant, let attribute):
				return [topConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .bottom(let constant, let attribute):
				return [bottomConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .width(let constant):
				return [widthConstraint(for: selfView, with: view, constant: constant)]
			case .height(let constant):
				return [heightConstraint(for: selfView, with: view, constant: constant)]
			case .center:
				return [centerConstraint(for: selfView, with: view, attribute: .centerX), centerConstraint(for: selfView, with: view, attribute: .centerY)]
			case .centerX:
				return [centerConstraint(for: selfView, with: view, attribute: .centerX)]
			case .centerY:
				return [centerConstraint(for: selfView, with: view, attribute: .centerY)]
			}
		}

		private func leftConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			return NSLayoutConstraint(item: selfView, attribute: .left, relatedBy: .equal, toItem: item, attribute: attribute ?? .left, multiplier: 1.0, constant: constant)
		}

		private func rightConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .right, relatedBy: .equal, toItem: item, attribute: attribute ?? .right, multiplier: 1.0, constant: constant)
		}

		private func topConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .top, relatedBy: .equal, toItem: item, attribute: attribute ?? .top, multiplier: 1.0, constant: constant)
		}

		private func bottomConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .bottom, relatedBy: .equal, toItem: item, attribute: attribute ?? .bottom, multiplier: 1.0, constant: constant)
		}

		private func widthConstraint(for selfView: UIView, with item: Any, constant: CGFloat?) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .width, relatedBy: .equal, toItem: (constant == nil ? item : nil), attribute: .width, multiplier: 1.0, constant: constant ?? (item as? UIView)?.frame.size.width ?? 0)
		}

		private func heightConstraint(for selfView: UIView, with item: Any, constant: CGFloat?) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .height, relatedBy: .equal, toItem: (constant == nil ? item : nil), attribute: .height, multiplier: 1.0, constant: constant ?? (item as? UIView)?.frame.size.height ?? 0)
		}
		
		private func centerConstraint(for selfView: UIView, with item: Any, attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: attribute, relatedBy: .equal, toItem: item, attribute: attribute, multiplier: 1.0, constant: 0)
		}
	}

	func layoutConstraints(with view: UIView, to alignments: [UIView.Alignment]) -> [NSLayoutConstraint] {
		var constraints = [NSLayoutConstraint]()

		for alignment in alignments {
			constraints.append(contentsOf: alignment.constraints(for: self, with: view))
		}

		return constraints
	}
	
	func layoutConstraints(equal view: UIView) -> [NSLayoutConstraint] {
		return layoutConstraints(with: view, to: [.allSides])
	}
	
	func add(to superview: UIView, activate constraints: [NSLayoutConstraint]? = nil) {
		translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(self)
		NSLayoutConstraint.activate(constraints ?? layoutConstraints(equal: superview))
	}

	func add(to superview: UIView, constraints: [NSLayoutConstraint]? = nil, accumulator: inout [NSLayoutConstraint]) {
		translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(self)
		accumulator += constraints ?? layoutConstraints(equal: superview)
	}
}

class UIPassThroughView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Get the hit view we would normally get with a standard UIView
        let hitView = super.hitTest(point, with: event)

        // If the hit view was ourself (meaning no subview was touched),
        // return nil instead. Otherwise, return hitView, which must be a subview.
        return hitView == self ? nil : hitView
    }
}

extension UIViewController {
	func presentPopover(_ viewController: UIViewController, from sourceView: UIView, animated: Bool) {
		viewController.popoverPresentationController?.sourceView = sourceView
		viewController.popoverPresentationController?.sourceRect = sourceView.bounds
		self.present(viewController, animated: animated)
	}
	
	static var topMost: UIViewController? {
		guard var topController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
		while let presentedViewController = topController.presentedViewController {
			topController = presentedViewController
		}
		return topController
	}
}

public enum Model : String {
    case simulator   = "simulator/sandbox",
    iPod1            = "iPod 1",
    iPod2            = "iPod 2",
    iPod3            = "iPod 3",
    iPod4            = "iPod 4",
    iPod5            = "iPod 5",
    iPad2            = "iPad 2",
    iPad3            = "iPad 3",
    iPad4            = "iPad 4",
    iPhone4          = "iPhone 4",
    iPhone4S         = "iPhone 4S",
    iPhone5          = "iPhone 5",
    iPhone5S         = "iPhone 5S",
    iPhone5C         = "iPhone 5C",
    iPadMini1        = "iPad Mini 1",
    iPadMini2        = "iPad Mini 2",
    iPadMini3        = "iPad Mini 3",
    iPadAir1         = "iPad Air 1",
    iPadAir2         = "iPad Air 2",
    iPadPro9_7       = "iPad Pro 9.7\"",
    iPadPro9_7_cell  = "iPad Pro 9.7\" cellular",
    iPadPro10_5      = "iPad Pro 10.5\"",
    iPadPro10_5_cell = "iPad Pro 10.5\" cellular",
    iPadPro12_9      = "iPad Pro 12.9\"",
    iPadPro12_9_cell = "iPad Pro 12.9\" cellular",
    iPhone6          = "iPhone 6",
    iPhone6plus      = "iPhone 6 Plus",
    iPhone6S         = "iPhone 6S",
    iPhone6Splus     = "iPhone 6S Plus",
    iPhoneSE         = "iPhone SE",
    iPhone7          = "iPhone 7",
    iPhone7plus      = "iPhone 7 Plus",
    iPhone8          = "iPhone 8",
    iPhone8plus      = "iPhone 8 Plus",
    iPhoneX          = "iPhone X",
    iPhoneXS         = "iPhone XS",
    iPhoneXSmax      = "iPhone XS Max",
    iPhoneXR         = "iPhone XR",
    iPhone11         = "iPhone 11",
    iPhone11Pro      = "iPhone 11 Pro",
    iPhone11ProMax   = "iPhone 11 Pro Max",
    unrecognized     = "?unrecognized?"
}

extension UIDevice {
	static let modelMap : [ String : Model ] = [
		"i386"       : .simulator,
		"x86_64"     : .simulator,
		"iPod1,1"    : .iPod1,
		"iPod2,1"    : .iPod2,
		"iPod3,1"    : .iPod3,
		"iPod4,1"    : .iPod4,
		"iPod5,1"    : .iPod5,
		"iPad2,1"    : .iPad2,
		"iPad2,2"    : .iPad2,
		"iPad2,3"    : .iPad2,
		"iPad2,4"    : .iPad2,
		"iPad2,5"    : .iPadMini1,
		"iPad2,6"    : .iPadMini1,
		"iPad2,7"    : .iPadMini1,
		"iPhone3,1"  : .iPhone4,
		"iPhone3,2"  : .iPhone4,
		"iPhone3,3"  : .iPhone4,
		"iPhone4,1"  : .iPhone4S,
		"iPhone5,1"  : .iPhone5,
		"iPhone5,2"  : .iPhone5,
		"iPhone5,3"  : .iPhone5C,
		"iPhone5,4"  : .iPhone5C,
		"iPad3,1"    : .iPad3,
		"iPad3,2"    : .iPad3,
		"iPad3,3"    : .iPad3,
		"iPad3,4"    : .iPad4,
		"iPad3,5"    : .iPad4,
		"iPad3,6"    : .iPad4,
		"iPhone6,1"  : .iPhone5S,
		"iPhone6,2"  : .iPhone5S,
		"iPad4,1"    : .iPadAir1,
		"iPad4,2"    : .iPadAir2,
		"iPad4,4"    : .iPadMini2,
		"iPad4,5"    : .iPadMini2,
		"iPad4,6"    : .iPadMini2,
		"iPad4,7"    : .iPadMini3,
		"iPad4,8"    : .iPadMini3,
		"iPad4,9"    : .iPadMini3,
		"iPad6,3"    : .iPadPro9_7,
		"iPad6,11"   : .iPadPro9_7,
		"iPad6,4"    : .iPadPro9_7_cell,
		"iPad6,12"   : .iPadPro9_7_cell,
		"iPad6,7"    : .iPadPro12_9,
		"iPad6,8"    : .iPadPro12_9_cell,
		"iPad7,3"    : .iPadPro10_5,
		"iPad7,4"    : .iPadPro10_5_cell,
		"iPhone7,1"  : .iPhone6plus,
		"iPhone7,2"  : .iPhone6,
		"iPhone8,1"  : .iPhone6S,
		"iPhone8,2"  : .iPhone6Splus,
		"iPhone8,4"  : .iPhoneSE,
		"iPhone9,1"  : .iPhone7,
		"iPhone9,2"  : .iPhone7plus,
		"iPhone9,3"  : .iPhone7,
		"iPhone9,4"  : .iPhone7plus,
		"iPhone10,1" : .iPhone8,
		"iPhone10,2" : .iPhone8plus,
		"iPhone10,3" : .iPhoneX,
		"iPhone10,6" : .iPhoneX,
		"iPhone11,2" : .iPhoneXS,
		"iPhone11,4" : .iPhoneXSmax,
		"iPhone11,6" : .iPhoneXSmax,
		"iPhone11,8" : .iPhoneXR,
		"iPhone12,1" : .iPhone11,
		"iPhone12,3" : .iPhone11Pro,
		"iPhone12,5" : .iPhone11ProMax
	]
	
    public var modelString: String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)

            }
		}
		if let modelCode = modelCode {
			return String(validatingUTF8: modelCode)
		}
        return nil
    }
	
	public var model: Model {
		guard let modelString = modelString else { return .unrecognized }
		return UIDevice.modelMap[modelString] ?? .unrecognized
	}
	
	public var highSpecs: Bool? {
		guard let modelString = modelString else { return nil }

		let generations = ["iPhone": 12, "iPad": 6]
		
		for (category, firstHighSpecGeneration) in generations {
			if modelString.hasPrefix(category) {
				let generation = Int(modelString.components(separatedBy: category).last?.components(separatedBy: ",").first ?? "0")
				return generation ?? 0 >= firstHighSpecGeneration
			}
		}
		return nil
	}
}
