import UIKit
import CoreLocation

class TourSelectionCard: UIView {
	struct Constants {
		static let horizontalPaddingOutside: CGFloat = 16
		static let verticalPadding: CGFloat = 16
		static let horizontalPaddingInside: CGFloat = 16
		static let titleVerticalCorrection: CGFloat = 16
		static let bodyHeight: CGFloat = 60
		static let numericLabelMargin: CGFloat = 5
	}

	public static let cardHeight: CGFloat = 560
	public static let cardWidth: CGFloat = UIScreen.main.bounds.width
	private lazy var maxLabelWidth: CGFloat = TourSelectionCard.cardWidth - Constants.horizontalPaddingInside*2 - Constants.horizontalPaddingOutside*2

	private let cardView = UIView()
	private lazy var diamondImageView = StoryTeaserImageView(story: story)
	private lazy var titleLabel = UILabel.label(for: .headline1,
												text: story.title ?? "Test Story-Titel",
												alignment: .center,
												color: story.color)
	private lazy var subtitleLabel = UILabel.label(for: .subtitleBig,
												   text: "Zeitreise",
												   alignment: .center)
	private lazy var bodyLabel = UILabel.label(for: .bodySubtle,
											   text: story.teaserText ?? "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, magna aliquyam erat.",
											   alignment: .center)
	
	private lazy var durationLabel: UILabel = {
		var text = "—"
		if let duration = self.story.tourDuration?.intValue { text = String(format: "%d:%02d h", duration/60, duration%60) }
		return UILabel.label(for: .subtitleSmall, text: text, alignment: .center, color: self.story.color)
	}()
	
	private lazy var distanceLabel: UILabel = {
		let distance = LocationUpdateManager.shared.location?.distance(from: story.portals?.first?.location?.clLocation ?? CLLocation())
		return UILabel.label(for: .subtitleSmall, text: distance?.distanceString() ?? "—", alignment: .center, color: self.story.color)
	}()
	
	private lazy var selectButton = CardMainButton(state: story.state, selectAction: selectAction)

	private let story: Story
	private let selectAction: (() -> Void)

	init(_ story: Story, selectAction: @escaping (() -> Void)) {
		self.story = story
		self.selectAction = selectAction
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		cardView.backgroundColor = .dark80Branded
		cardView.layer.cornerRadius = 8
		cardView.layer.borderColor = UIColor.dark60Branded.cgColor
		cardView.layer.borderWidth = 1.0
		cardView.clipsToBounds = true

		let showDistance = story.state == .notStarted
		
		var constraints = [NSLayoutConstraint]()
		
		add(cardView, constraints: [
			cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
			cardView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.verticalPadding),
			cardView.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPaddingOutside*2),
			cardView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7)
		], accumulator: &constraints)
		
		add(diamondImageView, constraints: [
			diamondImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
			diamondImageView.centerYAnchor.constraint(equalTo: cardView.topAnchor),
			diamondImageView.widthAnchor.constraint(equalToConstant: StoryTeaserImageView.Constants.diamondImageViewDimension),
			diamondImageView.heightAnchor.constraint(equalToConstant: StoryTeaserImageView.Constants.diamondImageViewDimension)
		], accumulator: &constraints)
		
		add(titleLabel, constraints: [
			titleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
			titleLabel.bottomAnchor.constraint(equalTo: diamondImageView.bottomAnchor, constant: -Constants.titleVerticalCorrection),
			titleLabel.widthAnchor.constraint(equalToConstant: maxLabelWidth),
			titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.attributedText?.height(withConstrainedWidth: maxLabelWidth) ?? 0)
		], accumulator: &constraints)
		
		add(subtitleLabel, constraints: [
			subtitleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
			subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.verticalPadding),
			subtitleLabel.widthAnchor.constraint(equalTo: cardView.widthAnchor, constant: -Constants.horizontalPaddingInside*2),
			subtitleLabel.heightAnchor.constraint(equalToConstant: subtitleLabel.attributedText?.height(withConstrainedWidth: maxLabelWidth) ?? 0)
		], accumulator: &constraints)
		
		add(bodyLabel, constraints: [
			bodyLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
			bodyLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: Constants.verticalPadding),
			bodyLabel.widthAnchor.constraint(equalTo: cardView.widthAnchor, constant: -Constants.horizontalPaddingInside*2),
			bodyLabel.heightAnchor.constraint(equalToConstant: Constants.bodyHeight)
		], accumulator: &constraints)

		cardView.add(selectButton, constraints: [
			selectButton.leftAnchor.constraint(equalTo: cardView.leftAnchor),
			selectButton.rightAnchor.constraint(equalTo: cardView.rightAnchor),
			selectButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
		], accumulator: &constraints)
		
		let durationContainer = UIView()
		add(durationContainer, constraints: [
			durationContainer.leftAnchor.constraint(equalTo: cardView.leftAnchor),
			durationContainer.rightAnchor.constraint(equalTo: showDistance ? cardView.centerXAnchor : cardView.rightAnchor),
			durationContainer.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor),
			durationContainer.bottomAnchor.constraint(equalTo: selectButton.topAnchor)
		], accumulator: &constraints)
		
		durationContainer.add(durationLabel, constraints: [
			durationLabel.leftAnchor.constraint(equalTo: durationContainer.leftAnchor),
			durationLabel.rightAnchor.constraint(equalTo: durationContainer.rightAnchor),
			durationLabel.bottomAnchor.constraint(equalTo: durationContainer.centerYAnchor)
		], accumulator: &constraints)
		
		let durationCaption = UILabel.label(for: .subtitleSmaller, text: "Spieldauer", alignment: .center, color: .grey60Branded)
		durationContainer.add(durationCaption, constraints: [
			durationCaption.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: Constants.numericLabelMargin),
			durationCaption.leftAnchor.constraint(equalTo: durationContainer.leftAnchor),
			durationCaption.rightAnchor.constraint(equalTo: durationContainer.rightAnchor)
		], accumulator: &constraints)
		
		if showDistance {
			let distanceContainer = UIView()
			add(distanceContainer, constraints: [
				distanceContainer.leftAnchor.constraint(equalTo: cardView.centerXAnchor),
				distanceContainer.rightAnchor.constraint(equalTo: cardView.rightAnchor),
				distanceContainer.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor),
				distanceContainer.bottomAnchor.constraint(equalTo: selectButton.topAnchor)
			], accumulator: &constraints)
			
			distanceContainer.add(distanceLabel, constraints: [
				distanceLabel.leftAnchor.constraint(equalTo: distanceContainer.leftAnchor),
				distanceLabel.rightAnchor.constraint(equalTo: distanceContainer.rightAnchor),
				distanceLabel.bottomAnchor.constraint(equalTo: distanceContainer.centerYAnchor)
			], accumulator: &constraints)
			
			let distanceCaption = UILabel.label(for: .subtitleSmaller, text: "Erstes Portal", alignment: .center, color: .grey60Branded)
			distanceContainer.add(distanceCaption, constraints: [
				distanceCaption.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: Constants.numericLabelMargin),
				distanceCaption.leftAnchor.constraint(equalTo: distanceContainer.leftAnchor),
				distanceCaption.rightAnchor.constraint(equalTo: distanceContainer.rightAnchor)
			], accumulator: &constraints)
		}


		
		NSLayoutConstraint.activate(constraints)
	}
}
