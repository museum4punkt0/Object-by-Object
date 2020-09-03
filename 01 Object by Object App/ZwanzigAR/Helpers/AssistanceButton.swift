import UIKit

class AssistanceButton: UIView {
	struct Constants {
		static let buttonSize = CGSize(width: 290, height: 64)
		static let backgroundColor = UIColor.dark90Branded
		static let textColor = UIColor.champagneBranded
		static let cornerRadius: CGFloat = 4
		static let bottomPadding: CGFloat = 16
	}

	enum Style: Equatable {
		case none
		case simplerMap
		case pharusMap
		case helpWithClueObject
		case goToSystemSettings
		case startAdHocSession
		case custom(String)

		var title: String {
			switch self {
			case .none:
				return ""
			case .simplerMap:
				return "Einfachere Darstellung"
			case .pharusMap:
				return "Pharus-Plan"
			case .helpWithClueObject:
				return "Ich brauche Hilfe"
			case .goToSystemSettings:
				return "Zu den Einstellungen"
			case .startAdHocSession:
				return "Einfache AR-Session starten"
			case .custom(let title):
				return title
			}
		}
	}

	private var style: Style
	private var action: (() -> Void)?
	init(style: Style, selectAction: @escaping (() -> Void) = {}) {
		self.style = style
		super.init(frame: .zero)
		if style == .none { alpha = 0 }
		setup()
		set(style: style, selectAction: selectAction)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = Constants.backgroundColor
		addCornerRadius(Constants.cornerRadius)
	}
	
	public func add(to view: UIView, animated: Bool = false) {
		let addAction = {
			view.add(self, activate: self.constraints(in: view))
		}
		
		if animated {
			alpha = 0
			addAction()
			UIView.animate(withDuration: 0.2) {
				self.alpha = 1
			}
		}
		else {
			addAction()
		}
	}
	
	
	public func constraints(in view: UIView) -> [NSLayoutConstraint] {
		return [
			centerXAnchor.constraint(equalTo: view.centerXAnchor),
			bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.bottomPadding),
			widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
			heightAnchor.constraint(equalToConstant: Constants.buttonSize.height)
		]
	}
	
	public func set(style: Style, selectAction: @escaping (() -> Void)) {
		if self.style == .none, style != .none {
			DispatchQueue.main.async { UIView.animate(withDuration: 0.2) { self.alpha = 1 } }
		}
		else if self.style != .none, style == .none {
			DispatchQueue.main.async { UIView.animate(withDuration: 0.2) { self.alpha = 0 } }
		}
		self.style = style
		self.action = selectAction
		isUserInteractionEnabled = true
		if let oldLabel = subviews.first as? UILabel { oldLabel.removeFromSuperview() }
		add(UILabel.label(for: .buttonDark, text: style.title, alignment: .center, color: Constants.textColor))
	}

//	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//		switch style {
//		case .pharusMap:
//		case .simplerMap
//		}
//	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let action = action else { return }
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()
		action()
	}
}
