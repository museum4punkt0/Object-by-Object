import UIKit
import ARKit

protocol PortalSessionSource {
	var objects: [Object]? { get }
	var navigatorTool: NavigatorToolObjectType? { get }
	var worldMap: ARWorldMap? { get }
}

class PortalSessionViewController: UIViewController, InteractiveARSessionController, PortalSessionDelegate, HintImageDelegate, ARSCNViewDelegate, ARSessionDelegate, ARCoachingOverlayViewDelegate {
	// Enumerations
	enum Options: Equatable {
		case planeDetection(ARWorldTrackingConfiguration.PlaneDetection)
		case showCoaching
	}

	// Structs
	struct Constants {
		static let shutterDiameter: CGFloat = 350
		static let initialHintTimerInterval: TimeInterval = 5
		static let upgradeHintTimerInterval: TimeInterval = 10
		static let portalHintTimerInterval: TimeInterval = 5
		static let nextObjectHintTimerInterval: TimeInterval = 10
		static let userMovementThreshold: Float = 1
		static let assistanceButtonHeight: CGFloat = 64
		static let assistanceButtonWidth: CGFloat = 320
		static let reconciliationTimeout: TimeInterval = 60
	}
	
	struct Requirements {
        static var sessionObjectswithHorizontalAlignment = [String: VirtualObject]()
		
        static var minimalRequiredHorizontalPlaneSize: CGSize {
			let portalBoundingBox: SCNVector3? = sessionObjectswithHorizontalAlignment.filter({ $0.value.id == StandardObjectType.portal.id }).map({ $0.value.boundingBox.max - $0.value.boundingBox.min }).first
            let sessionObjectBoundingBoxes: [SCNVector3] = sessionObjectswithHorizontalAlignment.filter({ $0.value.id != StandardObjectType.portal.id }).map({ $0.value.boundingBox.max - $0.value.boundingBox.min })
			
			return horizontalPlaneSize(sessionObjectBoundingBoxes: sessionObjectBoundingBoxes, portalBoundingBox: portalBoundingBox)
        }
        
        private static func horizontalPlaneSize(sessionObjectBoundingBoxes: [SCNVector3], portalBoundingBox: SCNVector3?) -> CGSize {
			let minimumDistanceInBetweenObjects: Float = 0.8
			
            if sessionObjectBoundingBoxes.isEmpty {
                return CGSize.zero
            }

            if sessionObjectBoundingBoxes.count == 1 && portalBoundingBox == nil {
                // Return bounding box only
                let width: CGFloat = CGFloat(sessionObjectBoundingBoxes[0].x)
                let depth: CGFloat = CGFloat(sessionObjectBoundingBoxes[0].z)
                return CGSize(width: width, height: depth)
			} else {
				var portalWidth: Float = 0
				if let portalBoundingBox = portalBoundingBox {
					portalWidth = portalBoundingBox.x
				}
				let minimumDiameterBasedOnPortalWidth = portalWidth + Float(minimumDistanceInBetweenObjects)
				var sessionObjectsWidthInTotal: Float {
					var totalWidth: Float = 0
					for boundingBox in sessionObjectBoundingBoxes {
						totalWidth += boundingBox.x
					}
					return totalWidth
				}
				let minimumPadding = minimumDistanceInBetweenObjects * Float(sessionObjectBoundingBoxes.count - 1)
				let minimumCircumference = sessionObjectsWidthInTotal + minimumPadding
				let minimumDiameterBasedOnCircumference = (minimumCircumference / .pi) * 2.0 // Double the value to represent a half-circle
				
				let minimumDiameter = minimumDiameterBasedOnPortalWidth > minimumDiameterBasedOnCircumference ? minimumDiameterBasedOnPortalWidth : minimumDiameterBasedOnCircumference
				
				return CGSize(width: CGFloat(minimumDiameter), height: CGFloat(minimumDiameter))
			}
		}
	}
	
	struct Planes {
		static var horizontal = [UUID: ARPlaneAnchor]()
		static var vertical = [UUID: ARPlaneAnchor]()
		static var largestHorizontalPlaneSoFar: ARPlaneAnchor?
		
		public static func add(_ anchor: ARPlaneAnchor) {
			switch anchor.alignment {
			case .horizontal:
				horizontal[anchor.identifier] = anchor
			case .vertical:
				vertical[anchor.identifier] = anchor
			default:
				break
			}
		}
		
		public static func update(_ anchor: ARPlaneAnchor) {
			add(anchor)
		}
		
		public static func remove(_ anchor: ARPlaneAnchor) {
			switch anchor.alignment {
			case .horizontal:
				horizontal.removeValue(forKey: anchor.identifier)
			case .vertical:
				vertical.removeValue(forKey: anchor.identifier)
			default:
				break
			}
		}
		
		public static func findHorizontalPlaneAnchor(minimumSize: CGSize) -> ARPlaneAnchor? {
			for (_, planeAnchor) in horizontal {
				if planeAnchor.extent.x >= Float(minimumSize.width) && planeAnchor.extent.z >= Float(minimumSize.height) {
					return planeAnchor
				} else {
					updateLargestPlaneAnchor(with: planeAnchor)
				}
			}
			return nil
		}
		
		private static func updateLargestPlaneAnchor(with planeAnchor: ARPlaneAnchor) {
			if let largestPlane = largestHorizontalPlaneSoFar {
				if (planeAnchor.extent.x * planeAnchor.extent.z) > (largestPlane.extent.x * largestPlane.extent.z) {
					largestHorizontalPlaneSoFar = planeAnchor
				}
			} else {
				largestHorizontalPlaneSoFar = planeAnchor
			}
		}
	}

	// Properties
	private let source: PortalSessionSource
	public var portal: Portal? {
		return source as? Portal
	}
	private var story: Story? {
		return source as? Story
	}
	private let worldMap: ARWorldMap?
	private let objects: [Object]?
	private let navigatorTool: NavigatorToolObjectType?

	private var sessionObjects = [String: VirtualObject]()
	private var portalObject: VirtualObject? {
		Array(sessionObjects.values).first(where: {$0.name == StandardObjectType.portal.id})
	}
	private var nextObjectToPointOut: VirtualObject? {
		if !hasEnteredPortal { return portalObject }
		
		for (key, object) in sessionObjects {
			print("Key: \(key):")
			switch object.objectType {
			case .contentful(_):
				print("    objectType: contentful")
			default:
				print("    objectType: other")
			}
			print("    combinationState: \(object.combinationState.rawValue)")
			print("    object.state: \(object.object?.state.rawValue ?? "---")")
		}
		
		if let collectionObject = sessionObjects.values.first(where: {
			if case .contentful(_) = $0.objectType {
				return ($0.combinationState == .complete && $0.object?.state != .collected) || ($0.combinationState == .incompleteMoveable)
			}
			return false
		}) {
			return collectionObject
		}
		
		return sessionObjects.values.first(where: {
			if case .navigatorTool(_) = $0.objectType { return true }
			return false
		})
	}
	
	private lazy var pointingArrow: VirtualObject = {
		let arrow = VirtualObject(from: .indexHand, controller: objectController)
		var preloadedModels = [String : SCNNode]()
		arrow.loadModel(preloadedModels: &preloadedModels)
		arrow.opacity = 0
		arrow.isHidden = true
		self.sceneView.scene.rootNode.addChildNode(arrow)
		return arrow
	}()

	private var currentGesture: Gesture? {
		get {
			return objectController.currentGesture
		}
		set {
			objectController.currentGesture = newValue
		}
	}
	private let objectController: VirtualObjectManipulator
	private var portalController: PortalController?
	private var planeDetectionAlignment: ARWorldTrackingConfiguration.PlaneDetection = .horizontal
	@available(iOS 13.0, *)
    private lazy var coachingOverlayGoal: ARCoachingOverlayView.Goal = .horizontalPlane

	// Checks
	private var showCoaching: Bool = false
	private lazy var isInitialWorldMapPresent: Bool = worldMap != nil
	private lazy var isAdHocSession: Bool = worldMap == nil
	private var objectsArePositionedInAdHocSession = false
	public var isWorldMapped = false
	public var isMissionCompleted = false
	private var userHasMoved = false

	private var userPositions = [SCNVector3]()
	private var currentUserMovement: Float {
		var movementInTotal: Float = 0
		guard userPositions.count > 1 else { return movementInTotal }

		for i in 1..<userPositions.count {
			movementInTotal += (userPositions[i] - userPositions[i-1]).length()
		}
		return movementInTotal
	}

	// Helpers
	private var screenCenter = UIScreen.main.bounds.size.mid
	private var mapSize: Int = 0 {
		didSet { logView.mapSize = mapSize }
	}
	private var unanchoredModelKeys = [String]()
	private var offsetAngleForAdHocPosition: Float = 0

	// Views
	private let sceneView = InteractiveARSceneView()
	private let sessionNotificationView = SessionNotificationView()
	private let logView = LogView()
	@available(iOS 13.0, *)
    private lazy var coachingOverlay = ARCoachingOverlayView()
	private lazy var outerMask: UICircleView = {
		let circle = UICircleView()
		circle.backgroundColor = UIColor.blueBranded
		return circle
	}()
	private lazy var outerMaskLayoutView: UIPassThroughView = {
		let view = UIPassThroughView()
		view.backgroundColor = .dark80Branded
		return view
	}()
	private let navigatorToolColorView = UIPassThroughView()
	private lazy var sessionProgressView = SessionProgressView(portalNumber: portal?.numberInStory ?? 0,
															   objectsInTotal: portal?.objects?.count ?? 0,
															   objectsCollected: portal?.numberOfCollectedObjects ?? 0,
															   isPortalStoryCollected: portal?.portalStoryState == .collected)
	private var hintView: HintView?
	private lazy var startAdHocButton = AssistanceButton(style: .startAdHocSession, selectAction: { [weak self] in
		guard let self = self else { return }
		self.resetAsAdhoc()	})
	private let dimmerView = DimmerView()

	// View Constraints
	private var outerMaskWidthConstraint = NSLayoutConstraint()
	private var outerMaskHeightConstraint = NSLayoutConstraint()
	private var hintViewConstraint: NSLayoutConstraint?

	// View Helpers
	private lazy var closeButtonHub = HubView(blueprint: HubViewBlueprint(
		centerViewLayout: .hidden,
		centerViewTopElement: nil,
		centerViewBottomElement: nil,
		topLeftButtonStyle: .hidden,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .close,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: {},
		bottomLeftButtonAction: {},
		topRightButtonAction: { [weak self] in
			self?.closeButtonPressed()
		},
		bottomRightButtonAction: {}
	))
	
	private lazy var pointOutHintButtonHub = HubView(blueprint: HubViewBlueprint(
		centerViewLayout: .hidden,
		centerViewTopElement: nil,
		centerViewBottomElement: nil,
		topLeftButtonStyle: .hidden,
		bottomLeftButtonStyle: .hidden,
		topRightButtonStyle: .hidden,
		bottomRightButtonStyle: .hidden,
		topLeftButtonAction: {},
		bottomLeftButtonAction: {},
		topRightButtonAction: {},
		bottomRightButtonAction: {}
	))

	// Timers
	private var logTimer: Timer? {
		willSet { logTimer?.invalidate() }
	}
	private var hintTimer: Timer? {
		willSet { hintTimer?.invalidate() }
	}
	private var reconciliationTimeout: Timer? {
		willSet { reconciliationTimeout?.invalidate() }
	}
	private var simplifyPlaneRequirementsTimeout: Timer?
	private var endSessionTimeout: Timer?
	private var userMovementTimer: Timer?

	private var contentCollectionDialogue: DialogueCard?
	private lazy var speechSynthesizer = AVSpeechSynthesizer()

	init(from source: PortalSessionSource, options: [Options] = []) {
		self.source = source
		self.objects = source.objects
		self.worldMap = source.worldMap
		self.navigatorTool = source.navigatorTool
		
//		for (i, object) in (portal.objects ?? []).enumerated() {
//			switch i % 3 {
//				case 0: object.setState(.hidden)
//				case 1: object.setState(.seen)
//				case 2: object.setState(.collected)
//				default: break
//			}
//		}
//		for object in portal.objects ?? [] {
//			print("Object »\(object.title ?? "---")« state: \(object.state.rawValue)")
//

		self.objectController = VirtualObjectManipulator(sceneView)
		self.portalController = PortalController(sceneView)

		super.init(nibName: nil, bundle: nil)
		set(options: options)

		Planes.largestHorizontalPlaneSoFar = nil
		
		self.sceneView.sessionController = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("PortalSessionViewController deinitialized")
		Planes.largestHorizontalPlaneSoFar = nil
		Planes.horizontal = [:]
		Planes.vertical = [:]
		Requirements.sessionObjectswithHorizontalAlignment = [:]
	}

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()

		GameStateManager.shared.portalSessionDelegate = self

		sceneView.showsStatistics = false
		view.add(sceneView, activate: [
			sceneView.topAnchor.constraint(equalTo: view.topAnchor),
			sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
			sceneView.leftAnchor.constraint(equalTo: view.leftAnchor)
		])
		sceneView.mask = outerMask

		navigationController?.setNavigationBarHidden(true, animated: false)
		
		// Outer Mask
		outerMaskWidthConstraint = outerMaskLayoutView.widthAnchor.constraint(equalToConstant: 0)
		outerMaskHeightConstraint = outerMaskLayoutView.heightAnchor.constraint(equalToConstant: 0)
		sceneView.add(outerMaskLayoutView, activate: [
			outerMaskLayoutView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			outerMaskLayoutView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -NavigatorViewController.Constants.offCenterCorrection),
			outerMaskWidthConstraint,
			outerMaskHeightConstraint
		])

		// DimmerView
		view.add(dimmerView, activate: [
			dimmerView.leftAnchor.constraint(equalTo: view.leftAnchor),
			dimmerView.rightAnchor.constraint(equalTo: view.rightAnchor),
			dimmerView.topAnchor.constraint(equalTo: view.topAnchor),
			dimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		// NotificationView
		view.add(sessionNotificationView, activate: [
			sessionNotificationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			sessionNotificationView.widthAnchor.constraint(equalTo: view.widthAnchor),
			sessionNotificationView.topAnchor.constraint(equalTo: view.topAnchor),
		])

		// Close Button Container
		// Squeezes when notification is presented to move vertically centered close button only fraction of vertical delta
		let closeButtonContainer = UIPassThroughView()
		view.add(closeButtonContainer, activate: [
			closeButtonContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
			closeButtonContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
			closeButtonContainer.topAnchor.constraint(equalTo: sessionNotificationView.containerView.bottomAnchor),
			closeButtonContainer.bottomAnchor.constraint(equalTo: view.topAnchor, constant: view.safeAreaInsets.top + HubView.Constants.topPadding + HubView.Constants.totalHeight)
		])
		
		// Close Button (Hub)
		closeButtonContainer.add(closeButtonHub, activate: [
			closeButtonHub.centerXAnchor.constraint(equalTo: closeButtonContainer.centerXAnchor),
			closeButtonHub.centerYAnchor.constraint(equalTo: closeButtonContainer.centerYAnchor, constant: (view.safeAreaInsets.top + HubView.Constants.topPadding) / 2),
			closeButtonHub.widthAnchor.constraint(equalTo: closeButtonContainer.widthAnchor, constant: -2 * HubView.Constants.horizontalPadding)
		])
		closeButtonHub.alpha = 0

		// SessionProgressView
		sessionProgressView.isHidden = true
//		view.add(sessionProgressView, activate: [
//			sessionProgressView.leftAnchor.constraint(equalTo: view.leftAnchor,
//													  constant: 8),
//			sessionProgressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
//		])
		closeButtonContainer.add(sessionProgressView, activate: [
			sessionProgressView.leftAnchor.constraint(equalTo: closeButtonContainer.leftAnchor, constant: 8),
			sessionProgressView.centerYAnchor.constraint(equalTo: closeButtonContainer.centerYAnchor, constant: (view.safeAreaInsets.top - 108) / 2)
		])
		
		// NavigatorToolColorView
		navigatorToolColorView.backgroundColor = .clear
		view.add(navigatorToolColorView, activate: [
			navigatorToolColorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			navigatorToolColorView.widthAnchor.constraint(equalTo: view.widthAnchor),
			navigatorToolColorView.topAnchor.constraint(equalTo: view.topAnchor),
			navigatorToolColorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		// AdHocButton
		if !isAdHocSession {
			startAdHocButton.alpha = 0
			startAdHocButton.isHidden = true
			view.add(startAdHocButton, activate: [
				startAdHocButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
				startAdHocButton.topAnchor.constraint(equalTo: outerMaskLayoutView.bottomAnchor, constant: 64),
				startAdHocButton.widthAnchor.constraint(equalToConstant: Constants.assistanceButtonWidth),
				startAdHocButton.heightAnchor.constraint(equalToConstant: Constants.assistanceButtonHeight)
			])
		}

		view.add(pointOutHintButtonHub, activate: [
			pointOutHintButtonHub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			pointOutHintButtonHub.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -HubView.Constants.bottomPadding),
			pointOutHintButtonHub.leftAnchor.constraint(equalTo: view.leftAnchor, constant: HubView.Constants.horizontalPadding),
			pointOutHintButtonHub.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -HubView.Constants.horizontalPadding)
		])

		// HintView
		if !isAdHocSession {
			if portal?.hintImage?.loadImage() == nil && portal?.hintText == nil {
				return
			}

			hintView = HintView(portal: portal)
			guard let hintView = hintView else { return }

			hintView.delegate = self

			hintViewConstraint = NSLayoutConstraint(item: hintView.topView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1.0, constant: 120)

			guard let hintViewConstraint = hintViewConstraint else { return }

			view.add(hintView, activate: [
				hintView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
				hintViewConstraint
			])
		}
	}

	internal func animateHint(to state: HintView.State) {
		guard
			let hintView = hintView,
			let hintViewConstraint = hintViewConstraint
			else { return }

		switch state {
		case .hidden:
			UIView.animate(withDuration: 0.5, animations: {
				hintViewConstraint.constant = 120
				hintView.layoutIfNeeded()
				self.view.layoutIfNeeded()
			}, completion: { success in
				if success {
					hintView.state = state
				}
			})
		case .fullDisplay:
			UIView.animate(withDuration: 0.5, animations: {
				let buttonHeight: CGFloat = hintView.buttonIsDisplayed ? 64 : 0
				hintViewConstraint.constant = -(hintView.bottomView.bounds.height + hintView.verticalPaddingOutside + buttonHeight - 64)
				hintView.layoutIfNeeded()
				self.view.layoutIfNeeded()
			}, completion: { success in
				if success {
					hintView.state = state
				}
			})
		case .partDisplay:
			UIView.animate(withDuration: 0.5, animations: {
				hintViewConstraint.constant = -32
				hintView.layoutIfNeeded()
				self.view.layoutIfNeeded()
			}, completion: { success in
				if success {
					hintView.state = state
				}
			})
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		activate()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		hintTimer?.invalidate()
		userMovementTimer?.invalidate()
		reconciliationTimeout?.invalidate()
		simplifyPlaneRequirementsTimeout?.invalidate()
		logTimer?.invalidate()
		endSessionTimeout?.invalidate()
		sceneView.session.pause()
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		screenCenter = size.mid
	}

	override var prefersHomeIndicatorAutoHidden: Bool {
		return true
	}
	
	// MARK: - Transitions
	
	public func openShutterHalf() {
		setShutter(Constants.shutterDiameter)
	}
	public func openShutterFull() {
		setShutter(sqrt(pow(self.view.frame.size.width + 2*NavigatorViewController.Constants.offCenterCorrection, 2) + pow(self.view.frame.size.height + 2*NavigatorViewController.Constants.offCenterCorrection, 2)))
	}

	private func setShutter(_ newMaskDiameter: CGFloat) {
		self.outerMaskWidthConstraint.constant = newMaskDiameter
		self.outerMaskHeightConstraint.constant = newMaskDiameter
		self.view.layoutIfNeeded()
		self.updateOuterMask()
	}
	
	public func fadeInCameraView() {
		self.closeButtonHub.alpha = 1
		self.outerMaskLayoutView.alpha = 0
	}
	
	public func updateOuterMask() {
		self.outerMask.frame = self.outerMaskLayoutView.frame
		self.outerMask.layer.cornerRadius = self.outerMask.frame.size.width/2
	}
	
	// MARK: -

	private var userMovementTimerCount: Int = 0

	func activate() {
		// setupLogView()
		
		startSession()
		
		sceneView.delegate = self
		sceneView.session.delegate = self

		// Track user movement
		userMovementTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
			guard let self = self else { return }
			self.userMovementTimerCount += 1

			if let cameraTransform = self.sceneView.session.currentFrame?.camera.transform {
				self.userPositions.append(SCNVector3.positionFromTransform(cameraTransform))
			}

			if self.currentUserMovement > Constants.userMovementThreshold {
				self.sessionNotificationView.forceDismiss()
				self.animateHint(to: .fullDisplay)
				self.userMovementTimer?.invalidate()
			} else if self.userMovementTimerCount == 10 {
				self.sessionNotificationView.notification(for: .userShouldMove)
				self.animateHint(to: .partDisplay)
			}
		})

		// Hint View Activation
		guard let hintView = hintView else { return }

		hintTimer = Timer.scheduledTimer(withTimeInterval: Constants.initialHintTimerInterval, repeats: false, block: { [weak self] _ in
			guard let self = self else { return }
			self.animateHint(to: .fullDisplay)

			self.hintTimer = Timer.scheduledTimer(withTimeInterval: Constants.upgradeHintTimerInterval, repeats: false, block: { [weak self] _ in
				guard let self = self else { return }
				hintView.showUpgradeButton()
				if hintView.state != .hidden {
					self.animateHint(to: .fullDisplay)
				}
			})
		})

		// Load lazy pointingArrow
		pointingArrow.opacity = 0
	}

	private func set(options: [PortalSessionViewController.Options]) {
		for option in options {
			switch option {
            case .planeDetection(let alignments):
                planeDetectionAlignment = alignments
			case .showCoaching:
				showCoaching = true
			}
		}
	}

	private func setupLogView() {
		logView.mapTitle = portal?.title ?? "[Portal Title Missing]"
		logView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(logView)

		logTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (_) in
			self.logView.mapStatus = self.sceneView.session.currentFrame?.worldMappingStatus ?? .notAvailable
		})
		
		
		NSLayoutConstraint.activate([
			logView.leftAnchor.constraint(equalTo: view.leftAnchor),
			logView.rightAnchor.constraint(equalTo: view.rightAnchor),
			logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -19.0),
			logView.heightAnchor.constraint(equalToConstant: 50.0)
		])
	}


	private func startSession() {
		setupSessionObjects()
		
		if isAdHocSession {
            // Setup session requirements
			setupAdHocSession()
		}
		else {
			// Do not provide the option to start an ad-hoc-session yourself

			reconciliationTimeout = Timer.scheduledTimer(withTimeInterval: Constants.reconciliationTimeout, repeats: false, block: { [weak self] (_) in
				guard let self = self else { return }
				DispatchQueue.main.async {
					self.animateHint(to: .partDisplay)

					self.startAdHocButton.isHidden = false
					UIView.animate(withDuration: 0.5, animations: {
						self.startAdHocButton.alpha = 1.0
					})
				}
			})
		}

		let options: ARSession.RunOptions = [.removeExistingAnchors]
        let configuration: ARWorldTrackingConfiguration = isAdHocSession ? setupAdHocConfiguration() : setupWorldMapConfiguration()

		sceneView.session.run(configuration, options: options)
	}
	
	private func setupAdHocSession() {
//		Requirements.sessionObjectswithHorizontalAlignment = sessionObjects.filter({ $0.value.desiredAlignment == .horizontal })
		
		Requirements.sessionObjectswithHorizontalAlignment = sessionObjects.filter({ $0.value.desiredAlignment == .horizontal ||
			$0.value.desiredAlignment == .vertical ||
			$0.value.desiredAlignment == .horizontalVertical ||
			$0.value.desiredAlignment == .horizontalVerticalIfAvailable
		})
		
		simplifyPlaneRequirementsTimeout = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
			if !self.objectsArePositionedInAdHocSession {
				if let largestPlaneSoFar = Planes.largestHorizontalPlaneSoFar {
					let sessionObjectsWithHorizontalAlignment = Requirements.sessionObjectswithHorizontalAlignment.map({ $0.value })
					self.placeSessionObjectsInScene(sessionObjectsHorizontal: sessionObjectsWithHorizontalAlignment, horizontalAnchor: largestPlaneSoFar)
				} else {
					print("Warning: No plane has been found to place on")
				}
			}
		}
	}
	
	private func setupSessionObjects() {

		var sessionObjectKeys = [String]()
		
		for object in source.objects ?? [] {
			if let fragmentation = object.fragmentation?.intValue, fragmentation > 1 {
				var referenceObjectKey = ""
				for fragmentIndex in 0..<fragmentation {
					print("Creating session object fragment »\(object.title ?? "---")« \(fragmentIndex+1)/\(fragmentation) …")
					let objectKey = "\(object.id)_\(fragmentIndex)"
					switch fragmentIndex {
					case 0:
						referenceObjectKey = objectKey
						sessionObjects[objectKey] = VirtualObject(from: object,
																  controller: objectController,
																  fragmentIndex: fragmentIndex)
					default:
						let fragmentObject = VirtualObject(from: object,
														   controller: objectController,
														   fragmentIndex: fragmentIndex,
														   fragmentReferenceObject: sessionObjects[referenceObjectKey])
						sessionObjects[objectKey] = fragmentObject
						sessionObjects[referenceObjectKey]?.fragmentSecondaryObjects.append(fragmentObject)
					}
					
					
					sessionObjectKeys.append(objectKey)
				}
			}
			else {
				print("Creating session object »\(object.title ?? "---")« …")
				sessionObjects[object.id] = VirtualObject(from: object, controller: objectController)
				sessionObjectKeys.append(object.id)
			}
		}
		
		sessionObjects[StandardObjectType.portal.id] = VirtualObject(from: .portal, controller: objectController)
		sessionObjectKeys.append(StandardObjectType.portal.id)

		var preloadedModels = [String: SCNNode]()
		for (_, object) in sessionObjects {
			object.loadModel(preloadedModels: &preloadedModels)
		}

		var array: [SCNNode] = []
		for (_, value) in preloadedModels {
			array.append(value)
		}
		DispatchQueue.updateQueue.async { [weak self] in
			self?.sceneView.prepare(array, completionHandler: { result in
				print("Preparation successful: \(result)")
			})
		}
		
//		unanchoredModelKeys = Array(preloadedModels.keys)
		unanchoredModelKeys = sessionObjectKeys
	}

	// MARK: - Pointing Arrow
//	var pointingArrowFadingOut = false
	
	private func placePointingArrow() {
		print("\(#function)")
		guard pointingArrow.isHidden else { return }

		hidePointOutHintButton()

		pointingArrow.opacity = 0
		pointingArrow.isHidden = false

//		pointingArrow.runAction(SCNAction.fadeIn(duration: 0.25))
		pointingArrow.isHidden = false

	}
	
	private func orientPointingArrow() {
		guard
			pointingArrow.isHidden == false,
//			pointingArrowFadingOut == false,
			let objectToPointOut = nextObjectToPointOut,
			let pointOfView = sceneView.pointOfView,
			let cameraPosition = sceneView.session.currentFrame?.camera.transform.position
		else { return }

		let basicTransform = SCNMatrix4(position: SCNVector3(0, 0, -0.5), eulerAngles: SCNVector3(x: .pi/2, y: 0, z: 0))
		
		let arrowTransform = sceneView.scene.rootNode.convertTransform(basicTransform, from: pointOfView)
 		
		var objectToPointOutY = arrowTransform.position.y
		if arrowTransform.position.y > objectToPointOut.transformedBoundingBox.max.y {
			objectToPointOutY = objectToPointOut.transformedBoundingBox.max.y
		}
		else if arrowTransform.position.y < objectToPointOut.transformedBoundingBox.min.y {
			objectToPointOutY = objectToPointOut.transformedBoundingBox.min.y
		}
		
		let pp = SCNVector3(objectToPointOut.position.x, objectToPointOutY, objectToPointOut.position.z)
		let ap = arrowTransform.position
		let a2o = pp-ap
		
		let arrowDirection = atan(a2o.x / a2o.z) + (a2o.z > 0 ? .pi : 0)
		let arrowPitch = -atan2(sqrt(a2o.x*a2o.x + a2o.z*a2o.z), a2o.y) + .pi/2
		
		let distanceFromArrow = a2o.length()
		let distanceFromCamera = (SCNVector3(pp.x, 0, pp.z) - SCNVector3(cameraPosition.x, 0, cameraPosition.z)).length()
		let distance = min(distanceFromArrow, distanceFromCamera)
		
		pointingArrow.opacity = CGFloat(min(max(0, distance * 2 - 1), 1))
		print("Distance: \(distance) -> Opacity: \(pointingArrow.opacity)")

		pointingArrow.position = arrowTransform.position
		pointingArrow.eulerAngles.y = arrowDirection
		pointingArrow.eulerAngles.x = arrowPitch
	}
	
	private func removePointingArrow() {
		pointingArrow.isHidden = true
		scheduleNextPointOutHint()
	}
	
	private func scheduleNextPointOutHint() {
		let timeInterval = nextObjectToPointOut == portalObject ? Constants.portalHintTimerInterval : Constants.nextObjectHintTimerInterval
		
		self.hintTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { [weak self] _ in
			self?.showPointOutHintButton()
		})
	}
	
	private func showPointOutHintButton() {
		guard  let nextObject = nextObjectToPointOut else {
			print("Object to point out: ---")
			return
		}
		print("Object to point out: \(nextObject.id)")
		pointOutHintButtonHub.setButton(position: .bottomRight, type: .hint, action: { [weak self] in
			self?.placePointingArrow()
		})
	}
	
	private func hidePointOutHintButton() {
		pointOutHintButtonHub.setButton(position: .bottomRight, type: .hidden, action: {})
	}
	
	// MARK: -
	
	public func placeNavigatorTool(distanceToPortal: Float) {
		// Place the navigator tool right in front of the portal
		guard
			let navigatorTool = source.navigatorTool,
			let portal = sessionObjects[StandardObjectType.portal.id],
			let currentFrameCamera = sceneView.session.currentFrame?.camera
		else { return }

		let navigatorToolObject = VirtualObject(from: navigatorTool, controller: objectController)
		sessionObjects[navigatorTool.id] = navigatorToolObject

		// Add navigatorTool to session
		var preloadedModels = [String: SCNNode]()
		navigatorToolObject.loadModel(preloadedModels: &preloadedModels)

		var array: [SCNNode] = []
		for (_, value) in preloadedModels {
			array.append(value)
		}
		DispatchQueue.updateQueue.async { //[weak self] in
			self.sceneView.prepare(array, completionHandler: { result in
				print("Preparation successful: \(result)")
			})
		}

		let cameraPosition = SCNVector3.positionFromTransform(currentFrameCamera.transform)
		let navigatorToolPosition = navigatorToolObject.navigatorToolPosition(playerPosition: cameraPosition, portalPosition: portal.position, portalRotation: portal.eulerAngles.y, distanceToPortal: distanceToPortal)

		navigatorToolObject.position = navigatorToolPosition
		navigatorToolObject.eulerAngles = portal.eulerAngles

		for material in navigatorToolObject.allMaterials {
			material.transparency = 0.0
		}

		sceneView.scene.rootNode.addChildNode(navigatorToolObject)
		navigatorToolObject.updateAnchor(in: sceneView.session, requireExistingAnchor: false)

		// Animate navigator tool
		let innerRing = navigatorToolObject.childNode(withName: "inner", recursively: true)
		let outerRing = navigatorToolObject.childNode(withName: "outer", recursively: true)

		// Intro Animation
		let appearAnimation = {
			SCNAction.run { (node) in
				SCNTransaction.begin()
				SCNTransaction.animationDuration = 2

				navigatorToolObject.position.y -= 0.7
				outerRing?.eulerAngles.y += 10 * .pi
				innerRing?.eulerAngles.y -= 10 * .pi

				for material in navigatorToolObject.allMaterials {
					material.transparency = 1.0
				}

				SCNTransaction.completionBlock = {
					SCNTransaction.begin()
					SCNTransaction.animationDuration = 1

					navigatorToolObject.position.y += 0.2
					innerRing?.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))
					outerRing?.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: -1, z: 0, duration: 1)))

					SCNTransaction.commit()
				}

				SCNTransaction.commit()
			}
		}

		navigatorToolObject.runAction(appearAnimation())

		// Collect Animation

		navigatorToolObject.action.onTouchActions.append {
			return SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 1))
		}
		navigatorToolObject.action.onTouchActions.append { [weak self] in
			SCNAction.run { (node) in
				SCNTransaction.begin()
				SCNTransaction.animationDuration = 0.5

				navigatorToolObject.position.y -= 0.2

				SCNTransaction.completionBlock = {
					SCNTransaction.begin()
					SCNTransaction.animationDuration = 2

					navigatorToolObject.position.y += 0.5

					SCNTransaction.commit()
				}

				SCNTransaction.commit()

				let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
				impactFeedbackgenerator.prepare()
				impactFeedbackgenerator.impactOccurred()

				// Update GameState
				DispatchQueue.main.async {
					if let weakSelf = self {
						GameStateManager.shared.trigger(.navigatorToolCollected(weakSelf.source))
					}
				}
			}
		}

		GameStateManager.shared.trigger(.navigatorToolAppeared(source))
	}

	internal func portalAppeared() -> Void {
		animateHint(to: .hidden)
		hintTimer = nil

		userMovementTimer?.invalidate()

		updateViewToStartSession()
		var runFollowUp = true
		if let story = story {
			runFollowUp = story.state != .notStarted
		}
		else if let portal = portal {
			runFollowUp = portal.portalStoryState != .collected
		}
		sessionNotificationView.notification(for: .portalAppeared, runFollowUp: runFollowUp)
		
//		self.hintTimer = Timer.scheduledTimer(withTimeInterval: Constants.portalHintTimerInterval, repeats: false, block: { [weak self] _ in
//			self?.showPointOutHintButton()
//		})
		scheduleNextPointOutHint()
	}
	
	internal func portalEntered() -> Void {

		var optionalDialogue: DialogueCard? = nil
		sessionNotificationView.portalEntered = true
		
		removePointingArrow()
		
		if let story = story {
			// Session Zero
			optionalDialogue = DialogueCard(style: .storyIntro(story))
		}
		else if let portal = portal {
			// Regular session
			sessionProgressView.isHidden = false
			
			// Did not pick up navigation artefact in previous session
			if portal.state == .allObjectsCollected {
				self.placeNavigatorTool(distanceToPortal: 2.0)
				return
			}
			
			optionalDialogue = portal.portalStoryState != .collected ?
				DialogueCard(style: .collectPortal(portal, self.speechSynthesizer)) :
				DialogueCard(style: .revisitPortal(portal, self.speechSynthesizer))
		}

		guard let dialogue = optionalDialogue else { return }
		
		DispatchQueue.main.async {
			dialogue.add(to: self.view)
			if self.sessionNotificationView.isActive {
				self.sessionNotificationView.forceDismiss {
					dialogue.presentCard()
					self.dimmerView.show()
				}
			}
			else {
				DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
					dialogue.presentCard()
					self.dimmerView.show()
				}
			}
			self.contentCollectionDialogue = dialogue
		}
	}

	internal func storyIntroCollected() {
		self.placeNavigatorTool(distanceToPortal: 2.0)
	}
	
	internal func storyOutroCollected() {
		self.placeNavigatorTool(distanceToPortal: 1.0)
	}
	
	internal func portalStoryCollected() {
		sessionProgressView.setPortalStoryCollected()
	}

	internal func objectCollected() {
		sessionProgressView.setCollectedObjectCount(to: portal?.numberOfCollectedObjects ?? 0)
		removePointingArrow()
	}

	internal func hideDialogueCard() {
		dimmerView.hide()
	}

	internal func allObjectsCollected() -> Void {
		DispatchQueue.main.async {
			if self.portal?.lastInStory == true {
				if let story = self.portal?.story {
					let outroDialogue = DialogueCard(style: .storyOutro(story))
					outroDialogue.add(to: self.view)
					DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
						outroDialogue.presentCard()
						self.dimmerView.show()
					}
				}
			}
			else {
				self.placeNavigatorTool(distanceToPortal: 1.0)
			}
		}
	}

	internal func navigatorToolAppeared() -> Void {
		let storyCompleted = (story ?? portal?.story)?.state == .completed
		sessionNotificationView.notification(for: !storyCompleted ? .navigatorToolAppeared : .collectionLinkAppeared)
	}

	internal func navigatorToolCollected() -> Void {
		isMissionCompleted = true
		UIView.animate(withDuration: 2, animations: {
			guard let navigatorTool = self.navigatorTool else { return }
			self.navigatorToolColorView.backgroundColor = navigatorTool.color
		}) { (_) in
			self.close()
		}
	}
	
	// MARK: -
	
	private func presentCollectionCard(for object: Object) {
		guard let portal = portal else { return }
		
		let dialogue = object.state != .collected ?
			DialogueCard(style: .collectObject(object, portal, speechSynthesizer)) :
			DialogueCard(style: .revisitObject(object, portal, speechSynthesizer))

		GameStateManager.shared.trigger(.objectCollected(object))

		dialogue.add(to: self.view)
		if self.sessionNotificationView.isActive {
			self.sessionNotificationView.forceDismiss {
				dialogue.presentCard()
				self.dimmerView.show()
			}
		}
		else {
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
				dialogue.presentCard()
				self.dimmerView.show()
			}
		}
		self.contentCollectionDialogue = dialogue
	}
	

	// MARK: - WorldMap Session Helper Functions
	
	private func setupWorldMapConfiguration() -> ARWorldTrackingConfiguration {
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = planeDetectionAlignment
		if #available(iOS 13.4, *) {
			if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
				configuration.sceneReconstruction = .mesh
			}
		}
        
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            for (i, modelKey) in unanchoredModelKeys.enumerated().reversed() {
                if worldMap.anchors.map({ $0.name }).contains(modelKey) {
                    unanchoredModelKeys.remove(at: i)
                }
            }
        }
        
        return configuration
	}

	// MARK: - Ad-Hoc-Session Helper Functions
	
	private func setupAdHocConfiguration() -> ARWorldTrackingConfiguration {
		let configuration = ARWorldTrackingConfiguration()
        
        // So far only horizontal placement is integrated
        configuration.planeDetection = .horizontal
        
        return configuration
	}
	
	private func checkAdHocSessionRequirements() {
        if !objectsArePositionedInAdHocSession,
			let horizontalPlaneAnchor: ARPlaneAnchor = Planes.findHorizontalPlaneAnchor(minimumSize: Requirements.minimalRequiredHorizontalPlaneSize)
		{
			let sessionObjectsWithHorizontalAlignment = Requirements.sessionObjectswithHorizontalAlignment.map({ $0.value })
            placeSessionObjectsInScene(sessionObjectsHorizontal: sessionObjectsWithHorizontalAlignment, horizontalAnchor: horizontalPlaneAnchor)
			objectsArePositionedInAdHocSession = true
        }
    }

    private func placeSessionObjectsInScene(sessionObjectsHorizontal: [VirtualObject], horizontalAnchor: ARPlaneAnchor) {
		// Session objects are positioned in a half-circle in the top half of a squared plane
		// The portal is positioned in the center of the plane
		// The bottom half of the plane is empty
		var sessionObjectsOnHorizontal = sessionObjectsHorizontal
		
		let center = horizontalAnchor.center
		let position = SCNVector3.positionFromTransform(horizontalAnchor.transform)
		let centerOfPlane = SCNVector3(x: position.x + center.x, y: position.y, z: position.z + center.z)
		
		// Position the portal in the center of the plane first
		var portalObject: VirtualObject?
		for (i, sessionObject) in sessionObjectsOnHorizontal.enumerated() {
			if sessionObject.name == StandardObjectType.portal.id {
				portalObject = sessionObject
				sessionObjectsOnHorizontal.remove(at: i)
				break
			}
		}
		
		// Calculate the offset angle in between the new position of the camera and the center of the plane
		if let cameraTransform = sceneView.session.currentFrame?.camera.transform {
			let cameraPosition = SCNVector3.positionFromTransform(cameraTransform)
			offsetAngleForAdHocPosition = atan2(cameraPosition.x - centerOfPlane.x, cameraPosition.z - centerOfPlane.z)
		}
		
		if let portal = portalObject {
			portal.position = centerOfPlane
			print("Portal position before: \(centerOfPlane)")
			print("Portal offset angle before: \(offsetAngleForAdHocPosition)")
			portal.eulerAngles.y = offsetAngleForAdHocPosition
			sceneView.scene.rootNode.addChildNode(portal)
			
			portal.updateAnchor(in: sceneView.session, requireExistingAnchor: false)
		}

		// Distribute objects over 180° (< 4 objects) resp. 270° (>= 4 objects)
		let completeArc = /*sessionObjectsOnHorizontal.count < 4 ? Float.pi :*/ 3/2 * Float.pi
		let arcOffset = .pi - completeArc / 2
		let objectArc = completeArc / Float(max(sessionObjectsOnHorizontal.count, 1))
		for (i, object) in sessionObjectsOnHorizontal.enumerated() {
			let positionOnObjectArc = sessionObjectsOnHorizontal.count == 1 ? Float.random(in: 0...1) : 1/2
			let angle = arcOffset + (Float(i) + positionOnObjectArc)  * objectArc - offsetAngleForAdHocPosition
			
			let objectDepth = abs(object.boundingBox.max.z - object.boundingBox.min.z)
			let position = SCNVector3.onCircle(origin: centerOfPlane, radius: Float(Requirements.minimalRequiredHorizontalPlaneSize.width + CGFloat(objectDepth/2)) / 2, angle: angle)
			object.position = SCNVector3Make(position.x, centerOfPlane.y, position.z)
			
			// Rotate the node based on the position in the circle, so that it is facing inward
			object.eulerAngles.y = -angle + .pi // Additional 180 degrees rotation, because 3d objects are oriented to +z in their scn-files opposed to the scene, which is oriented along -z
			
			sceneView.scene.rootNode.addChildNode(object)
			
			object.updateAnchor(in: sceneView.session, requireExistingAnchor: false)
		}

		// Events
		GameStateManager.shared.trigger(.portalAppeared(source))
    }

	private func updateViewToStartSession() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 1) { self.openShutterFull() }

			self.animateHint(to: .hidden)
//			self.hintTimer = nil

			self.hideResetButton()
			self.reconciliationTimeout = nil
		}
	}
	
	// MARK: - Interaction Helper Functions
    
	private func closeButtonPressed() {
		logTimer = nil
		close()
	}
	
	private func close() {
		if let _ = story, !isMissionCompleted {
			// In Session Zero
			if let tourSelectionVC = parent as? TourSelectionViewController {
				DispatchQueue.main.async {
					tourSelectionVC.fadeIn()
				}
			}
			remove()
		} else {
			dismiss(animated: true)
		}
	}
	
	// MARK: - Interface Helper Functions
	
    @available(iOS 13.0, *)
    private func setupCoachingOverlay() {
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self

        switch planeDetectionAlignment {
        case .horizontal:
            coachingOverlay.goal = .horizontalPlane
        case .vertical:
            coachingOverlay.goal = .verticalPlane
        default:
			// Called if planeDetectionAlignment is set to either 'none' or 'both'
			if planeDetectionAlignment == [.horizontal, .vertical] {
				coachingOverlay.goal = .horizontalPlane
			} else {
				coachingOverlay.goal = .tracking
			}
        }

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)

        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])

        coachingOverlay.activatesAutomatically = true

        coachingOverlay.goal = coachingOverlayGoal
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // We can get the ARFrame directly here
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Anchor management is only necessary in ad-hoc-session
        if isAdHocSession {
            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                Planes.add(planeAnchor)
            }
            checkAdHocSessionRequirements()
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Anchor management is only necessary in ad-hoc-session
        if isAdHocSession {
            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                Planes.update(planeAnchor)
            }
            checkAdHocSessionRequirements()
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        // Anchor management is only necessary in ad-hoc-session
        if isAdHocSession {
            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                Planes.remove(planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Handle failure of session
    }
	
	// MARK: - ARSCNViewDelegate

	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		let node = SCNNode()
        
//        if showDebuggingHelper, let planeAnchor = anchor as? ARPlaneAnchor {
//            node.addChildNode(planeAnchor.debugNode())
//        }
		
		// In an ad-hoc-session there are no nodes required to be placed using loaded anchors
		if isAdHocSession {
            return node.nilIfEmpty()
        }
        
        // If there are unanchored objects among preloadedModels
		//		(initialWorldMap absent: all objects)
		// 		(initialWorldMap present: objects added to the microstory since last portal edit)
		// and this is a plane anchor, add these objects to the plane
        
		
		if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal {
			// Position in a half circle if it is the first time that objects are positioned
			if unanchoredModelKeys.count == sessionObjects.count {
				let objects = unanchoredModelKeys.compactMap({ sessionObjects[$0] })
				unanchoredModelKeys = []
				
				Requirements.sessionObjectswithHorizontalAlignment = sessionObjects
				placeSessionObjectsInScene(sessionObjectsHorizontal: objects, horizontalAnchor: planeAnchor)

				return node.nilIfEmpty()
			}
			
			// Position with a random offset when only a few session objects are added afterwards
			if unanchoredModelKeys.count > 0 {
				let objects = unanchoredModelKeys.compactMap({ sessionObjects[$0] })
				unanchoredModelKeys = []
				let anchorPosition =  SCNVector3.positionFromTransform(planeAnchor.transform)
				for object in objects {
					// FIXME: If all objects are positioned in the scene for the first time in editor mode,
					// we can position them directly in a proper circle instead of using a random offset
					object.position = anchorPosition + VirtualObject.randomOffset
					sceneView.scene.rootNode.addChildNode(object)
					object.updateAnchor(in: sceneView.session, requireExistingAnchor: false)
				}
				return node.nilIfEmpty()
			}
		}

		// If initial world map is present, handle discovered anchors that were associated
		// to virtual objects from previous sessions
		guard
			let anchorName = anchor.name,
			let object = sessionObjects[anchorName]
		else { return node.nilIfEmpty() }

		if
			let existingAnchor = object.anchor,
			existingAnchor != anchor
		{
			debugPrint("WARNING: A different anchor with this name already exists – discarding this one")
			sceneView.session.remove(anchor: anchor)
			return node.nilIfEmpty()
		}

		if anchorName == StandardObjectType.portal.id {
			DispatchQueue.main.async {
				GameStateManager.shared.trigger(.portalAppeared(self.source))
			}
		}

		object.anchor = anchor

		return object
	}
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        if showDebuggingHelper, let planeAnchor = anchor as? ARPlaneAnchor {
//            planeAnchor.updateDebugNode(in: node)
//        }
    }

	private var hasEnteredPortal = false
	private var closeHasBeenCalled = false

	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

//		if isMissionCompleted, portalController?.outside == true, !closeHasBeenCalled {
//			endSessionTimeout = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (_) in
//				DispatchQueue.main.async { self.close() }
//			}
//			closeHasBeenCalled = true
//		}
		
		guard let currentFrame = sceneView.session.currentFrame else { return }
		
		let cameraWorldPos = SCNVector3.positionFromTransform(currentFrame.camera.transform)
		let planeHitTestResults = sceneView.hitTest(screenCenter, options: [.boundingBoxOnly: true])

		let portalCollisionDetected = portalController?.checkForCollision(result: planeHitTestResults.first, position: cameraWorldPos) ?? false

		if portalCollisionDetected && !hasEnteredPortal {
			hasEnteredPortal = true
			DispatchQueue.main.async {
				GameStateManager.shared.trigger(.portalEntered(self.source))
			}
		}

		// Update picked up object
		updatePickedUpObject()

		orientPointingArrow()
	}
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("Anchor removed")
    }

	// MARK: - Reset
	
	@objc func resetAsAdhoc() {
		hideResetButton()
		animateHint(to: .hidden)
		resetSession(adHoc: true)
	}
	
	func resetSession(adHoc: Bool = false) {
        let options: ARSession.RunOptions = [.removeExistingAnchors, .resetTracking]
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = adHoc ? .horizontal : planeDetectionAlignment

		if adHoc {
			isAdHocSession = true
			setupAdHocSession()
		}
		
        if !adHoc, isInitialWorldMapPresent, let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
        }

        sceneView.session.run(configuration, options: options)
	}

	private func hideResetButton() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2, animations: { [weak self] in
				guard let self = self else { return }
				self.startAdHocButton.alpha = 0.0
			}, completion: { [weak self] _ in
				guard let self = self else { return }
				self.startAdHocButton.isHidden = true
			})
		}
		reconciliationTimeout?.invalidate()
	}
	
	// MARK: - ARCoachingOverlayViewDelegate
    
    @available(iOS 13.0, *)
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
		resetSession()
	}

	// MARK: - Gesture Recognizers

	var currentTouch: UITouch?
	var pickedUpObject: VirtualObject?
	
	func sceneViewTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			contentCollectionDialogue?.isPresenting != true,
			currentTouch == nil,
			touches.count == 1
		else { return }
		
		pickedUpObject = nil
		
		let touch = touches[touches.index(touches.startIndex, offsetBy: 0)]

		guard let (selectedObject, localHitCoordinates) = sceneView.virtualObjectForHitTest(touch: touch, sessionObjects: sessionObjects, combinationState: .incompleteMoveable) ??
								   sceneView.virtualObjectForHitTest(touch: touch, sessionObjects: sessionObjects, combinationState: .complete) ??
								   sceneView.virtualObjectForHitTest(touch: touch, sessionObjects: sessionObjects) else {
			print("No virtual Object selected")
			return
		}
		
		switch selectedObject.combinationState {
		case .complete:
			selectedObject.triggerAction(for: .touch)
			if let object = selectedObject.object {
				selectedObject.loadBillboard()
				presentCollectionCard(for: object)
			}

		case .incompleteMoveable:
			currentTouch = touch
			selectedObject.saveTransform(localHitCoordinates: localHitCoordinates)
			selectedObject.attachToPointOfView(sceneView: sceneView, touch: touch)
			pickedUpObject = selectedObject
			removePointingArrow()

		case .incomplete, .completeMoveable:
			sessionNotificationView.notification(for: .primaryFragment)
		}
	}

	func sceneViewTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			contentCollectionDialogue?.isPresenting != true,
			touches.count == 1
		else { return }
		currentTouch = touches[touches.index(touches.startIndex, offsetBy: 0)]
	}

	func sceneViewTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard contentCollectionDialogue?.isPresenting != true else { return }
		updatePickedUpObject(release: true)
		currentTouch = nil
		pickedUpObject = nil
	}

	func sceneViewTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard contentCollectionDialogue?.isPresenting != true else { return }
		updatePickedUpObject(release: true)
		currentTouch = nil
		pickedUpObject = nil
	}
}

extension PortalSessionViewController {
    
	func updatePickedUpObject(release: Bool = false) {
		guard
			let touch = currentTouch,
			let pickedUpObject = pickedUpObject,
			pickedUpObject.isAnimating == false
		else {
			return
		}
		
		let allHitNodes = sceneView.hitTest(touch.location(in: sceneView), options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
		
		if let fragmentTargetHit = allHitNodes.filter({
			$0.node.parent?.parent == pickedUpObject.fragmentReferenceObject &&
			$0.node.name == VirtualObject.Constants.fragmentPlaneName
		}).first {
			pickedUpObject.attachToTargetPlane(
				targetPlaneCoordinates: fragmentTargetHit.localCoordinates, release: release, session: sceneView.session, completionAction: { [weak self] in
				if let referenceObject = pickedUpObject.fragmentReferenceObject, let collectionObject = referenceObject.object {
					referenceObject.loadBillboard()
					self?.presentCollectionCard(for: collectionObject)
				}
				
			})
		}
		else if release {
			pickedUpObject.dropAtPickup(sceneView: sceneView)
		}
		else {
			pickedUpObject.attachToPointOfView(sceneView: sceneView, touch: touch)
		}
	}
	
//	func planeAnchorForHitTest(touch: UITouch) -> ARPlaneAnchor? {
//		let touchLocation = touch.location(in: sceneView)
//		return sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent).first?.anchor as? ARPlaneAnchor
//	}
//
//	func allHitTestResults(at screenLocation: CGPoint) -> [SCNHitTestResult] {
//		let results = sceneView.hitTest(screenLocation, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
//		print("results: \(results.map({ $0.node.name ?? "---" }))")
//		return results
//	}
//
//	func hitTestResult(at screenLocation: CGPoint, for node: SCNNode) -> SCNHitTestResult? {
//		let results = allHitTestResults(at: screenLocation)
//
//		return results.first(where: { $0.node == node })
//	}
//
//	func hitTestResult(at screenLocation: CGPoint, for nodeName: String) -> SCNHitTestResult? {
//		let results = allHitTestResults(at: screenLocation)
//
//		return results.first(where: { $0.node.name == nodeName })
//	}
}
