import UIKit

class BigDiamondIllustration: UIView {
	struct Constants {
		static let origin = CGPoint(x: -size.width/2, y: -size.height/2)
		static let size = CGSize(width: 140, height: 75)
		static let lineWidth: CGFloat = 2
		static let labelHorizontalOffsetToCenter: CGFloat = -2
		static let labelVerticalOffsetToCenter: CGFloat = -20
	}

	private let fillColor: UIColor
	private let strokeColor: UIColor
	private let text: String

	init(fillColor: UIColor, strokeColor: UIColor, text: String) {
		self.fillColor = fillColor
		self.strokeColor = strokeColor
		self.text = text
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		let diamond = CAShapeLayer.diamondShape(bounds: CGRect(origin: Constants.origin,
															   size: Constants.size))
		diamond.fillColor = fillColor.cgColor
		diamond.strokeColor = strokeColor.cgColor
		diamond.lineWidth = Constants.lineWidth
		diamond.lineJoin = CAShapeLayerLineJoin.miter
		layer.addSublayer(diamond)

		let indexLabel = UILabel.label(for: .portalHeaderNumberCollection(nil),
									   text: text,
									   alignment: .center,
									   color: strokeColor)
		add(indexLabel, activate: [
			indexLabel.centerXAnchor.constraint(equalTo: centerXAnchor,
												constant: Constants.labelHorizontalOffsetToCenter),
			indexLabel.topAnchor.constraint(equalTo: topAnchor,
												constant: Constants.labelVerticalOffsetToCenter)
		])
		bringSubviewToFront(indexLabel)
	}
}
