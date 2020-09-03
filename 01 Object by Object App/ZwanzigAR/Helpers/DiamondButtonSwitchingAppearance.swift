import UIKit

class DiamondButtonSwitchingAppearance: UIView {
	enum Style: Equatable {
		case audioOn
		case audioOff

		var icon: UIImage? {
			switch self {
			case .audioOn:
				return UIImage(named: "icon_audio_play")
			case .audioOff:
				return UIImage(named: "icon_audio_stop")
			}
		}

		var alignmentCorrection: CGSize {
			switch self {
			case .audioOn:
				return CGSize(width: 0, height: -2)
			case .audioOff:
				return CGSize(width: 0, height: 0)
			}
		}

		var backgroundImage: UIImage {
			return UIImage(named: "diamond-button_bg")!
		}
	}

	public var style: Style
	private var action: ((Bool) -> Void)

	private lazy var background = UIImageView(image: style.backgroundImage)
	private lazy var icon = UIImageView(image: style.icon)

	init(_ style: Style, action: @escaping ((Bool) -> Void)) {
		self.style = style
		self.action = action
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true

		background.translatesAutoresizingMaskIntoConstraints = false
		addSubview(background)

		icon.translatesAutoresizingMaskIntoConstraints = false
		addSubview(icon)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalTo: background.widthAnchor),
			heightAnchor.constraint(equalTo: background.heightAnchor),

			background.centerXAnchor.constraint(equalTo: centerXAnchor),
			background.centerYAnchor.constraint(equalTo: centerYAnchor),

			icon.centerXAnchor.constraint(equalTo: background.centerXAnchor, constant: style.alignmentCorrection.width),
			icon.centerYAnchor.constraint(equalTo: background.centerYAnchor, constant: style.alignmentCorrection.height),
		])
	}

	// MARK: Interaction

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()

		switch style {
		case .audioOn:
			action(true)
			update(to: .audioOff)
		case .audioOff:
			action(false)
			update(to: .audioOn)
		}
	}

	// MARK: Helpers

	private func update(to newStyle: Style) {
		style = newStyle
		background.image = newStyle.backgroundImage
		icon.image = newStyle.icon
	}
}
