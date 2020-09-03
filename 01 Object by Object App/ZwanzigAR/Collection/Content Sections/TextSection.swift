import UIKit

class TextSection: UIView {
	struct Constants {
		static let horizontalPadding: CGFloat = 32
		static let verticalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let topPaddingStory: CGFloat = 32
		static let bottomPadding: CGFloat = 64
	}

	enum State {
		case storyStart(Story)
		case portalPlaceHolder(Story)
		case storyEnd(Story)
		case portal(Portal)

		var text: String {
			switch self {
			case .storyStart(let story):
				return story.introduction?.text ?? ""
			case .portalPlaceHolder(let story):
				return story.visiblePortals.count > 0 ? "Finde das nächste Portal dieser Zeitreise, um dein Sammelalbum zu vervollständigen." : "Finde das erste Portal dieser Zeitreise, um dein Sammelalbum zu anzulegen."
			case .storyEnd(let story):
				return story.conclusion?.text ?? ""
			case .portal(let portal):
				return portal.portalStory?.text ?? ""
			}
		}

		var textAlignment: NSTextAlignment {
			switch self {
			case .portalPlaceHolder(_):
				return .center
			default:
				return .left
			}
		}
	}

	private let state: State 

	private var topPadding: CGFloat {
		switch state {
		case .storyStart(_), .storyEnd(_):
			return Constants.topPaddingStory
		default:
			return Constants.topPadding
		}
	}
	
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

		let body = UILabel.label(for: .body, text: state.text, alignment: state.textAlignment)
		body.translatesAutoresizingMaskIntoConstraints = false
		addSubview(body)

		NSLayoutConstraint.activate([
			body.centerXAnchor.constraint(equalTo: centerXAnchor),
			body.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			body.topAnchor.constraint(equalTo: topAnchor, constant: topPadding),
			body.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomPadding)
		])
	}
}
