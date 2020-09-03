import UIKit
import Contentful

class PortalStoryHeaderDiamond: UIView {
	struct Constants {
		static let maxNumberOfObjects: Int = 8
		static let bigDiamondSize = CGSize(width: 140, height: 75)
		static let smallDiamondSize = CGSize(width: 30, height: 16)
		static let horizontalPadding: CGFloat = 5
		static let verticalPadding: CGFloat = 4
		static let horizontalOffsetToCenter: CGFloat = 0
		static let verticalOffsetToCenter: CGFloat = 1
		static let labelHorizontalOffsetToCenter: CGFloat = -2
		static let labelVerticalOffsetToCenter: CGFloat = -20
	}

	enum DiamondState: Equatable {
		case collected
		case uncollected
		case hidden
	}

	let portal: Portal

	// Variables
	private lazy var origin = CGPoint(x: -Constants.bigDiamondSize.width/2, y: -Constants.bigDiamondSize.height/2)
	private lazy var objectsInTotal: Int = portal.objects?.count ?? 0
	private var totalHeight: CGFloat {
		if objectsInTotal <= 2 {
			return Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height
		} else if objectsInTotal <= 5 {
			return Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height*2
		} else if objectsInTotal <= 7 {
			return Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height*3
		} else {
			return Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height*4
		}
	}

	// Parameters
	private lazy var bigDiamondParams: [(CGColor?, CGColor?, CGFloat)] = [
		(UIColor.dark90Branded.cgColor, UIColor.dark80Branded.cgColor, 2),
		(nil, portal.story?.color.cgColor, 2)
	]
	private lazy var smallDiamondParamsFilled: [(CGColor?, CGColor?, CGFloat)] = [
		(portal.story?.color.cgColor, portal.story?.color.cgColor, 2)
	]
	private lazy var smallDiamondParamsOutlined: [(CGColor?, CGColor?, CGFloat)] = [
		(UIColor.dark90Branded.cgColor, UIColor.dark80Branded.cgColor, 2),
		(nil, portal.story?.color.cgColor, 2)
	]

	// Layout
	private var layout = [DiamondState]()

	init(for portal: Portal) {
		self.portal = portal
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		layout = getFinalLayout()

		addBigDiamond()
		addSmallDiamonds()

		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: totalHeight)
		])
	}

	// Helper
	private func getFinalLayout() -> [DiamondState] {
		let originalLayout = getOriginalLayout(for: objectsInTotal)
		let numberOfCollectedObjects = portal.numberOfCollectedObjects

		var finalLayout = [DiamondState]()

		var count: Int = 0

		for state in originalLayout {
			if state == .uncollected && count < numberOfCollectedObjects {
				finalLayout.append(.collected)
				count += 1
			} else {
				finalLayout.append(state)
			}
		}

		return finalLayout
	}

	private func getOriginalLayout(for inTotal: Int) -> [DiamondState]  {
		switch inTotal {
		case 0:
			return [.hidden, .hidden,
					.hidden, .hidden, .hidden,
					.hidden, .hidden,
					.hidden]
		case 1:
			return [.hidden, .hidden,
					.hidden, .uncollected, .hidden,
					.hidden, .hidden,
					.hidden]
		case 2:
			return [.uncollected, .uncollected,
					.hidden, .hidden, .hidden,
					.hidden, .hidden,
					.hidden]
		case 3:
			return [.uncollected, .uncollected,
					.hidden, .uncollected, .hidden,
					.hidden, .hidden,
					.hidden]
		case 4:
			return [.uncollected, .uncollected,
					.hidden, .hidden, .hidden,
					.uncollected, .uncollected,
					.hidden]
		case 5:
			return [.uncollected, .uncollected,
					.hidden, .uncollected, .hidden,
					.uncollected, .uncollected,
					.hidden]
		case 6:
			return [.uncollected, .uncollected,
					.uncollected, .hidden, .uncollected,
					.uncollected, .uncollected,
					.hidden]
		case 7:
			return [.uncollected, .uncollected,
					.uncollected, .uncollected, .uncollected,
					.uncollected, .uncollected,
					.hidden]
		case 8:
			return [.uncollected, .uncollected,
					.uncollected, .uncollected, .uncollected,
					.uncollected, .uncollected,
					.uncollected]
		default:
			return []
		}
	}

	private func addBigDiamond() {
		let origin = CGPoint(x: -Constants.bigDiamondSize.width/2 + Constants.horizontalOffsetToCenter,
							 y: -Constants.bigDiamondSize.height/2 + Constants.verticalOffsetToCenter)

		for (fillColor, strokeColor, borderWidth) in bigDiamondParams {
			let diamond = CAShapeLayer.diamondShape(bounds: CGRect(origin: origin, size: Constants.bigDiamondSize))
			diamond.fillColor = fillColor
			diamond.strokeColor = strokeColor
			diamond.lineWidth = borderWidth
			diamond.lineJoin = CAShapeLayerLineJoin.miter
			layer.addSublayer(diamond)
		}

		let indexLabel = UILabel.label(for: .portalHeaderNumberCollection(portal), text: String(portal.numberInStory), alignment: .center)
		add(indexLabel, activate: [
			indexLabel.centerXAnchor.constraint(equalTo: centerXAnchor,
												constant: Constants.labelHorizontalOffsetToCenter),
			indexLabel.topAnchor.constraint(equalTo: topAnchor,
												constant: Constants.labelVerticalOffsetToCenter)
		])
		bringSubviewToFront(indexLabel)
	}

	private func addSmallDiamonds() {
		let origin = CGPoint(x: -Constants.smallDiamondSize.width/2 + Constants.horizontalOffsetToCenter,
							 y: -Constants.smallDiamondSize.height/2 + Constants.verticalOffsetToCenter)

		if let state0 = layout[safe: 0],
			let state1 = layout[safe: 1],
			let state2 = layout[safe: 2],
			let state3 = layout[safe: 3],
			let state4 = layout[safe: 4],
			let state5 = layout[safe: 5],
			let state6 = layout[safe: 6],
			let state7 = layout[safe: 7]
		{
			// First row from left to right
			if state0 != .hidden {
				let horizontalOffset = Constants.smallDiamondSize.width/2 + Constants.horizontalPadding
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.verticalPadding
				let diamondOrigin = CGPoint(x: origin.x - horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state0)
			}
			if state1 != .hidden {
				let horizontalOffset = Constants.smallDiamondSize.width/2 + Constants.horizontalPadding
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.verticalPadding
				let diamondOrigin = CGPoint(x: origin.x + horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state1)
			}

			// Second row from left to right
			if state2 != .hidden {
				let horizontalOffset = Constants.smallDiamondSize.width + Constants.horizontalPadding*2
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height/2 + Constants.verticalPadding*2
				let diamondOrigin = CGPoint(x: origin.x - horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state2)
			}
			if state3 != .hidden {
				let horizontalOffset: CGFloat = 0
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height/2 + Constants.verticalPadding*2
				let diamondOrigin = CGPoint(x: origin.x + horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state3)
			}
			if state4 != .hidden {
				let horizontalOffset = Constants.smallDiamondSize.width + Constants.horizontalPadding*2
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height/2 + Constants.verticalPadding*2
				let diamondOrigin = CGPoint(x: origin.x + horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state4)
			}

			// Third row from left to right
			if state5 != .hidden {
				let horizontalOffset = Constants.smallDiamondSize.width/2 + Constants.horizontalPadding
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height + Constants.verticalPadding*3
				let diamondOrigin = CGPoint(x: origin.x - horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state5)
			}
			if state6 != .hidden {
				let horizontalOffset = Constants.smallDiamondSize.width/2 + Constants.horizontalPadding
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height + Constants.verticalPadding*3
				let diamondOrigin = CGPoint(x: origin.x + horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state6)
			}

			// Fourth row center
			if state7 != .hidden {
				let horizontalOffset: CGFloat = 0
				let verticalOffset = Constants.bigDiamondSize.height/2 + Constants.smallDiamondSize.height*1.5 + Constants.verticalPadding*4
				let diamondOrigin = CGPoint(x: origin.x + horizontalOffset,
											y: origin.y + verticalOffset)
				addSmallDiamond(at: diamondOrigin, state: state7)
			}
		}
	}

	private func addSmallDiamond(at origin: CGPoint, state: DiamondState) {
		let params = state == .collected ? smallDiamondParamsFilled : smallDiamondParamsOutlined

		for (fillColor, strokeColor, lineWidth) in params {
			let diamond = CAShapeLayer.diamondShape(bounds: CGRect(origin: origin, size: Constants.smallDiamondSize))
			diamond.fillColor = fillColor
			diamond.strokeColor = strokeColor
			diamond.lineWidth = lineWidth
			diamond.lineJoin = CAShapeLayerLineJoin.miter
			layer.addSublayer(diamond)
		}
	}
}
