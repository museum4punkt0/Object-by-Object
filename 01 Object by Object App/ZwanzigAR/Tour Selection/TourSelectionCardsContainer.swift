import UIKit

class TourSelectionCardsContainer: UIView {
	private let tourCards: [TourSelectionCard]
	public var cardsInTotal: Int {
		tourCards.count
	}

	init(_ tourCards: [TourSelectionCard]) {
		self.tourCards = tourCards
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		for (i, tourCard) in tourCards.enumerated() {
			tourCard.translatesAutoresizingMaskIntoConstraints = false
			addSubview(tourCard)

			NSLayoutConstraint.activate([
				tourCard.widthAnchor.constraint(equalToConstant: TourSelectionCard.cardWidth),
				tourCard.heightAnchor.constraint(equalToConstant: TourSelectionCard.cardHeight)
			])

			NSLayoutConstraint.activate([
				tourCard.leftAnchor.constraint(equalTo: tourCards[safe: i-1]?.rightAnchor ?? leftAnchor)
			])
		}
	}

	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		// Override hitTest to make buttons work inside the UIScrollView
		var count: Int = 0
		for view in subviews {
			let adjustedPoint = CGPoint(x: point.x - UIScreen.main.bounds.width * CGFloat(count), y: point.y)
			count += 1

			if let button = view.hitTest(adjustedPoint, with: event) as? UIButton {
				return button
			}
		}
		return nil
	}
}
