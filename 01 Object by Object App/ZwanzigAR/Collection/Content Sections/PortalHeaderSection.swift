import UIKit

class PortalHeaderSection: UIView {
	private let portal: Portal

	private lazy var color = portal.story?.color ?? UIColor.yellowBranded

	init(_ portal: Portal) {
		self.portal = portal
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
		separator.backgroundColor = color
		separator.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separator)

		let diamond = PortalStoryHeaderDiamond(for: portal)
		diamond.translatesAutoresizingMaskIntoConstraints = false
		addSubview(diamond)

		let separatorLeft = UIView()
		separatorLeft.backgroundColor = color
		separatorLeft.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separatorLeft)

		let arrowHead = ArrowHeadIllustration(color: color)
		arrowHead.translatesAutoresizingMaskIntoConstraints = false
		addSubview(arrowHead)

		NSLayoutConstraint.activate([
			separator.heightAnchor.constraint(equalToConstant: 2),
			separator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/2),
			separator.centerYAnchor.constraint(equalTo: topAnchor),
			separator.rightAnchor.constraint(equalTo: rightAnchor),

			diamond.centerXAnchor.constraint(equalTo: centerXAnchor),
			diamond.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
			diamond.bottomAnchor.constraint(equalTo: bottomAnchor),

			separatorLeft.heightAnchor.constraint(equalToConstant: 2),
			separatorLeft.centerYAnchor.constraint(equalTo: topAnchor),
			separatorLeft.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 2/8),
			separatorLeft.leftAnchor.constraint(equalTo: leftAnchor),

			arrowHead.centerYAnchor.constraint(equalTo: topAnchor),
			arrowHead.centerXAnchor.constraint(equalTo: separatorLeft.rightAnchor)
		])
	}
}
