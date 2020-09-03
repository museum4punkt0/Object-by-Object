import MapKit

class PortalAnnotation: MKPointAnnotation {
	let portal: Portal

	init(portal: Portal) {
		self.portal = portal
		super.init()
		self.coordinate = portal.location?.coordinate ?? CLLocationCoordinate2D()
		self.title = portal.title
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PortalAnnotationView: MKAnnotationView {
	static let reuseIdentifier = String(describing: PortalAnnotationView.self)

	private let portal: Portal
	private let portalState: Portal.State
	private lazy var hasAchievement: Bool = { portal.hasAchievement }()
	private let portalNumber: Int

	private lazy var calloutView = CalloutView(for: portal)
	private var calloutIsPresented = false
	private lazy var calloutViewCenterXConstraint = NSLayoutConstraint(item: calloutView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
	private lazy var calloutViewTopConstraint = NSLayoutConstraint(item: calloutView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 16.0)

	init(annotation: PortalAnnotation) {
		self.portal = annotation.portal
		self.portalState = annotation.portal.state
		//self.hasAchievement = annotation.portal.hasAchievement
		self.portalNumber = annotation.portal.numberInStory
		super.init(annotation: annotation, reuseIdentifier: PortalAnnotationView.reuseIdentifier)

		isUserInteractionEnabled = true

		setImage()
		setNumber()
		if hasAchievement {
			setAchievement()
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		if calloutIsPresented && calloutView.hitTest(point, with: event) != nil {
			return calloutView.hitTest(point, with: event)
		}
		return nil
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let rect = self.bounds
		var isInside = rect.contains(point)
		if !isInside {
			for view in subviews {
				isInside = view.frame.contains(point)
				if isInside { break }
			}
		}
		return isInside
	}

	private func setImage() {
		// FOR TESTING:
		switch portalState {
		case .completed:
			image = UIImage(named: "img_portal_annotation_complete")
		default:
			image = UIImage(named: "img_portal_annotation_incomplete")
		}
		
		// FOR PRODUCTION:
//		switch portalState {
//		case .hidden, .inNavigation:
//			break
//		case .allObjectsCollected, .completed:
//			image = UIImage(named: "img_portal_annotation_complete")
//		default:
//			image = UIImage(named: "img_portal_annotation_incomplete")
//		}
		
		if let image = image {
			centerOffset = CGPoint(x: 0, y: -image.size.height/2)
		}
	}

	private func setNumber() {
		let label = UILabel.label(for: .portalAnnotation(portalState == .completed))
		label.text = "\(portalNumber)"
		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)

		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: centerXAnchor),
			label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2.0)
		])
	}

	private func setAchievement() {
		let image = UIImage(named: "img_achievement")
		let imageView = UIImageView(image: image)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(imageView)

		NSLayoutConstraint.activate([
			imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
			imageView.bottomAnchor.constraint(equalTo: topAnchor, constant: 10)
		])
	}

	public func showCallout(_ showCallout: Bool) {
		if showCallout {
			calloutView.translatesAutoresizingMaskIntoConstraints = false
			calloutView.isUserInteractionEnabled = true
			calloutView.addShadow()
			addSubview(calloutView)

			NSLayoutConstraint.activate([
				calloutViewCenterXConstraint,
				calloutViewTopConstraint
			])

			calloutIsPresented = true
			calloutView.isPresented = true
		} else {
			calloutView.removeFromSuperview()

			NSLayoutConstraint.deactivate([
				calloutViewCenterXConstraint,
				calloutViewTopConstraint
			])

			calloutIsPresented = false
			calloutView.isPresented = false
		}
	}
}

class CalloutView: UIView {
	struct Constants {
		static let verticalPadding: CGFloat = 16
		static let horizontalPadding: CGFloat = 16
		static let verticalOffset: CGFloat = 0
		static let textMaxWidth: CGFloat = 140
	}

	let portal: Portal

	let actionsImageView = UIImageView(image: UIImage(named: "img_tooltip_actions"))
	let topBackgroundImageView = UIImageView(image: UIImage(named: "img_tooltip_top"))
	let backgroundView = UIView()
	var titleLabel = UILabel()
	var subtitleLabel = UILabel()
	var isPresented = false
	let navigationButton = UIButton(type: .custom)
	let collectionButton = UIButton(type: .custom)

	init(for portal: Portal) {
		self.portal = portal
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true

		backgroundView.backgroundColor = .dark90Branded
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(backgroundView)

		topBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topBackgroundImageView)

		titleLabel = UILabel.label(for: .headline4, text: portal.title ?? "", alignment: .center, color: .whiteBranded)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(titleLabel)

		subtitleLabel = UILabel.label(for: .subtitleSmall, text: portal.statusText, alignment: .center, color: portal.statusColor)
		subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(subtitleLabel)

		actionsImageView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(actionsImageView)

		navigationButton.backgroundColor = .clear
		navigationButton.addTarget(self, action: #selector(startNavigation), for: .touchUpInside)
		navigationButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(navigationButton)

		collectionButton.backgroundColor = .clear
		collectionButton.addTarget(self, action: #selector(openCollection), for: .touchUpInside)
		collectionButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(collectionButton)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: 160),

			topBackgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalOffset),
			topBackgroundImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
			topBackgroundImageView.bottomAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 2.0),

			backgroundView.widthAnchor.constraint(equalTo: actionsImageView.widthAnchor),
			backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),

			titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			titleLabel.topAnchor.constraint(equalTo: topBackgroundImageView.topAnchor, constant: Constants.verticalPadding*2),
			titleLabel.widthAnchor.constraint(equalToConstant: Constants.textMaxWidth),

			subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.verticalPadding),
			subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			subtitleLabel.bottomAnchor.constraint(equalTo: actionsImageView.topAnchor, constant: -Constants.verticalPadding),
			subtitleLabel.widthAnchor.constraint(equalTo: titleLabel.widthAnchor),

			actionsImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
			actionsImageView.topAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -1.0),
			actionsImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

			navigationButton.rightAnchor.constraint(equalTo: actionsImageView.rightAnchor),
			navigationButton.leftAnchor.constraint(equalTo: actionsImageView.centerXAnchor),
			navigationButton.topAnchor.constraint(equalTo: actionsImageView.topAnchor),
			navigationButton.bottomAnchor.constraint(equalTo: actionsImageView.bottomAnchor),

			collectionButton.leftAnchor.constraint(equalTo: actionsImageView.leftAnchor),
			collectionButton.rightAnchor.constraint(equalTo: actionsImageView.centerXAnchor),
			collectionButton.topAnchor.constraint(equalTo: actionsImageView.topAnchor),
			collectionButton.bottomAnchor.constraint(equalTo: actionsImageView.bottomAnchor)
		])
	}

	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let offset = CGPoint(x: 40, y: -60)
		let offsetPoint = point + offset

		if isPresented {
			if navigationButton.frame.contains(offsetPoint) {
				return navigationButton
			} else if collectionButton.frame.contains(offsetPoint) {
				return collectionButton
			} else if topBackgroundImageView.frame.contains(offsetPoint) {
				return topBackgroundImageView
			} else if backgroundView.frame.contains(offsetPoint) {
				return backgroundView
			}
		}
		return nil
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let rect = self.bounds
		var isInside = rect.contains(point)
		if !isInside {
			for view in subviews {
				isInside = view.frame.contains(point)
				if isInside { break }
			}
		}
		return isInside
	}

	@objc
	private func startNavigation() {
		let navigatorVC = NavigatorViewController(navigationTool: .pharusPin, targetPortal: portal)
		navigatorVC.transitioningDelegate = navigatorVC.presentationManager
		navigatorVC.modalPresentationStyle = .custom
		UIViewController.topMost?.present(navigatorVC, animated: true, completion: nil)
	}

	@objc
	private func openCollection() {
		guard let story = GameStateManager.shared.currentStory else { return }

		let collectionVC = CollectionViewController(story: story, openAt: portal)
		collectionVC.modalPresentationStyle = .fullScreen
		UIViewController.topMost?.present(collectionVC, animated: true, completion: nil)
	}
}
