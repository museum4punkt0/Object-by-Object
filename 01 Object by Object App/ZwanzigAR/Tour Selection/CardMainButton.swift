import UIKit

class CardMainButton: UIButton {
	static let buttonHeight: CGFloat = 64.0

	struct Constants {
		static let horizontalPadding: CGFloat = 8
		static let verticalPaddingInside: CGFloat = 16
	}

	enum Style {
		case startTour
		case selectTour
		case normal(String)

		var backgroundColor: UIColor {
			switch self {
			case .normal:
				return .dark90Branded
			case .startTour, .selectTour:
				return .champagneBranded
			}
		}

		var textColor: UIColor {
			switch self {
			case .normal(_):
				return .champagneBranded
			case .startTour, .selectTour:
				return .dark80Branded
			}

		}

		var title: String {
			switch self {
			case .normal(let title):
				return title
			case .startTour:
				return "Zeitreise starten"
			case .selectTour:
				return "Zeitreise fortsetzen"
			}
		}

		var icon: UIImage? {
			switch self {
			case .startTour:
				return UIImage(named: "icon_arkit")
			default:
				return nil
			}
		}

		var verticalIconCorrection: CGFloat {
			switch self {
			case .startTour:
				return -3
			default:
				return 0
			}
		}

		var labelStyle: UILabel.Style {
			switch self {
			case .normal(_):
				return .buttonDark
			case .startTour, .selectTour:
				return .buttonLight
			}
		}

		var alignment: NSTextAlignment {
			return icon != nil ? .center : .left
		}
	}

	private let style: Style
	private let action: (() -> Void)
	private let buttonLabelContainer = UIView()
	private lazy var iconView: UIImageView? = style.icon != nil ? UIImageView(image: style.icon) : nil
	private lazy var buttonLabel = UILabel.label(for: style.labelStyle,
												 text: style.title,
												 alignment: style.alignment,
												 color: style.textColor)

	init(state: Story.State, selectAction: @escaping (() -> Void)) {
		self.style = state == Story.State.notStarted ? .startTour : .selectTour
		self.action = selectAction
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true

		backgroundColor = style.backgroundColor

		buttonLabelContainer.translatesAutoresizingMaskIntoConstraints = false
		addSubview(buttonLabelContainer)

		buttonLabel.translatesAutoresizingMaskIntoConstraints = false
		buttonLabelContainer.addSubview(buttonLabel)

		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: CardMainButton.buttonHeight),
			buttonLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

			buttonLabelContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
			buttonLabelContainer.centerYAnchor.constraint(equalTo: centerYAnchor)
		])

		let textWidth: CGFloat = buttonLabel.attributedText?.width(withConstrainedHeight: CardMainButton.buttonHeight - Constants.verticalPaddingInside*2) ?? 0
		let iconWidth: CGFloat = iconView?.image?.size.width ?? 0

		if let iconView = iconView {
			iconView.translatesAutoresizingMaskIntoConstraints = false
			buttonLabelContainer.addSubview(iconView)

			NSLayoutConstraint.activate([
				iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: style.verticalIconCorrection),
				buttonLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: Constants.horizontalPadding),
				buttonLabelContainer.widthAnchor.constraint(equalToConstant: iconWidth + Constants.horizontalPadding + textWidth)
			])
		} else {
			NSLayoutConstraint.activate([
				buttonLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
				buttonLabelContainer.widthAnchor.constraint(equalToConstant: textWidth)
			])
		}

	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()

		action()
	}
}
