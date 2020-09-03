import UIKit

class SessionProgressView: UIView {
	// NOTE: SessionProgressView is only built to support up to 8 objects to be collected

	struct Constants {
		static let horizontalOffset: CGFloat = 14
		static let verticalCorrection: CGFloat = 0
		static let firstRowVerticalCorrection: CGFloat = 4
		static let secondRowVerticalCorrection: CGFloat = 7
		static let secondRowHorizontalCorrection: CGFloat = 4
		static let thirdRowVerticalCorrection: CGFloat = 7
		static let fourthRowVerticalCorrection: CGFloat = 8
	}

	enum State {
		case collected
		case uncollected
		case hidden
	}

	enum Resource {
		case portalStory(Bool)
		case object(Bool)

		var image: UIImage? {
			switch self {
			case .portalStory(let isCollected):
				return isCollected ? UIImage(named: "img_session-progress_big_active") : UIImage(named: "img_session-progress_big_inactive")
			case .object(let isCollected):
				return isCollected ? UIImage(named: "img_session-progress_small_active") : UIImage(named: "img_session-progress_small_inactive")
			}
		}
	}

	private let portalNumber: Int
	private let objectsInTotal: Int
	private var objectsCollected: Int
	private let isPortalStoryCollected: Bool

	// Views
	private lazy var portalStoryIndicatorView = UIImageView(image: Resource.portalStory(isPortalStoryCollected).image)
	private lazy var portalStoryIndicatorLabel = UILabel.label(for: .sessionProgressNumber, text: "\(portalNumber)", alignment: .center, color: isPortalStoryCollected ? .lightGoldBranded : .grey80Branded)
	private var objectIndicatorViews = [UIImageView]()

	// Layout
	private var originalLayout: [State] {
		if objectsInTotal == 0 {
			return [.hidden, .hidden,
					.hidden, .hidden, .hidden,
					.hidden, .hidden,
					.hidden]
		} else if objectsInTotal == 1 {
			return [.hidden, .hidden,
					.hidden, .uncollected, .hidden,
					.hidden, .hidden,
					.hidden]
		} else if objectsInTotal == 2 {
			return [.uncollected, .uncollected,
					.hidden, .hidden, .hidden,
					.hidden, .hidden,
					.hidden]
		} else if objectsInTotal == 3 {
			return [.uncollected, .uncollected,
					.hidden, .uncollected, .hidden,
					.hidden, .hidden,
					.hidden]
		} else if objectsInTotal == 4 {
			return [.uncollected, .uncollected,
					.hidden, .hidden, .hidden,
					.uncollected, .uncollected,
					.hidden]
		} else if objectsInTotal == 5 {
			return [.uncollected, .uncollected,
					.hidden, .uncollected, .hidden,
					.uncollected, .uncollected,
					.hidden]
		} else if objectsInTotal == 6 {
			return [.uncollected, .uncollected,
					.uncollected, .hidden, .uncollected,
					.uncollected, .uncollected,
					.hidden]
		} else if objectsInTotal == 7 {
			return [.uncollected, .uncollected,
					.uncollected, .uncollected, .uncollected,
					.uncollected, .uncollected,
					.hidden]
		} else if objectsInTotal == 8 {
			return [.uncollected, .uncollected,
					.uncollected, .uncollected, .uncollected,
					.uncollected, .uncollected,
					.uncollected]
		} else {
			return []
		}
	}

	// Values
	private let maxNumberOfObjects: Int = 8

	init(portalNumber: Int, objectsInTotal: Int, objectsCollected: Int, isPortalStoryCollected: Bool) {
		self.portalNumber = portalNumber
		self.objectsInTotal = objectsInTotal
		self.objectsCollected = objectsCollected
		self.isPortalStoryCollected = isPortalStoryCollected
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		var constraints = [NSLayoutConstraint]()

		// Portal Story Indicators
		add(portalStoryIndicatorView, constraints: [
			widthAnchor.constraint(equalTo: portalStoryIndicatorView.widthAnchor),

			portalStoryIndicatorView.topAnchor.constraint(equalTo: topAnchor),
			portalStoryIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor)
		], accumulator: &constraints)

		add(portalStoryIndicatorLabel, constraints: [
			portalStoryIndicatorLabel.centerXAnchor.constraint(equalTo: portalStoryIndicatorView.centerXAnchor),
			portalStoryIndicatorLabel.centerYAnchor.constraint(equalTo: portalStoryIndicatorView.centerYAnchor)
		], accumulator: &constraints)

		// Object Indicators
		for _ in 1...maxNumberOfObjects {
			let image = Resource.object(false).image
			objectIndicatorViews.append(UIImageView(image: image))
		}

		if let view0 = objectIndicatorViews[safe: 0],
			let view1 = objectIndicatorViews[safe: 1],
			let view2 = objectIndicatorViews[safe: 2],
			let view3 = objectIndicatorViews[safe: 3],
			let view4 = objectIndicatorViews[safe: 4],
			let view5 = objectIndicatorViews[safe: 5],
			let view6 = objectIndicatorViews[safe: 6],
			let view7 = objectIndicatorViews[safe: 7] {

			// First row from left to right
			add(view0, constraints: [
				view0.centerYAnchor.constraint(equalTo: portalStoryIndicatorView.bottomAnchor,
											   constant: -Constants.firstRowVerticalCorrection),
				view0.centerXAnchor.constraint(equalTo: portalStoryIndicatorView.centerXAnchor,
											   constant: -Constants.horizontalOffset)
			], accumulator: &constraints)

			add(view1, constraints: [
				view1.centerYAnchor.constraint(equalTo: portalStoryIndicatorView.bottomAnchor,
											   constant: -Constants.firstRowVerticalCorrection),
				view1.centerXAnchor.constraint(equalTo: portalStoryIndicatorView.centerXAnchor,
											   constant: Constants.horizontalOffset)
			], accumulator: &constraints)

			// Second row from left to right
			add(view2, constraints: [
				view2.topAnchor.constraint(equalTo: portalStoryIndicatorView.bottomAnchor,
										   constant: -Constants.secondRowVerticalCorrection),
				view2.rightAnchor.constraint(equalTo: view0.centerXAnchor,
											 constant: Constants.secondRowHorizontalCorrection)
			], accumulator: &constraints)

			add(view3, constraints: [
				view3.topAnchor.constraint(equalTo: portalStoryIndicatorView.bottomAnchor,
										   constant: -Constants.secondRowVerticalCorrection),
				view3.centerXAnchor.constraint(equalTo: portalStoryIndicatorView.centerXAnchor)
			], accumulator: &constraints)

			add(view4, constraints: [
				view4.topAnchor.constraint(equalTo: portalStoryIndicatorView.bottomAnchor,
										   constant: -Constants.secondRowVerticalCorrection),
				view4.leftAnchor.constraint(equalTo: view1.centerXAnchor,
											constant: -Constants.secondRowHorizontalCorrection)
					], accumulator: &constraints)

			// Third row from left to right
			add(view5, constraints: [
				view5.centerXAnchor.constraint(equalTo: view0.centerXAnchor),
				view5.topAnchor.constraint(equalTo: view0.bottomAnchor,
										   constant: -Constants.thirdRowVerticalCorrection)
			], accumulator: &constraints)

			add(view6, constraints: [
				view6.centerXAnchor.constraint(equalTo: view1.centerXAnchor),
				view6.topAnchor.constraint(equalTo: view1.bottomAnchor,
										   constant: -Constants.thirdRowVerticalCorrection)
			], accumulator: &constraints)

			// Fourth row center
			add(view7, constraints: [
				view7.centerXAnchor.constraint(equalTo: portalStoryIndicatorView.centerXAnchor),
				view7.topAnchor.constraint(equalTo: view3.bottomAnchor,
										   constant: -Constants.fourthRowVerticalCorrection)
			], accumulator: &constraints)
		}

		NSLayoutConstraint.activate(constraints)

		update()
	}

	// Helper Functions
	private func update() {
		let layout = originalLayout
		var count: Int = 0
		for i in 0..<objectIndicatorViews.count {
			if layout[i] == .hidden {
				objectIndicatorViews[i].isHidden = true
			} else if layout[i] == .uncollected && count < objectsCollected {
				objectIndicatorViews[i].image = Resource.object(true).image
				count += 1
			} else {
				objectIndicatorViews[i].image = Resource.object(false).image
			}
		}
	}

	// Public Functions
	public func setPortalStoryCollected() {
		portalStoryIndicatorView.image = Resource.portalStory(true).image
		portalStoryIndicatorLabel.textColor = .lightGoldBranded
	}

	public func setCollectedObjectCount(to count: Int) {
		objectsCollected = count
		update()
	}
}
