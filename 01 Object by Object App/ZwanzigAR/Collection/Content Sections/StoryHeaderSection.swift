import UIKit

class StoryHeaderSection: UIView {
	enum State {
		case start
		case end
	}

	struct Constants {
		static let topPadding: CGFloat = 64
		static let verticalPadding: CGFloat = 16
		static let horizontalPadding: CGFloat = 16
		static let titleVerticalOffset: CGFloat = 32
	}

	private let story: Story
	private let state: State

	private var titleText: String {
		return story.title ?? "Hier ist der Story-Titel"
	}

	private var subtitleText: String {
		switch state {
		case .start:
			return "Start"
		case .end:
			return "Ende"
		}
	}

	init(state: State, story: Story) {
		self.state = state
		self.story = story
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark90Branded
		clipsToBounds = false
		layer.zPosition = .greatestFiniteMagnitude

		var constraints = [NSLayoutConstraint]()

		constraints.append(heightAnchor.constraint(equalToConstant: 400))

		let diamondImage = StoryTeaserImageView(story: story)
		add(diamondImage, constraints: [
			diamondImage.centerXAnchor.constraint(equalTo: centerXAnchor),
			diamondImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 42),
			diamondImage.widthAnchor.constraint(equalToConstant: StoryTeaserImageView.Constants.diamondImageViewDimension),
			diamondImage.heightAnchor.constraint(equalToConstant: StoryTeaserImageView.Constants.diamondImageViewDimension)
		], accumulator: &constraints)

		let title = UILabel.label(for: .headline1, text: titleText, alignment: .center, color: story.color)
		add(title, constraints: [
			title.centerXAnchor.constraint(equalTo: centerXAnchor),
			title.centerYAnchor.constraint(equalTo: diamondImage.centerYAnchor, constant: Constants.verticalPadding),
			title.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2)
		], accumulator: &constraints)

		let subtitle = UILabel.label(for: .subtitleBig, text: subtitleText, alignment: .center, color: .whiteBranded)
		add(subtitle, constraints: [
			subtitle.centerXAnchor.constraint(equalTo: centerXAnchor),
			subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Constants.verticalPadding)
		], accumulator: &constraints)

		switch state {
		case .start:
			let separator = UIView()
			separator.backgroundColor = story.color
			add(separator, constraints: [
				separator.heightAnchor.constraint(equalToConstant: 2),
				separator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 7/8),
				separator.rightAnchor.constraint(equalTo: rightAnchor),
				separator.centerYAnchor.constraint(equalTo: bottomAnchor)
			], accumulator: &constraints)

			let arrowTail = ArrowTailIllustration(color: story.color)
			add(arrowTail, constraints: [
				arrowTail.centerYAnchor.constraint(equalTo: separator.centerYAnchor),
				arrowTail.rightAnchor.constraint(equalTo: separator.leftAnchor)
			], accumulator: &constraints)
		case .end:
			let separator = UIView()
			separator.backgroundColor = story.color
			add(separator, constraints: [
				separator.heightAnchor.constraint(equalToConstant: 2),
				separator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/2),
				separator.leftAnchor.constraint(equalTo: leftAnchor),
				separator.centerYAnchor.constraint(equalTo: bottomAnchor)
			], accumulator: &constraints)

			let endMarker = UIView()
			let shapeLayer = CAShapeLayer.diamondShape(bounds: CGRect(origin: CGPoint(x: -10, y: -10),
																	  size: CGSize(width: 20, height: 20)))
			shapeLayer.fillColor = story.color.cgColor
			shapeLayer.strokeColor = nil
			shapeLayer.lineWidth = 0
			shapeLayer.lineJoin = CAShapeLayerLineJoin.miter
			endMarker.layer.addSublayer(shapeLayer)

			add(endMarker, constraints: [
				endMarker.centerYAnchor.constraint(equalTo: separator.centerYAnchor),
				endMarker.leftAnchor.constraint(equalTo: separator.rightAnchor)
			], accumulator: &constraints)
		}

		NSLayoutConstraint.activate(constraints)
	}
}
