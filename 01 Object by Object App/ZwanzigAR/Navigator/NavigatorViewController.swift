import UIKit
import CoreLocation
import MapKit
import SceneKit

class NavigatorViewController: UIViewController, PortalSessionPresentationDelegate {
	struct Constants {
		static let backgroundColor = UIColor.dark60Branded
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 16

		static let toolDiameterLarge: CGFloat = 240
		static let toolDiameterSmall: CGFloat = 106
		static let toolDiameterTiny: CGFloat = 20
		static let toolBorderDelta: CGFloat = 40
		static let toolBorderDeltaProximity: CGFloat = 8

		static let compassDistanceLabelSize = CGSize(width: 106, height: 50)
		static let compassDistanceLabelMargin: CGFloat = 48
		
		static let compassNeedleImageName = "compass_needle"
		
		static let objectiveLabelSize = CGSize(width: 320, height: 80)
		static let objectiveLabelMargin: CGFloat = 16
		static let objectiveNavigationObject = "Wohin führt dieses Navigations-Artefakt?"
		static let objectiveClueObject = "Welcher Ortshinweis könnte hier verschlüsselt sein? Begib dich dorthin!"
		static let objectiveClueObjectProximity = "Das Ziel ist ganz in der Nähe!"

		static let haloCount = 5
		static let haloDiameterDelta: CGFloat = 100
		static let haloDiameterDeltaProximity: CGFloat = 80

		static let offCenterCorrection: CGFloat = 60
		static let navigatorButtonVerticalCorrection: CGFloat = 64
		
		static let compassDistanceFont = UIFont.font(.light, size: 24)
		static let objectiveFont = UIFont.font(.lightItalic, size: 24)
		
		static let enterSessionDistanceInMeters: Double = 10
//		static let maximumAccuracyDeviation: Double = 20

		static let enterProximityDistanceInMeters: Double = 30
//		static let maximumAccuracyDeviationProximity: Double = 30

		static let topHubTitle: [NavigationToolTypeString: HubCenterElementView.ElementType] = [
			.compass: .title("Magischer Kompass"),
			.pharusPin: .title("Pharus-Nadel"),
			.clueObject: .title("Hinweis-Artefakt")
		]
		static let topHubSubtitle: [NavigationToolTypeString: HubCenterElementView.ElementType] = [
			.compass: .subtitle("Navigation"),
			.pharusPin: .subtitle("Navigation"),
			.clueObject: .subtitle("Bonus-Navigation")
		]
		
		static let helpWithClueObjectCardTitle = "Ist das Rätsel zu schwer?"
//		static let helpWithClueObjectCardBody = "Das Hinweis-Artefakt ist eine besondere Herausforderung. Finde heraus, zu welchem Ort das Artefakt gehört und begib dich dorthin.\n\nDas Artefakt führt dich dann die letzten Meter zum Portal!"
		static let helpWithClueObjectCardBody = "Das Hinweis-Artefakt ist eine besondere Herausforderung. Finde heraus, zu welchem Ort das Artefakt gehört und begib dich dorthin.\n\nDu kannst es auch in ein einfacheres Artefakt umtauschen, dann verfällt jedoch dein Bonus."
	}

	private var navigationTool: NavigationTool
	private var targetPortal: Portal
	
	private lazy var topHubViewLayout = HubViewBlueprint(
		centerViewLayout: self.clueObjectView != nil ? .extendedWithAchievement : .extended,
		centerViewTopElement: Constants.topHubTitle[self.navigationTool.typeString],
		centerViewBottomElement: Constants.topHubSubtitle[self.navigationTool.typeString],
		topLeftButtonStyle: .hidden,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .close,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: {},
		bottomLeftButtonAction: {},
		topRightButtonAction: { [weak self] in
			self?.tapClose()
		},
		bottomRightButtonAction: {}
	)
	private lazy var topHubView = HubView(blueprint: topHubViewLayout)

	private lazy var outerMask: UICircleView = {
		let circle = UICircleView()
		circle.backgroundColor = UIColor.blueBranded
		return circle
	}()
	private lazy var outerMaskLayoutView: UIPassThroughView = {
		let view = UIPassThroughView()
		view.backgroundColor = .clear
		return view
	}()
	
	private lazy var haloContainer = UIView()
	
	private lazy var centerCircle: UICircleView = {
		let circle = UICircleView()
		circle.backgroundColor = .blueBranded
		return circle
	}()
	private var centerCircleWidthConstraint = NSLayoutConstraint()
	private var centerCircleHeightConstraint = NSLayoutConstraint()
	
	private lazy var borderCircle: UICircleView = {
		let circle = UICircleView()
		circle.backgroundColor = .dark60Branded
		return circle
	}()
	private var borderCircleWidthConstraint = NSLayoutConstraint()
	private var borderCircleHeightConstraint = NSLayoutConstraint()

	private var haloWidthConstraints = [NSLayoutConstraint]()
	private var haloHeightConstraints = [NSLayoutConstraint]()

	private var objectiveLabel: UILabel = {
		let label = UILabel()
		label.font = Constants.objectiveFont
		label.numberOfLines = 0
		label.textAlignment = .center
		label.textColor = UIColor.whiteBranded.withAlphaComponent(0.6)
		return label
	}()

	private var assistanceButton = AssistanceButton(style: .none)
	
	// Compass Tool
	private var compassNeedleImageView: UIImageView?
	private var compassDistanceLabel: UILabel?

	// Pharus Pin Tool
	private var pharusMap: PharusMapView?
	
	// Clue Object Tool
	private var clueObjectView: ClueObjectSceneView?
	private var clueObjectTargetLocationView: UIView?
	private var clueObjectTargetLocationCenterXConstraint = NSLayoutConstraint()
	private var clueObjectTargetLocationCenterYConstraint = NSLayoutConstraint()
	var activatingProximityNavigation = false
	
	private var presentedAnimationConstraints = [[NavigatorPresentationAnimator.AnimationState: NSLayoutConstraint]]()

	var presentationManager = NavigatorPresentationManager()

	// PortalSessionPresentationDelegate
	public var portalSessionHasBeenCompleted: Bool = false
	
	init(navigationTool: NavigationTool, targetPortal: Portal) {
		self.navigationTool = navigationTool
		self.targetPortal = targetPortal
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("NavigatorVC: Deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		overrideUserInterfaceStyle = .dark

		view.backgroundColor = Constants.backgroundColor

		var constraints = [NSLayoutConstraint]()
		
		// Outer Mask
		let outerMaskVerticalConstraintInitial = outerMaskLayoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.navigatorButtonVerticalCorrection)
		presentedAnimationConstraints.append([
			.initial: outerMaskVerticalConstraintInitial,
			.intermediate: outerMaskLayoutView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Constants.offCenterCorrection),
			.final: outerMaskLayoutView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		let outerMaskWidthConstraintInitial = outerMaskLayoutView.widthAnchor.constraint(equalToConstant: Constants.toolDiameterSmall)
		presentedAnimationConstraints.append([
			.initial: outerMaskWidthConstraintInitial,
			.intermediate: outerMaskLayoutView.widthAnchor.constraint(equalToConstant: Constants.toolDiameterLarge),
			.final: outerMaskLayoutView.widthAnchor.constraint(equalToConstant: sqrt(pow(view.frame.size.width, 2) + pow(view.frame.size.height, 2)))
		])
		let outerMaskHeightConstraintInitial = outerMaskLayoutView.heightAnchor.constraint(equalToConstant: Constants.toolDiameterSmall)
		presentedAnimationConstraints.append([
			.initial: outerMaskHeightConstraintInitial,
			.intermediate: outerMaskLayoutView.heightAnchor.constraint(equalToConstant: Constants.toolDiameterLarge),
			.final: outerMaskLayoutView.heightAnchor.constraint(equalToConstant: sqrt(pow(view.frame.size.width, 2) + pow(view.frame.size.height, 2)))
		])
		view.add(outerMaskLayoutView, constraints: [
			outerMaskLayoutView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			outerMaskVerticalConstraintInitial,
			outerMaskWidthConstraintInitial,
			outerMaskHeightConstraintInitial
		], accumulator: &constraints)
		view.mask = outerMask

//		view.add(navigationView)
		
		// Halo Circles
		view.add(haloContainer)
		for i in 1...Constants.haloCount {
			let diameterDelta = CGFloat(i) * Constants.haloDiameterDelta
			let haloCircle = UICircleView()
			haloCircle.backgroundColor = UIColor.blueBranded.withAlphaComponent(0.06)
			let haloWidthConstraint = haloCircle.widthAnchor.constraint(equalTo: centerCircle.widthAnchor, constant: diameterDelta)
			let haloHeightConstraint = haloCircle.heightAnchor.constraint(equalTo: centerCircle.heightAnchor, constant: diameterDelta)
			haloWidthConstraints.append(haloWidthConstraint)
			haloHeightConstraints.append(haloHeightConstraint)
			haloContainer.add(haloCircle, constraints: [
				haloCircle.centerXAnchor.constraint(equalTo: haloContainer.centerXAnchor),
				haloCircle.centerYAnchor.constraint(equalTo: haloContainer.centerYAnchor, constant: -Constants.offCenterCorrection),
				haloWidthConstraint,
				haloHeightConstraint
			], accumulator: &constraints)
		}
		borderCircleWidthConstraint = borderCircle.widthAnchor.constraint(equalTo: centerCircle.widthAnchor, constant: Constants.toolBorderDelta)
		borderCircleHeightConstraint = borderCircle.heightAnchor.constraint(equalTo: centerCircle.heightAnchor, constant: Constants.toolBorderDelta)
		view.add(borderCircle, constraints: [
			borderCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			borderCircle.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Constants.offCenterCorrection),
			borderCircleWidthConstraint,
			borderCircleHeightConstraint
		], accumulator: &constraints)

		// Center Circle
		let centerCircleVerticalConstraintInitial = centerCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.navigatorButtonVerticalCorrection)
		presentedAnimationConstraints.append([
			.initial: centerCircleVerticalConstraintInitial,
			.intermediate: centerCircle.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Constants.offCenterCorrection),
			.final: centerCircle.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Constants.offCenterCorrection)
		])
		centerCircleWidthConstraint = centerCircle.widthAnchor.constraint(equalToConstant: Constants.toolDiameterLarge)
		centerCircleHeightConstraint = centerCircle.heightAnchor.constraint(equalToConstant: Constants.toolDiameterLarge)
		view.add(centerCircle, constraints: [
			centerCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			centerCircleVerticalConstraintInitial,
			centerCircleWidthConstraint,
			centerCircleHeightConstraint
		], accumulator: &constraints)
		
		// Navigator UI
		switch navigationTool {
		case .compass:
			let needleImageView = UIImageView(image: UIImage(named: Constants.compassNeedleImageName))
			needleImageView.backgroundColor = .clear
			centerCircle.add(needleImageView, constraints: [
				needleImageView.topAnchor.constraint(equalTo: centerCircle.topAnchor),
				needleImageView.bottomAnchor.constraint(equalTo: centerCircle.bottomAnchor),
				needleImageView.leftAnchor.constraint(equalTo: centerCircle.leftAnchor),
				needleImageView.rightAnchor.constraint(equalTo: centerCircle.rightAnchor)
			], accumulator: &constraints)
			compassNeedleImageView = needleImageView

			let distanceLabel = UILabel()
			distanceLabel.addCornerRadius(4)
			distanceLabel.backgroundColor = .dark60Branded
			distanceLabel.textColor = .whiteBranded
			distanceLabel.textAlignment = .center
			distanceLabel.font = UIFont.font(.light, size: 24)
			view.add(distanceLabel, constraints: [
				distanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
				distanceLabel.bottomAnchor.constraint(equalTo: objectiveLabel.topAnchor, constant: -Constants.compassDistanceLabelMargin),
				distanceLabel.widthAnchor.constraint(equalToConstant: Constants.compassDistanceLabelSize.width),
				distanceLabel.heightAnchor.constraint(equalToConstant: Constants.compassDistanceLabelSize.height)
			], accumulator: &constraints)
			compassDistanceLabel = distanceLabel

		case .pharusPin:
			let mapView = PharusMapView(mode: .navigation)
			centerCircle.add(mapView, constraints: [
				mapView.topAnchor.constraint(equalTo: centerCircle.topAnchor),
				mapView.bottomAnchor.constraint(equalTo: centerCircle.bottomAnchor),
				mapView.leftAnchor.constraint(equalTo: centerCircle.leftAnchor),
				mapView.rightAnchor.constraint(equalTo: centerCircle.rightAnchor)
			], accumulator: &constraints)
			mapView.addAnnotation(PharusAnnotation(portal: targetPortal))
			pharusMap = mapView
			setAssistanceButtonForMapSwitch()
			
		case .clueObject(let clueObject):
			let objectView = ClueObjectSceneView(clueObject: clueObject)
			view.add(objectView, constraints: [
				objectView.leftAnchor.constraint(equalTo: view.leftAnchor),
				objectView.rightAnchor.constraint(equalTo: view.rightAnchor),
				objectView.centerYAnchor.constraint(equalTo: centerCircle.centerYAnchor),
				objectView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: Constants.offCenterCorrection*2)
			], accumulator: &constraints)
			clueObjectView = objectView
			setAssistanceButtonForHelpWithClueObject()
			centerCircle.backgroundColor = Constants.backgroundColor
		}
		
		view.add(assistanceButton, constraints: assistanceButton.constraints(in: view), accumulator: &constraints)
		
		switch navigationTool {
		case .compass, .pharusPin:
			objectiveLabel.text = Constants.objectiveNavigationObject
		default:
			objectiveLabel.text =  Constants.objectiveClueObject
		}
		view.add(objectiveLabel, constraints: [
			objectiveLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			objectiveLabel.bottomAnchor.constraint(equalTo: assistanceButton.topAnchor, constant: -Constants.objectiveLabelMargin),
			objectiveLabel.widthAnchor.constraint(equalToConstant: Constants.objectiveLabelSize.width),
			objectiveLabel.heightAnchor.constraint(equalToConstant: Constants.objectiveLabelSize.height)
		], accumulator: &constraints)
		
		// Hub
		view.add(topHubView, constraints: [
			topHubView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			topHubView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
			topHubView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.horizontalPadding)
		], accumulator: &constraints)

		NSLayoutConstraint.activate(constraints)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		LocationUpdateManager.subscribe(self, locationSelector: #selector(locationDataUpdated), headingSelector: #selector(locationDataUpdated))
	}
	
	override var prefersHomeIndicatorAutoHidden: Bool {
		return true
	}
}

extension NavigatorViewController {
	func presentPortalSessionViewController() {
		LocationUpdateManager.unsubscribe(self)

		let portalSessionVC = PortalSessionViewController(from: self.targetPortal)
		self.add(portalSessionVC)
		if let clueObjectView = self.clueObjectView {
			let scaleAction = SCNAction.scale(to: 0, duration: 0.5)
			scaleAction.timingMode = .easeIn
			clueObjectView.container.runAction(scaleAction, completionHandler: {
				self.clueObjectView?.container.removeAllActions()
			})
		}
		UIView.animate(withDuration: 0.2, animations: {
			self.topHubView.alpha = 0
			self.objectiveLabel.alpha = 0
			self.compassDistanceLabel?.alpha = 0
			self.assistanceButton.alpha = 0
		}) { (_) in
			UIView.animate(withDuration: 0.8, animations: {
				self.centerCircleWidthConstraint.constant = Constants.toolDiameterTiny
				self.centerCircleHeightConstraint.constant = Constants.toolDiameterTiny
				self.centerCircle.backgroundColor = .dark80Branded

				self.borderCircleWidthConstraint.constant = Constants.toolBorderDelta
				self.borderCircleHeightConstraint.constant = Constants.toolBorderDelta
				self.borderCircle.backgroundColor = .dark60Branded
				
				_ = self.centerCircle.subviews.map { $0.alpha = 0 }
				_ = self.clueObjectTargetLocationView?.subviews.map { $0.alpha = 0 }

				self.view.layoutIfNeeded()
			}) { (_) in
				portalSessionVC.updateOuterMask()
				UIView.animate(withDuration: 1.0, animations: {
					self.centerCircleWidthConstraint.constant = PortalSessionViewController.Constants.shutterDiameter
					self.centerCircleHeightConstraint.constant = PortalSessionViewController.Constants.shutterDiameter
					self.view.layoutIfNeeded()
					portalSessionVC.updateOuterMask()
					portalSessionVC.openShutterHalf()
				}) { (_) in
					UIView.animate(withDuration: 1.0) {
						portalSessionVC.fadeInCameraView()
					}
				}
			}
		}
	}

	private func tapClose() {
		LocationUpdateManager.unsubscribe(self)
		dismiss(animated: true, completion: nil)
	}
}

extension NavigatorViewController {

	@objc private func locationDataUpdated() {
		guard
			let heading = LocationUpdateManager.shared.heading,
			let currentLocation = LocationUpdateManager.shared.location,
			let targetLocation = targetPortal.location?.clLocation
		else { return }

		let distance = currentLocation.distance(from: targetLocation)
		let bearing = currentLocation.bearing(to: targetLocation)
		let trueBearing = CGFloat(((360.0 - heading.trueHeading) + bearing).remainder(dividingBy: 360))

		
		switch navigationTool {
		case .compass:
			updateCompass(distance: distance, trueBearing: trueBearing)//heading: heading, bearing: bearing)
		case .pharusPin:
			updatePharusPin(currentLocation: currentLocation, targetLocation: targetLocation, heading: heading)
		case .clueObject(_):
			if
//				currentLocation.horizontalAccuracy < Constants.maximumAccuracyDeviation,
				distance < Constants.enterProximityDistanceInMeters
			{
				if clueObjectTargetLocationView == nil {
					clueObjectView?.dismissSwipeHint()
					activateProximityNavigation()
				}
				else {
					updateProximityNavigation(distance: distance, trueBearing: trueBearing)
				}
			}
		}
		
		if
			!activatingProximityNavigation &&
			(
				distance < Constants.enterSessionDistanceInMeters ||
				(
					distance < currentLocation.horizontalAccuracy /*&&
					currentLocation.horizontalAccuracy < Constants.maximumAccuracyDeviation*/
				)
			)
			
		{
			presentPortalSessionViewController()
		}

	}
	
	// MARK: - Compass Functions
	
	private func updateCompass(distance: CLLocationDistance, trueBearing: CGFloat /*heading: CLHeading, bearing: Double*/) {
		guard
			let compassNeedleImageView = compassNeedleImageView,
			let compassDistanceLabel = compassDistanceLabel
		else { return }
		
		UIView.animate(withDuration: 0.5) {
//			var angle: CGFloat = (360.0 - CGFloat(heading.trueHeading)) + CGFloat(bearing)
//			if angle > 360 { angle -= 360 }
			compassNeedleImageView.transform = CGAffineTransform(rotationAngle: trueBearing.degreesToRadians)
		}

//		switch distance {
//		case 0..<50:
//			compassDistanceLabel.text = distance.friendlyString(0) + " m"
//		case 50..<1000:
//			compassDistanceLabel.text = (round(distance / 10) * 10).friendlyString(0) + " m"
//		default:
//			compassDistanceLabel.text = (distance / 1000).friendlyString(1).replacingOccurrences(of: ".", with: ",") + " km"
//		}
		compassDistanceLabel.text = distance.distanceString()
	}

	// MARK: - Pharus Pin Functions
	
	private func updatePharusPin(currentLocation: CLLocation, targetLocation: CLLocation, heading: CLHeading) {
		guard let pharusMap = pharusMap else { return }

		pharusMap.setCamera(MKMapCamera(lookingAtCenter: currentLocation.weightedMidPoint(fractionOfWay: 0.35, to: targetLocation),//currentLocation.midPoint(to: targetLocation),
										fromDistance: currentLocation.distance(from: targetLocation) * 3, //2.25,
										pitch: PharusMapView.Constants.pitch,
										heading: heading.trueHeading
		), animated: false)
	}
	
	func setAssistanceButtonForMapSwitch() {
		assistanceButton.set(style: .simplerMap) { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.pharusMap?.setMapOverlay(visible: false)
			weakSelf.assistanceButton.set(style: .pharusMap) {
				weakSelf.pharusMap?.setMapOverlay(visible: true)
				weakSelf.setAssistanceButtonForMapSwitch()
			}
		}
	}
	
	// MARK: - Clue Object Functions
	
	func setAssistanceButtonForHelpWithClueObject() {
		let helpCard = DialogueCard(style: .custom(Constants.helpWithClueObjectCardTitle, Constants.helpWithClueObjectCardBody, [
			DialogueCard.DialogueButton(title: "Weiterrätseln", action: {}),
			DialogueCard.DialogueButton(title: "Einfacheres Artefakt", action: { [weak self] in
				self?.downgradeNavigationObject()
			})
		]))
		helpCard.add(to: self.view)
		assistanceButton.set(style: .helpWithClueObject) {
			print("Getting help …")
			helpCard.presentCard()
		}
	}
	
	func downgradeNavigationObject() {
		self.clueObjectView?.container.removeAllActions()

		SCNTransaction.begin()

		if let containerNode = clueObjectView?.container {
			containerNode.opacity = 0
			containerNode.eulerAngles.z += 0.75 * .pi
			containerNode.position.y -= 9
		}
		
		SCNTransaction.animationDuration = 0.5
		SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
		
		SCNTransaction.completionBlock =  { DispatchQueue.main.async {
			self.topHubView.downgradeNavigationObject()

			self.clueObjectView?.removeFromSuperview()
			self.clueObjectTargetLocationView?.removeFromSuperview()
			
			self.navigationTool = Bool.random() ? .compass : .pharusPin
			
			self.targetPortal.downgradeNavigationTool(to: self.navigationTool)
			if
				let newTitle = Constants.topHubTitle[self.navigationTool.typeString],
				let newSubtitle = Constants.topHubSubtitle[self.navigationTool.typeString]
			{
				self.topHubView.updateContent(elementType: newTitle)
				self.topHubView.updateContent(elementType: newSubtitle)
			}
			
			switch self.navigationTool {
			case .compass:
				let needleImageView = UIImageView(image: UIImage(named: Constants.compassNeedleImageName))
				needleImageView.backgroundColor = .clear
				self.centerCircle.add(needleImageView, activate: [
					needleImageView.topAnchor.constraint(equalTo: self.centerCircle.topAnchor),
					needleImageView.bottomAnchor.constraint(equalTo: self.centerCircle.bottomAnchor),
					needleImageView.leftAnchor.constraint(equalTo: self.centerCircle.leftAnchor),
					needleImageView.rightAnchor.constraint(equalTo: self.centerCircle.rightAnchor)
				])
				needleImageView.alpha = 0
				self.compassNeedleImageView = needleImageView
				
				let distanceLabel = UILabel()
				distanceLabel.addCornerRadius(4)
				distanceLabel.backgroundColor = .dark60Branded
				distanceLabel.textColor = .whiteBranded
				distanceLabel.textAlignment = .center
				distanceLabel.font = UIFont.font(.light, size: 24)
				self.view.add(distanceLabel, activate: [
					distanceLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
					distanceLabel.bottomAnchor.constraint(equalTo: self.objectiveLabel.topAnchor, constant: -Constants.compassDistanceLabelMargin),
					distanceLabel.widthAnchor.constraint(equalToConstant: Constants.compassDistanceLabelSize.width),
					distanceLabel.heightAnchor.constraint(equalToConstant: Constants.compassDistanceLabelSize.height)
				])
				distanceLabel.alpha = 0
				self.compassDistanceLabel = distanceLabel
				
				UIView.animate(withDuration: 1) {
					needleImageView.alpha = 1
					distanceLabel.alpha = 1
					self.centerCircle.backgroundColor = .blueBranded
				}
				self.assistanceButton.set(style: .none) {}
				
			case .pharusPin:
				let mapView = PharusMapView(mode: .navigation)
				self.centerCircle.add(mapView, activate: [
					mapView.topAnchor.constraint(equalTo: self.centerCircle.topAnchor),
					mapView.bottomAnchor.constraint(equalTo: self.centerCircle.bottomAnchor),
					mapView.leftAnchor.constraint(equalTo: self.centerCircle.leftAnchor),
					mapView.rightAnchor.constraint(equalTo: self.centerCircle.rightAnchor)
				])
				mapView.addAnnotation(PharusAnnotation(portal: self.targetPortal))
				mapView.alpha = 0
				self.pharusMap = mapView
				
				UIView.animate(withDuration: 1) { mapView.alpha = 1 }
				self.setAssistanceButtonForMapSwitch()
				
			default: break
			}
			
			self.objectiveLabel.text = Constants.objectiveNavigationObject
		}}
		
		SCNTransaction.commit()
	}
	
	func activateProximityNavigation() {

		activatingProximityNavigation = true
		assistanceButton.set(style: .none) {}
		objectiveLabel.text =  Constants.objectiveClueObjectProximity
		
		let containerDimension = Constants.toolDiameterTiny + CGFloat(Constants.haloCount) * Constants.haloDiameterDeltaProximity
		
		let clueObjectTargetLocationView = UIView()
		clueObjectTargetLocationView.alpha = 0
		clueObjectTargetLocationCenterXConstraint = clueObjectTargetLocationView.centerXAnchor.constraint(equalTo: centerCircle.centerXAnchor)
		clueObjectTargetLocationCenterYConstraint = clueObjectTargetLocationView.centerYAnchor.constraint(equalTo: centerCircle.centerYAnchor)
		haloContainer.add(clueObjectTargetLocationView, activate: [
			clueObjectTargetLocationCenterXConstraint,
			clueObjectTargetLocationCenterYConstraint,
			clueObjectTargetLocationView.widthAnchor.constraint(equalToConstant: containerDimension),
			clueObjectTargetLocationView.heightAnchor.constraint(equalToConstant: containerDimension)
		])
		
		let targetColor = GameStateManager.shared.currentStory?.color ?? .white
		
		let targetObjectCircle = UIView()
		targetObjectCircle.transform = CGAffineTransform(rotationAngle: .pi/4)
		targetObjectCircle.backgroundColor = targetColor
		clueObjectTargetLocationView.add(targetObjectCircle, activate: [
			targetObjectCircle.centerXAnchor.constraint(equalTo: clueObjectTargetLocationView.centerXAnchor),
			targetObjectCircle.centerYAnchor.constraint(equalTo: clueObjectTargetLocationView.centerYAnchor),
			targetObjectCircle.widthAnchor.constraint(equalToConstant: Constants.toolDiameterTiny),
			targetObjectCircle.heightAnchor.constraint(equalToConstant: Constants.toolDiameterTiny)
		])
		
		for i in 1...Constants.haloCount {
			let diameterDelta = CGFloat(i) * Constants.haloDiameterDeltaProximity
			let haloCircle = UICircleView()
//			haloCircle.transform = CGAffineTransform(rotationAngle: .pi/4)
			haloCircle.backgroundColor = targetColor.withAlphaComponent(0.05)
			clueObjectTargetLocationView.add(haloCircle, activate: [
				haloCircle.centerXAnchor.constraint(equalTo: clueObjectTargetLocationView.centerXAnchor),
				haloCircle.centerYAnchor.constraint(equalTo: clueObjectTargetLocationView.centerYAnchor),
				haloCircle.widthAnchor.constraint(equalTo: targetObjectCircle.widthAnchor, constant: diameterDelta),
				haloCircle.heightAnchor.constraint(equalTo: targetObjectCircle.heightAnchor, constant: diameterDelta)
			])
		}
		
		self.clueObjectTargetLocationView = clueObjectTargetLocationView

		self.clueObjectView?.container.removeAllActions()

		SCNTransaction.begin()

		if let containerNode = clueObjectView?.container {
			containerNode.opacity = 0
			containerNode.scale = SCNVector3(uniform: 0)
		}
		
		SCNTransaction.animationDuration = 0.5
		SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
		
		SCNTransaction.completionBlock =  { DispatchQueue.main.async {
			UIView.animate(withDuration: 0.8, animations: {
				self.centerCircleWidthConstraint.constant = Constants.toolDiameterTiny
				self.centerCircleHeightConstraint.constant = Constants.toolDiameterTiny
				self.borderCircleWidthConstraint.constant = Constants.toolBorderDeltaProximity
				self.borderCircleHeightConstraint.constant = Constants.toolBorderDeltaProximity
				self.centerCircle.backgroundColor = .blueBranded
				self.borderCircle.backgroundColor = .dark60Branded
				for (i, haloWidthConstraint) in self.haloWidthConstraints.enumerated() {
					haloWidthConstraint.constant = CGFloat(i+1) * Constants.haloDiameterDeltaProximity
				}
				for (i, haloHeightConstraint) in self.haloHeightConstraints.enumerated() {
					haloHeightConstraint.constant = CGFloat(i+1) * Constants.haloDiameterDeltaProximity
				}
				self.view.layoutIfNeeded()
			}) { (_) in
				UIView.animate(withDuration: 0.2) {
					clueObjectTargetLocationView.alpha = 1
					self.activatingProximityNavigation = false
				}
			}
		}}
		
		SCNTransaction.commit()
	}
	
	private func updateProximityNavigation(distance: CLLocationDistance, trueBearing: CGFloat) {
		let containerDimension = Constants.toolDiameterTiny + CGFloat(Constants.haloCount) * Constants.haloDiameterDeltaProximity
		let radius = CGFloat(distance/Constants.enterProximityDistanceInMeters) * containerDimension/2
		
		let pointOnCircumference = CGPoint.onCircle(origin: .zero, radius: radius, angle: .pi + CGFloat(trueBearing.degreesToRadians))

		print("\(#function) – new position: \(pointOnCircumference) distance: \(distance), radius: \(radius)")
		
		UIView.animate(withDuration: 0.4) {
			self.clueObjectTargetLocationCenterXConstraint.constant = pointOnCircumference.x
			self.clueObjectTargetLocationCenterYConstraint.constant = pointOnCircumference.y
			self.view.layoutIfNeeded()
		}
	}
}

// MARK: - UIViewController Custom Modal Presentation

extension NavigatorViewController {
	public func setAnimationState(_ state: NavigatorPresentationAnimator.AnimationState) {
		NavigatorPresentationAnimator.activate(constraints: presentedAnimationConstraints, state: state)
		compassDistanceLabel?.alpha = state == .final ? 1 : 0
		objectiveLabel.alpha = state == .final ? 1 : 0
		view.layoutIfNeeded()
		outerMask.frame = outerMaskLayoutView.frame
		outerMask.layer.cornerRadius = outerMask.frame.size.width/2
	}
}

class NavigatorPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//		let presentationController = DimmedPopupPresentationController(presentedViewController: presented, presenting: presenting)
//		return presentationController
		return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NavigatorPresentationAnimator(direction: .to)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NavigatorPresentationAnimator(direction: .from)
    }
}

final class NavigatorPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	public enum AnimationState {
		case initial
		case intermediate
		case final
	}

	static public func activate(constraints: [[NavigatorPresentationAnimator.AnimationState: NSLayoutConstraint]], state activeState: NavigatorPresentationAnimator.AnimationState) {
		for constraintsDict in constraints {
			NSLayoutConstraint.deactivate(Array(constraintsDict.filter({ $0.0 != activeState }).values))
			NSLayoutConstraint.activate(constraintsDict.filter({ $0.0 == activeState }).map({ $0.1 }))
		}
	}
	
    let direction: UITransitionContextViewControllerKey
    
    init(direction: UITransitionContextViewControllerKey) {
        self.direction = direction
        super.init()
    }
    
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.8
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let presenting = direction == .to
		guard
			let navigatorVC = transitionContext.viewController(forKey: direction) as? NavigatorViewController,
			let parentVC = transitionContext.viewController(forKey: presenting ? .from : .to) as? NavigatorPresenter
		else { return }
		
		transitionContext.containerView.addSubview(navigatorVC.view)

		if !presenting { parentVC.updateNavigatorButton() }
		
		let initialAlpha: CGFloat = presenting ? 0 : 1
		let finalAlpha: CGFloat = presenting ? 1 : 0

		navigatorVC.view.alpha = initialAlpha
		navigatorVC.setAnimationState(presenting ? .initial : .final)
		parentVC.setAnimationState(presenting ? .initial : .final)
		
		UIView.animate(withDuration: transitionDuration(using: transitionContext)/2, delay: 0, animations: {
			if presenting { navigatorVC.view.alpha = finalAlpha }
			navigatorVC.setAnimationState(.intermediate)
			parentVC.setAnimationState(.intermediate)
		}) { (_) in
			UIView.animate(withDuration: self.transitionDuration(using: transitionContext)/2, delay: 0, animations: {
				if !presenting { navigatorVC.view.alpha = finalAlpha }
				navigatorVC.setAnimationState(presenting ? .final : .initial)
				parentVC.setAnimationState(presenting ? .final : .initial)
			}) { finished in
				transitionContext.completeTransition(finished)
			}
		}
	}
}

final class SlideInPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: UITransitionContextViewControllerKey
    
    init(direction: UITransitionContextViewControllerKey) {
        self.direction = direction
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.75
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let controller = transitionContext.viewController(forKey: direction) else { return }

        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        
		if direction == .to {
            transitionContext.containerView.addSubview(controller.view)
        }
		dismissedFrame.origin.y += direction == .to ? presentedFrame.height : dismissedFrame.height

		let initialFrame = direction == .to ? dismissedFrame : presentedFrame
		let finalFrame = direction == .to ? presentedFrame : dismissedFrame
        
        controller.view.frame = initialFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
			controller.view.frame = finalFrame
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
