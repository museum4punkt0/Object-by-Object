import UIKit

class DiamondButton: UIView {
	enum ButtonType: Equatable {
		case hidden
		case close
		case tourSelection
		case next
		case back
		case intro
		case about
		case restart
		case collection
		case currentLocation
		case boardOverview(Bool)
		case augmentedReality
		case pharusPin
		case share
		case hint

		var icon: UIImage? {
			switch self {
			case .share:
				return UIImage(named: "icon_share")
			case .hint:
				return UIImage(named: "icon_lightbulb")
			case .pharusPin:
				return UIImage(named: "icon_pharus_pin")
			case .augmentedReality:
				return UIImage(named: "icon_arkit_light")
			case .close:
				return UIImage(named: "icon_close")
			case .tourSelection:
				return UIImage(named: "icon_tour-selection")
			case .next:
				return UIImage(named: "icon_next")
			case .back:
				return UIImage(named: "icon_back")
			case .intro:
				return UIImage(named: "icon_intro")
			case .about:
				return UIImage(named: "icon_about")
			case .restart:
				return UIImage(named: "icon_next")
			case .collection:
				return UIImage(named: "icon_collection")
			case .currentLocation:
				return UIImage(named: "icon_current-location")
			case .boardOverview(let isBoardFilled):
				if isBoardFilled {
					return UIImage(named: "icon_board-overview_active")
				} else {
					return UIImage(named: "icon_board-overview_inactive")
				}
			case .hidden:
				return nil
			}
		}

		var alignmentCorrection: CGSize {
			switch self {
			case .augmentedReality:
				return CGSize(width: 0, height: -1)
			case .currentLocation:
				return CGSize(width: 0, height: -2)
			case .boardOverview:
				return CGSize(width: 0, height: -2)
			default:
				return CGSize(width: 0, height: 0)
			}
		}

		var backgroundImage: UIImage {
			return UIImage(named: "diamond-button_bg")!
		}
	}

	public var buttonType: ButtonType
	private var action: (() -> Void)

	private lazy var background = UIImageView(image: buttonType.backgroundImage)
	private var icon: UIImageView

	init(_ buttonType: ButtonType, action: @escaping (() -> Void)) {
		self.buttonType = buttonType
		self.icon = UIImageView(image: buttonType.icon)
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

			icon.centerXAnchor.constraint(equalTo: background.centerXAnchor, constant: buttonType.alignmentCorrection.width),
			icon.centerYAnchor.constraint(equalTo: background.centerYAnchor, constant: buttonType.alignmentCorrection.height),
		])
	}

	// MARK: Interaction

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()
		action()
	}

	// MARK: Helpers

	public func update(to buttonType: ButtonType, action: @escaping (() -> Void)) {
		self.buttonType = buttonType
		icon.image = buttonType.icon
		self.action = action
		isHidden = buttonType == .hidden
	}
}
