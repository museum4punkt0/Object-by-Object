import UIKit
import AVFoundation

class AudioButtonSection: UIView {
	enum State {
		case portal(Portal)
		case storyStart(Story)
		case storyEnd(Story)
	}

	struct Constants {
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 16
	}

	private let state: State

	init(_ state: State) {
		self.state = state
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark90Branded

		let button = DiamondButtonSwitchingAppearance(.audioOn, action: { [weak self] (shouldTurnOn) in
			self?.readOutLoud(shouldTurnOn: shouldTurnOn)
		})
		button.translatesAutoresizingMaskIntoConstraints = false
		addSubview(button)

		NSLayoutConstraint.activate([
			button.centerXAnchor.constraint(equalTo: centerXAnchor),
			button.centerYAnchor.constraint(equalTo: centerYAnchor),
			button.topAnchor.constraint(equalTo: topAnchor, constant: Constants.topPadding),
			button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomPadding)
		])
	}

	private func readOutLoud(shouldTurnOn: Bool) {
		let synthesizer = CollectionViewController.speechSynthesizer
		var textForSpeech: String?

		guard shouldTurnOn else {
			synthesizer.stopSpeaking(at: .immediate)
			return
		}

		switch state {
		case .portal(let portal):
			//			textForSpeech = portal.portalStory?.phoneticTranscript ?? portal.portalStory?.text
			textForSpeech = portal.portalStory?.text
		case .storyStart(let story):
			//			textForSpeech = story.introduction?.phoneticTranscript ?? story.introduction?.text
			textForSpeech = story.introduction?.text
		case .storyEnd(let story):
			//			textForSpeech = story.conclusion?.phoneticTranscript ?? story.conclusion?.text
			textForSpeech = story.conclusion?.text
		}

		guard let text = textForSpeech else { return }

		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice.init(language: "de-DE")
		utterance.rate = 0.52

		if synthesizer.isSpeaking {
			synthesizer.stopSpeaking(at: .immediate)
		}
		synthesizer.speak(utterance)
	}
}
