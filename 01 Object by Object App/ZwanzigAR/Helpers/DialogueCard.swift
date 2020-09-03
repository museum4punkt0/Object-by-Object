import UIKit
import AVFoundation

class DialogueCard: UIView {
	struct Constants {
		static let horizontalMargin: CGFloat = 16
		static let bottomMargin: CGFloat = 24
		
		static let backgroundColor = UIColor.dark90Branded
		static let messageBackgroundColor = UIColor.dark80Branded
		
		static let textColor = UIColor.champagneBranded
		static let cornerRadius: CGFloat = 16
		static let bottomPadding: CGFloat = 16

		static let buttonSize = CGSize(width: 290, height: 64)
		static let buttonTextColor = UIColor.champagneBranded
		
		static let separatorColorDark = UIColor.dark100Branded
		static let separatorColorLight = UIColor.dark60Branded
		static let separatorHeight: CGFloat = 2
		
		static let hintImageMinimumRatio: CGFloat = 5/3
		
		static let textMargin: CGFloat = 24
		
		static let titleViewHeight: CGFloat = 64
		static let subtitleViewHeight: CGFloat = 22
		
		static let maximumBodyHeight: CGFloat = UIScreen.main.bounds.height/4
		
		static let headerSafeMargin: CGFloat = ContentHeaderDiamond.Constants.thumb3DFitSize.height - ContentHeaderDiamond.Constants.size.height
	}
	
	class DialogueButton: UIView {
		
		struct Constants {
			static let iconMargin: CGFloat = 18
		}
		
		let label = UILabel()
		let action: (() -> Void)
		var dismiss: (() -> Void)?
		
		init(title: String, icon: UIImage? = nil, action: @escaping () -> Void) {
			self.action = action
			super.init(frame: .zero)

			backgroundColor = .champagneBranded

			label.text = title
			label.textAlignment = .center
			label.font = UIFont.font(for: .button)
			label.textColor = .dark90Branded
			add(label)
			if let iconImage = icon {
				let imageView = UIImageView(image: iconImage)
				add(imageView, activate: [
					imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.iconMargin*2),
					imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
					imageView.widthAnchor.constraint(equalTo: heightAnchor, constant: -2*Constants.iconMargin),
					imageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -2*Constants.iconMargin)
				])
			}
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
			let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
			impactFeedbackGenerator.prepare()
			impactFeedbackGenerator.impactOccurred()
			action()
			dismiss?()
		}
	}

	enum Style: Equatable {
		case storyIntro(Story)
		case storyOutro(Story)
		case collectPortal(Portal, AVSpeechSynthesizer)
		case revisitPortal(Portal, AVSpeechSynthesizer)
		case collectObject(Object, Portal, AVSpeechSynthesizer)
		case revisitObject(Object, Portal, AVSpeechSynthesizer)
		case hintImage(URL)
		case custom(String, String, [DialogueButton])

		var contentHeaderDiamond: ContentHeaderDiamond? {
			switch self {
			case .storyIntro(let story), .storyOutro(let story):
				return ContentHeaderDiamond(story: story)
			case .collectPortal(let portal, _),
				 .revisitPortal(let portal, _):
				return ContentHeaderDiamond(portal: portal, storyColor: portal.story?.color ?? .white)
			case .collectObject(let object, let portal, _),
				 .revisitObject(let object, let portal, _):
				return ContentHeaderDiamond(object: object, storyColor: portal.story?.color ?? .white)
			default:
				return nil
			}
		}
		
		var title: String? {
			switch self {
			case .storyIntro(let story), .storyOutro(let story):
				return story.title
			case .collectPortal(let portal, _), .revisitPortal(let portal, _):
				return portal.title
			case .collectObject(let object, _, _), .revisitObject(let object, _, _):
				return object.title
			case .custom(let title, _, _):
				return title
			default:
				return nil
			}
		}

		var subtitle: String? {
			switch self {
			case .storyIntro(_):
				return "Die Zeitreise beginnt"
			case .storyOutro(_):
				return "Ende"
			case .collectPortal(_, _), .revisitPortal(_, _):
				return "Portal"
			case .collectObject(_, _, _), .revisitObject(_, _, _):
				return "Objekt"
			default:
				return nil
			}
		}

		var body: String? {
			switch self {
			case .storyIntro(let story):
				return story.introduction?.text
			case .storyOutro(let story):
				return story.conclusion?.text
			case .collectPortal(let portal, _), .revisitPortal(let portal, _):
				return portal.portalStory?.text
			case .collectObject(let object, _, _), .revisitObject(let object, _, _):
				return object.objectStory?.text
			case .custom(_, let message, _):
				return message
			default:
				return nil
			}
		}
		
		var buttons: [DialogueButton] {
			switch self {
			case .storyIntro(_), .storyOutro(_), .collectPortal(_, _), .collectObject(_, _, _):
				return [DialogueButton(title: "Einsammeln", icon: UIImage(named: "icn_collection_simple"), action: primaryAction)]
			case .revisitPortal(_, _), .revisitObject(_, _, _):
				return [DialogueButton(title: "Schließen", action: primaryAction)]
			case .hintImage(_):
				return [DialogueButton(title: "Verbergen", action: {})]
			case .custom(_, _, let buttons):
				return buttons
			}
		}

		var primaryAction: () -> () {
			switch self {
			case .storyIntro(let story):
				return {
					GameStateManager.shared.trigger(.storyIntroCollected(story))
					GameStateManager.shared.trigger(.hideDialogueCard)
				}
			case .storyOutro(let story):
				return {
					GameStateManager.shared.trigger(.storyOutroCollected(story))
					GameStateManager.shared.trigger(.hideDialogueCard)
				}
			case .collectPortal(let portal, _):
				return {
					GameStateManager.shared.trigger(.portalStoryCollected(portal))
					GameStateManager.shared.trigger(.hideDialogueCard)
				}
			case .collectObject(_, let portal, _):
				return {
					if portal.objects?.filter({ $0.state != .collected }).count == 0 {
						DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1_000)) {
							GameStateManager.shared.trigger(.allObjectsCollected(portal))
						}
					}
					GameStateManager.shared.trigger(.hideDialogueCard)
				}
			case .revisitObject(_, _, _), .revisitPortal(_, _):
				return { GameStateManager.shared.trigger(.hideDialogueCard) }
			default:
				return {}
			}
		}
	}

	private var verticalConstraintDismissed = NSLayoutConstraint()
	private var verticalConstraintPresented = NSLayoutConstraint()

	public var isPresenting = false

	private let backgroundView = UIView()
	
	private var style: Style
	init(style: Style) {
		self.style = style
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		switch style {
		case .storyIntro(_), .storyOutro(_):
			addContentHeaderDiamond(style.contentHeaderDiamond)
			addTitle(style.title)
			addSubtitle(style.subtitle)
			addBody(style.body)
		case .hintImage(let url):
			addImage(url: url)
		case .custom(let title, let message, _):
			addTitle(title)
			addBody(message)
		case .collectPortal(_, _), .collectObject(_, _, _), .revisitPortal(_, _), .revisitObject(_, _, _):
			addContentHeaderDiamond(style.contentHeaderDiamond)
			addTitle(style.title)
			addSubtitle(style.subtitle)
			addBody(style.body)
		}

		for i in 0..<style.buttons.count {
			let button = style.buttons[i]
			button.dismiss = { [weak self] in self?.dismissCard() }
			addButton(button, isLastButton: i == style.buttons.count-1)
		}

		if let lastSubview = subviews.last {
			NSLayoutConstraint.activate([bottomAnchor.constraint(equalTo: lastSubview.bottomAnchor)])
		}
		else {
			NSLayoutConstraint.activate([heightAnchor.constraint(equalToConstant: 0)])
		}

		backgroundView.backgroundColor = Constants.backgroundColor
		backgroundView.addCornerRadius(Constants.cornerRadius)
		add(backgroundView, activate: [
			backgroundView.topAnchor.constraint(equalTo: {
				if let headerDiamond = subviews.first(where: { $0.subviews.first is ContentHeaderDiamond }) {
					return headerDiamond.centerYAnchor
				}
				return topAnchor
			}()),
			backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
			backgroundView.leftAnchor.constraint(equalTo: leftAnchor),
			backgroundView.rightAnchor.constraint(equalTo: rightAnchor)
		])
		sendSubviewToBack(backgroundView)

		let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
		swipe.direction = .down
		addGestureRecognizer(swipe)
	}
	
	// Add to parent
	
	public func add(to view: UIView) {
		verticalConstraintDismissed = topAnchor.constraint(equalTo: view.bottomAnchor, constant: Constants.headerSafeMargin)
		verticalConstraintPresented = bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.bottomMargin)
		
		view.add(self, activate: [
			leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.horizontalMargin),
			rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Constants.horizontalMargin),
			verticalConstraintDismissed
		])
	}

	public func presentCard() {
		superview?.bringSubviewToFront(self)
		isPresenting = true
		
		UIView.animate(withDuration: 0.4) {
			NSLayoutConstraint.deactivate([self.verticalConstraintDismissed])
			NSLayoutConstraint.activate([self.verticalConstraintPresented])
			self.superview?.layoutIfNeeded()
			self.readOutLoud()
		}
	}
	
	@objc private func handleSwipe() {
		style.primaryAction()
		dismissCard()
	}
	
	public func dismissCard() {
		UIView.animate(withDuration: 0.4, animations: {
			NSLayoutConstraint.deactivate([self.verticalConstraintPresented])
			NSLayoutConstraint.activate([self.verticalConstraintDismissed])
			self.superview?.layoutIfNeeded()
		}) { (_) in
			self.isPresenting = false
		}
	}
	
	private func readOutLoud() {
		var textForSpeech: String?
		var speechSynthesizer: AVSpeechSynthesizer?
		
		switch style {
		case .collectPortal(let portal, let synthesizer):
			textForSpeech = portal.portalStory?.phoneticTranscript ?? portal.portalStory?.text
			speechSynthesizer = synthesizer
		case .collectObject(let object, _, let synthesizer):
			textForSpeech = object.objectStory?.text
			speechSynthesizer = synthesizer
		default:
			break
		}

		guard
			let text = textForSpeech,
			let synthesizer = speechSynthesizer
		else { return }
		
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice.init(language: "de-DE")
		utterance.rate = 0.52

		if synthesizer.isSpeaking {
			synthesizer.stopSpeaking(at: .immediate)
		}
//		synthesizer.speak(utterance)
	}
	
	// Add components
	
	private func addSeparator() {
		guard let lastSubview = subviews.last else { return }
		
		let base = UIView()
		base.backgroundColor = Constants.separatorColorDark
		let lowerHalf = UIView()
		lowerHalf.backgroundColor = Constants.separatorColorLight
		base.add(lowerHalf, activate: [
			lowerHalf.topAnchor.constraint(equalTo: base.centerYAnchor),
			lowerHalf.bottomAnchor.constraint(equalTo: base.bottomAnchor),
			lowerHalf.leftAnchor.constraint(equalTo: base.leftAnchor),
			lowerHalf.rightAnchor.constraint(equalTo: base.rightAnchor)
		])
		add(base, activate: [
			base.topAnchor.constraint(equalTo: lastSubview.bottomAnchor),
			base.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
			base.leftAnchor.constraint(equalTo: leftAnchor),
			base.rightAnchor.constraint(equalTo: rightAnchor)
		])
		
		return
	}
	
	private func addButton(_ button: DialogueButton, isLastButton: Bool = false) {
		addSeparator()
		add(button, activate: [
			button.topAnchor.constraint(equalTo: {
				if let lastSubview = subviews.last { return lastSubview.bottomAnchor }
				return topAnchor
			}()),
			button.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
			button.leftAnchor.constraint(equalTo: leftAnchor),
			button.rightAnchor.constraint(equalTo: rightAnchor)
		])

		if isLastButton {
			button.layer.cornerRadius = 16
			button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
		}
	}
	
	private func addImage(url: URL) {
		guard
			let data: Data = try? Data(contentsOf: url),
			let image: UIImage = UIImage(data: data)
		else {
			print("ERROR: No hint image available for hint image dialogue")
			return
		}
		let imageView = UIImageView(image: image)
		imageView.contentMode = .scaleAspectFill
		imageView.layer.masksToBounds = true
		add(imageView, activate: [
			imageView.topAnchor.constraint(equalTo: topAnchor),
			imageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1/max(image.size.width/image.size.height, Constants.hintImageMinimumRatio)),
			imageView.leftAnchor.constraint(equalTo: leftAnchor),
			imageView.rightAnchor.constraint(equalTo: rightAnchor)
		])
	}
	
	private func addContentHeaderDiamond(_ diamond: ContentHeaderDiamond?) {
		guard let diamond = diamond else { return }
		let container = UIView()
		let size = diamond.frame.size
		add(container, activate: [
			container.topAnchor.constraint(equalTo: topAnchor),
			container.heightAnchor.constraint(equalToConstant: size.height),
			container.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.textMargin),
			container.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.textMargin)
		])

		container.add(diamond, activate: [
			diamond.centerXAnchor.constraint(equalTo: container.centerXAnchor),
			diamond.centerYAnchor.constraint(equalTo: container.centerYAnchor),
			diamond.widthAnchor.constraint(equalToConstant: size.width),
			diamond.heightAnchor.constraint(equalToConstant: size.height)
		])
	}

	
	private func addTitle(_ title: String?) {
		guard let title = title else { return }
		let container = UIView()
		add(container, activate: [
			container.topAnchor.constraint(equalTo: {
				if let lastSubview = subviews.last { return lastSubview.bottomAnchor }
				return topAnchor
			}()),
			container.heightAnchor.constraint(equalToConstant: Constants.titleViewHeight),
			container.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.textMargin),
			container.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.textMargin)
		])

		let titleLabel = UILabel.label(for: .headline2, text: title)
		container.add(titleLabel)
	}
	
	private func addSubtitle(_ subtitle: String?) {
		guard let subtitle = subtitle else { return }
		let container = UIView()
		add(container, activate: [
			container.topAnchor.constraint(equalTo: {
				if let lastSubview = subviews.last { return lastSubview.bottomAnchor }
				return topAnchor
			}()),
			container.heightAnchor.constraint(equalToConstant: Constants.subtitleViewHeight),
			container.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.textMargin),
			container.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.textMargin)
		])

		let titleLabel = UILabel.label(for: .subtitleSmall, text: subtitle)
		container.add(titleLabel, activate: [
			titleLabel.leftAnchor.constraint(equalTo: container.leftAnchor),
			titleLabel.rightAnchor.constraint(equalTo: container.rightAnchor),
			titleLabel.heightAnchor.constraint(equalTo: container.heightAnchor),
			titleLabel.centerYAnchor.constraint(equalTo: container.topAnchor)
		])
	}

	private func addBody(_ message: String?) {
		guard let message = message else { return }

		let bodyLabel = UILabel.label(for: .body, text: message)

		addSeparator()
		var textHeight: CGFloat = 0
		if let attributedText = bodyLabel.attributedText {
			textHeight = attributedText.height(withConstrainedWidth: UIScreen.main.bounds.size.width - 2*Constants.horizontalMargin - 2*Constants.textMargin)
		}
		let textHeightWithMargins = textHeight + 2*Constants.textMargin

		print("\(#function) – textHeight for height \(UIScreen.main.bounds.size.width - 2*Constants.horizontalMargin): \(textHeightWithMargins)")

		let container = UIView()
		container.backgroundColor = Constants.messageBackgroundColor
		add(container, activate: [
			container.topAnchor.constraint(equalTo: {
				if let lastSubview = subviews.last { return lastSubview.bottomAnchor }
				return topAnchor
			}()),
			container.heightAnchor.constraint(equalToConstant: min(textHeightWithMargins, Constants.maximumBodyHeight)),
			container.leftAnchor.constraint(equalTo: leftAnchor),
			container.rightAnchor.constraint(equalTo: rightAnchor)
		])

		let scrollView = UIScrollView()
		container.add(scrollView, activate: [
			scrollView.topAnchor.constraint(equalTo: container.topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
			scrollView.leftAnchor.constraint(equalTo: container.leftAnchor, constant: Constants.textMargin),
			scrollView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -Constants.textMargin)
		])
		
		scrollView.add(bodyLabel)
		NSLayoutConstraint.activate([
			bodyLabel.heightAnchor.constraint(equalToConstant: textHeightWithMargins),
			bodyLabel.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -2*Constants.textMargin)
		])
	}
}
