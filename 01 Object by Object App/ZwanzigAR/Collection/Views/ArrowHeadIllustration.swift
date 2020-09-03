import UIKit

class ArrowHeadIllustration: UIView {
	struct Constants {
		static let origin = CGPoint(x: -size.width, y: -size.height/2)
		static let size = CGSize(width: 10, height: 20)
		static let lineWidth: CGFloat = 2
	}

	private let color: UIColor

	init(color: UIColor) {
		self.color = color
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		let illustration = CAShapeLayer.arrowHead(bounds: CGRect(origin: Constants.origin,
																 size: Constants.size))
		illustration.fillColor = nil
		illustration.strokeColor = color.cgColor
		illustration.lineWidth = Constants.lineWidth
		illustration.lineJoin = CAShapeLayerLineJoin.miter
		layer.addSublayer(illustration)
	}
}
