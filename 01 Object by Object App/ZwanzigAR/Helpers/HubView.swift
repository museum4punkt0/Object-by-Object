import UIKit

enum HubCenterViewLayout {
	case hidden
	case normal
	case extended
	case extendedWithAchievement
}

struct HubViewBlueprint {
	let centerViewLayout: HubCenterViewLayout
	let centerViewTopElement: HubCenterElementView.ElementType?
	let centerViewBottomElement: HubCenterElementView.ElementType?

	let topLeftButtonStyle: DiamondButton.ButtonType
	let bottomLeftButtonStyle: DiamondButton.ButtonType
	let topRightButtonStyle: DiamondButton.ButtonType
	let bottomRightButtonStyle: DiamondButton.ButtonType

	let topLeftButtonAction: () -> Void
	let bottomLeftButtonAction: () -> Void
	let topRightButtonAction: () -> Void
	let bottomRightButtonAction: () -> Void
}

class CenterHubView: UIView {
	struct Constants {
		static let centerHubEdgeTipWidth: CGFloat = 54
		static let centerHubHorizontalPadding: CGFloat = 10
		static let achievementWidth: CGFloat = 317
		static let achievementHeight: CGFloat = 78
		static let achivementHorizontalOffset: CGFloat = 10
		static let achievementVerticalOffset: CGFloat = -2
	}

	private let layout: HubCenterViewLayout

	private var achievement: UIImageView?

	private var paddingLeft: CGFloat {
		switch layout {
		case .extendedWithAchievement, .extended:
			return 0
		default:
			return Constants.centerHubHorizontalPadding
		}
	}

	init(_ layout: HubCenterViewLayout) {
		self.layout = layout
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		let leftEdge = UIImageView(image: UIImage(named: "hub-center-left"))
		add(leftEdge, activate: [
			leftEdge.leftAnchor.constraint(equalTo: leftAnchor, constant: paddingLeft),
			leftEdge.widthAnchor.constraint(equalToConstant: Constants.centerHubEdgeTipWidth),
			leftEdge.topAnchor.constraint(equalTo: topAnchor),
			leftEdge.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		let rightEdge = UIImageView(image: UIImage(named: "hub-center-right"))
		add(rightEdge, activate: [
			rightEdge.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.centerHubHorizontalPadding),
			rightEdge.widthAnchor.constraint(equalToConstant: Constants.centerHubEdgeTipWidth),
			rightEdge.topAnchor.constraint(equalTo: topAnchor),
			rightEdge.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		let center = UIImageView(image: UIImage(named: "hub-center-center"))
		add(center, activate: [
			center.leftAnchor.constraint(equalTo: leftEdge.rightAnchor),
			center.rightAnchor.constraint(equalTo: rightEdge.leftAnchor),
			center.topAnchor.constraint(equalTo: topAnchor),
			center.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		if layout == .extendedWithAchievement {
			achievement = UIImageView(image: UIImage(named: "img_center-hub_achievement"))

			guard let achievement = achievement else { return }

			add(achievement, activate: [
				achievement.leftAnchor.constraint(equalTo: leftEdge.leftAnchor, constant: Constants.achivementHorizontalOffset),
				achievement.centerYAnchor.constraint(equalTo: leftEdge.centerYAnchor, constant: Constants.achievementVerticalOffset),
				achievement.heightAnchor.constraint(equalToConstant: Constants.achievementHeight),
				achievement.widthAnchor.constraint(equalToConstant: Constants.achievementWidth)
			])
		}
	}

	public func downgrade() {
		self.achievement?.isHidden = true
	}
}

class HubView: UIPassThroughView {
	struct Constants {
		static let totalHeight: CGFloat = 130
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 16
		static let topPaddingHidden: CGFloat = -120
		static let horizontalPadding: CGFloat = 16
		static let centerHubMaximumWidth: CGFloat = 480
		static let centerHubVerticalPadding: CGFloat = 10
		static let centerHubElementsVerticalPadding: CGFloat = 8
		static let diamondButtonInnerHorizontalPadding: CGFloat = 12
		static let diamondButtonInnerVerticalPadding: CGFloat = 10
	}
	
	enum ButtonPosition {
		case topLeft, topRight, bottomLeft, bottomRight
	}
	
	private let blueprint: HubViewBlueprint

	private let emptyAction: () -> Void = {}
	private var centerViewElementsContainerView = UIView()

	private lazy var centerHubView: CenterHubView = CenterHubView(blueprint.centerViewLayout)
	private lazy var centerViewTopElement = HubCenterElementView(blueprint.centerViewTopElement ?? .none)
	private lazy var centerViewBottomElement = HubCenterElementView(blueprint.centerViewBottomElement ?? .none)

	private lazy var topLeftButton = DiamondButton(blueprint.topLeftButtonStyle,
												   action: blueprint.topLeftButtonAction)
	private lazy var topRightButton = DiamondButton(blueprint.topRightButtonStyle,
													action: blueprint.topRightButtonAction)
	private lazy var bottomLeftButton = DiamondButton(blueprint.bottomLeftButtonStyle,
													  action: blueprint.bottomLeftButtonAction)
	private lazy var bottomRightButton = DiamondButton(blueprint.bottomRightButtonStyle,
													   action: blueprint.bottomRightButtonAction)

	init(blueprint: HubViewBlueprint) {
		self.blueprint = blueprint
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true

//		let centerHubImage = UIImage(named: "hub-center")!
//		centerHubImage.resizableImage(withCapInsets: UIEdgeInsets(top: 40, left: 100, bottom: 40, right: 100)) // not actual numbers
//		centerHubView = UIImageView(image: centerHubImage)
		centerHubView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(centerHubView)
		centerHubView.isHidden = blueprint.centerViewLayout == .hidden

		centerViewElementsContainerView.translatesAutoresizingMaskIntoConstraints = false
		centerHubView.addSubview(centerViewElementsContainerView)

		centerViewTopElement.translatesAutoresizingMaskIntoConstraints = false
		centerViewElementsContainerView.addSubview(centerViewTopElement)

		centerViewBottomElement.translatesAutoresizingMaskIntoConstraints = false
		centerViewElementsContainerView.addSubview(centerViewBottomElement)

		topLeftButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topLeftButton)
		topLeftButton.isHidden = topLeftButton.buttonType == .hidden

		topRightButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topRightButton)
		topRightButton.isHidden = topRightButton.buttonType == .hidden

		bottomLeftButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bottomLeftButton)
		bottomLeftButton.isHidden = bottomLeftButton.buttonType == .hidden

		bottomRightButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bottomRightButton)
		bottomRightButton.isHidden = bottomRightButton.buttonType == .hidden

		let centerHubWidthAnchor = centerHubView.widthAnchor.constraint(equalTo: widthAnchor)
		centerHubWidthAnchor.priority = .defaultHigh
		let centerHubMaxWidthAnchor = centerHubView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.centerHubMaximumWidth)
		centerHubMaxWidthAnchor.priority = .required
		
		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: Constants.totalHeight),

			centerHubWidthAnchor, centerHubMaxWidthAnchor,

			centerHubView.centerXAnchor.constraint(equalTo: centerXAnchor),
			centerHubView.topAnchor.constraint(equalTo: topAnchor, constant: -Constants.centerHubVerticalPadding),

			centerViewElementsContainerView.centerXAnchor.constraint(equalTo: centerHubView.centerXAnchor),
			centerViewElementsContainerView.centerYAnchor.constraint(equalTo: centerHubView.centerYAnchor),
			centerViewElementsContainerView.topAnchor.constraint(equalTo: centerViewTopElement.topAnchor),
			centerViewElementsContainerView.bottomAnchor.constraint(equalTo: centerViewBottomElement.bottomAnchor),
			centerViewElementsContainerView.widthAnchor.constraint(equalToConstant: 160),

			centerViewTopElement.centerXAnchor.constraint(equalTo: centerViewElementsContainerView.centerXAnchor),
			centerViewTopElement.topAnchor.constraint(equalTo: centerViewElementsContainerView.topAnchor),

			centerViewBottomElement.centerXAnchor.constraint(equalTo: centerViewElementsContainerView.centerXAnchor),
			centerViewBottomElement.topAnchor.constraint(equalTo: centerViewTopElement.bottomAnchor, constant: Constants.centerHubElementsVerticalPadding),

			topLeftButton.leftAnchor.constraint(equalTo: leftAnchor, constant: -Constants.diamondButtonInnerHorizontalPadding),
			topLeftButton.centerYAnchor.constraint(equalTo: centerHubView.centerYAnchor),

			topRightButton.rightAnchor.constraint(equalTo: rightAnchor, constant: Constants.diamondButtonInnerHorizontalPadding),
			topRightButton.centerYAnchor.constraint(equalTo: centerHubView.centerYAnchor),

			bottomLeftButton.centerXAnchor.constraint(equalTo: topLeftButton.centerXAnchor),
			bottomLeftButton.topAnchor.constraint(equalTo: topLeftButton.bottomAnchor, constant: -Constants.diamondButtonInnerVerticalPadding * 2),

			bottomRightButton.centerXAnchor.constraint(equalTo: topRightButton.centerXAnchor),
			bottomRightButton.topAnchor.constraint(equalTo: topRightButton.bottomAnchor, constant: -Constants.diamondButtonInnerVerticalPadding * 2)
		])
	}

	// MARK: Update Content Helpers

	public func updateContent(elementType: HubCenterElementView.ElementType) {
		if centerViewTopElement.elementType == elementType {
			centerViewTopElement.updateContent(elementType: elementType)
		} else if centerViewBottomElement.elementType == elementType {
			centerViewBottomElement.updateContent(elementType: elementType)
		}
	}
	
	public func setButton(position: ButtonPosition, type: DiamondButton.ButtonType, action: @escaping () -> Void) {
		var buttonToSet: DiamondButton?

		switch position {
		case .topLeft: buttonToSet = topLeftButton
		case .topRight: buttonToSet = topRightButton
		case .bottomLeft: buttonToSet = bottomLeftButton
		case .bottomRight: buttonToSet = bottomRightButton
		}
		buttonToSet?.update(to: type, action: action)
	}

	public func downgradeNavigationObject() {
		centerHubView.downgrade()
	}
}
