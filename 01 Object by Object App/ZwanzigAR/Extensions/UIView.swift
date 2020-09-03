import UIKit

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
}
