import UIKit

class PortalHeaderSectionEmpty: UIView {
	struct Constants {
		static let paddingViewHeight: CGFloat = 64
	}

	let storyColor: UIColor

	init(storyColor: UIColor) {
		self.storyColor = storyColor
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		clipsToBounds = false
		backgroundColor = .dark90Branded
		layer.zPosition = .greatestFiniteMagnitude

		let separator = UIView()
		separator.backgroundColor = storyColor
		separator.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separator)

		let bottomPaddingView = UIView()
		bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bottomPaddingView)

		let arrowHead = ArrowHeadIllustration(color: storyColor)
		arrowHead.translatesAutoresizingMaskIntoConstraints = false
		addSubview(arrowHead)

		let illustration = BigDiamondIllustration(fillColor: .dark90Branded,
												  strokeColor: .grey70Branded,
												  text: "?")
		illustration.translatesAutoresizingMaskIntoConstraints = false
		addSubview(illustration)

		NSLayoutConstraint.activate([
			separator.heightAnchor.constraint(equalToConstant: 2),
			separator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/4),
			separator.topAnchor.constraint(equalTo: topAnchor),
			separator.leftAnchor.constraint(equalTo: leftAnchor),

			bottomPaddingView.topAnchor.constraint(equalTo: separator.bottomAnchor),
			bottomPaddingView.centerXAnchor.constraint(equalTo: centerXAnchor),
			bottomPaddingView.widthAnchor.constraint(equalTo: widthAnchor),
			bottomPaddingView.heightAnchor.constraint(equalToConstant: Constants.paddingViewHeight),
			bottomPaddingView.bottomAnchor.constraint(equalTo: bottomAnchor),

			arrowHead.centerYAnchor.constraint(equalTo: separator.centerYAnchor),
			arrowHead.leftAnchor.constraint(equalTo: separator.rightAnchor),

			illustration.centerXAnchor.constraint(equalTo: centerXAnchor),
			illustration.centerYAnchor.constraint(equalTo: separator.centerYAnchor),
		])
	}
}
