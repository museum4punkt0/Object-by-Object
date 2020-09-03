import UIKit

class SessionNotificationView: UIView {
	enum State {
		case portalAppeared
		case portalAppearedCallForWalkThrough
		case primaryFragment
		case navigatorToolAppeared
		case navigatorToolAppearedCallForCollect
		case collectionLinkAppeared
		case collectionLinkCallForCollect
		case portalCompleted
		case userShouldMove

		var message: String {
			switch self {
			case .portalAppeared:
				return "Ein Portal hat sich geöffnet."
			case .portalAppearedCallForWalkThrough:
				return "Betritt das Portal!"
			case .primaryFragment:
				return "Finde die fehlenden Teile und setze sie hier ein!"
			case .navigatorToolAppeared:
				return "Ein Navigations-Artefakt ist erschienen."
			case .navigatorToolAppearedCallForCollect:
				return "Sammle das Navigations-Artefakt ein!"
			case .collectionLinkAppeared:
				return "Die Auszeichnung »Sammelalbum komplett« ist erschienen."
			case .collectionLinkCallForCollect:
				return "Sammle deine Auszeichnung »Sammelalbum komplett« ein!"
			case .portalCompleted:
				return "Portal abgeschlossen"
			case .userShouldMove:
				return "Bewege dich und scanne den Boden"
			}
		}
		
		var followUp: State? {
			switch self {
			case .portalAppeared:
				return .portalAppearedCallForWalkThrough
			case .navigatorToolAppeared:
				return .navigatorToolAppearedCallForCollect
			case .collectionLinkAppeared:
				return .collectionLinkCallForCollect
			default:
				return nil
			}
		}
		
		var isPersistent: Bool {
			switch self {
			case .portalAppearedCallForWalkThrough, .navigatorToolAppearedCallForCollect, .collectionLinkCallForCollect, .userShouldMove:
				return true
			default:
				return false
			}
		}
	}

	struct Constants {
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 32
		static let horizontalPadding: CGFloat = 32
	}

	private var stateQueue = [State]()

	private let spacerView = UIView()
	private let topSpacerForContainerView = UIView()
	public let containerView = UIView()
	private let label = UILabel.label(for: .fatBody, text: "", alignment: .center, color: .whiteBranded)

	private var containerViewBottomConstraint = NSLayoutConstraint()
	private var containerViewTopConstraint = NSLayoutConstraint()

	public var isActive: Bool = false
	public var portalEntered: Bool = false

	private var dismissTimer: Timer? {
		willSet { dismissTimer?.invalidate() }
	}

	init() {
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		// Layout
		backgroundColor = .clear
		clipsToBounds = false
		isUserInteractionEnabled = true

		spacerView.backgroundColor = .clear
		spacerView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(spacerView)

		topSpacerForContainerView.backgroundColor = .dark90Branded
		topSpacerForContainerView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topSpacerForContainerView)

		containerView.isUserInteractionEnabled = true
		containerView.backgroundColor = .dark90Branded
		containerView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(containerView)

		label.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(label)

		// Constraints
		containerViewTopConstraint = containerView.topAnchor.constraint(equalTo: spacerView.bottomAnchor)
		containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: topAnchor)

		NSLayoutConstraint.activate([
			spacerView.widthAnchor.constraint(equalTo: widthAnchor),
			spacerView.centerXAnchor.constraint(equalTo: centerXAnchor),
			spacerView.topAnchor.constraint(equalTo: topAnchor),
			spacerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),

			topSpacerForContainerView.widthAnchor.constraint(equalTo: widthAnchor),
			topSpacerForContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
			topSpacerForContainerView.bottomAnchor.constraint(equalTo: containerView.topAnchor),
			topSpacerForContainerView.heightAnchor.constraint(equalToConstant: 200),

			containerView.widthAnchor.constraint(equalTo: widthAnchor),
			containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
			containerViewBottomConstraint,
			containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

			label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
			label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.bottomPadding),
			label.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.topPadding)
		])

		// Gesture Recognizers
		let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
		swipeUp.direction = .up
		containerView.addGestureRecognizer(swipeUp)
	}

	public func notification(for state: State, runFollowUp: Bool = true) {
		DispatchQueue.main.async {
			if self.isActive {
//				if override {
					// Put current message first in messageQueue and trigger refresh
					self.stateQueue = [state] + self.stateQueue
					self.dismissTimer = nil
					self.set(visible: false)
//				}
//				else {
//					// Put current message last in queue
//					self.stateQueue.append(state)
//				}
				return
			}

			self.label.attributedText = UILabel.attributedString(for: .fatBody, text: state.message, alignment: .center)
			self.setNeedsLayout()
			self.invalidateIntrinsicContentSize()

			self.set(visible: true)
			self.isActive = true
			
			if !state.isPersistent {
				self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { (_) in
					self.set(visible: false)
					if let followUp = state.followUp, runFollowUp {
						self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (_) in
							switch followUp {
							case .portalAppearedCallForWalkThrough:
								if self.portalEntered { return }
							default:
								break
							}
							self.notification(for: followUp)
						})
					}
				})
			}
			
		}
	}

	private func set(visible: Bool, emptyQueue: Bool = false, followUp: @escaping () -> Void = {}) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: {
				NSLayoutConstraint.deactivate(visible ? [self.containerViewBottomConstraint] : [self.containerViewTopConstraint])
				NSLayoutConstraint.activate(visible ? [self.containerViewTopConstraint] : [self.containerViewBottomConstraint])
				self.superview?.layoutIfNeeded()
			}, completion: { _ in
				if !visible {
					followUp()
					self.isActive = false
					if emptyQueue { self.stateQueue = [] }
					if self.stateQueue.count > 0 {
						self.notification(for: self.stateQueue.removeFirst())
					}
				}
			})
		}
	}
	
	@objc
	private func handleSwipeUp() {
		dismissTimer = nil
		set(visible: false)
	}
	
	public func forceDismiss(followUp: @escaping () -> Void = {}) {
		dismissTimer = nil
		set(visible: false, emptyQueue: true, followUp: followUp)
	}
}
