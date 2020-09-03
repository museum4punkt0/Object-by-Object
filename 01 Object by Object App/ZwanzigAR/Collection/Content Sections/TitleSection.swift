import UIKit

class TitleSection: UIView {
	enum State {
		case portal(Portal)
	}

	struct Constants {
		static let horizontalPadding: CGFloat = 32
		static let verticalPadding: CGFloat = 16
		static let topPadding: CGFloat = 32
		static let bottomPadding: CGFloat = 16
	}

	private let state: State

	private var subtitleText: String {
		switch state {
		case .portal:
			return "Portal"
		}
	}

	private var titleText: String {
		switch state {
		case .portal(let portal):
			if let title = portal.title {
				return title
			}
		}
		return "Hier ist ein Titel"
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

		let title = UILabel.label(for: .headline2Big, text: titleText, alignment: .center)
		title.translatesAutoresizingMaskIntoConstraints = false
		addSubview(title)

		let subtitle = UILabel.label(for: .subtitleSmall, text: subtitleText, alignment: .center)
		subtitle.translatesAutoresizingMaskIntoConstraints = false
		addSubview(subtitle)

		NSLayoutConstraint.activate([
			title.centerXAnchor.constraint(equalTo: centerXAnchor),
			title.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			title.topAnchor.constraint(equalTo: topAnchor, constant: Constants.topPadding),

			subtitle.centerXAnchor.constraint(equalTo: centerXAnchor),
			subtitle.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Constants.verticalPadding),
			subtitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomPadding)
		])
	}
}
