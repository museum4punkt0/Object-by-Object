import UIKit
import ARKit

class PortalSessionViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, ARCoachingOverlayViewDelegate {
	enum Options: Equatable {
		case showStatistics
		case showDebuggingHelper
		case updateWorldMapDuringSession
		case isReadOnly
		case planeDetection(ARWorldTrackingConfiguration.PlaneDetection)
		case isAdHocSession
		case showCoaching
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
	
	
	public let portal: CFPortal
	private var worldMap: ARWorldMap?
	private let objectController: VirtualObjectManipulator
	private var portalController: PortalController?
	private let contentfulWorldMap: CFWorldMap?
	private let localWorldMap: LocalWorldMap?
	
	private var showCoaching: Bool = false
	private var showStatistics: Bool = false
	private var showDebuggingHelper: Bool = false
	private var updateWorldMapDuringSession: Bool = false
	private var isReadOnly: Bool = false
	private var isInitialWorldMapPresent: Bool
	private var isAdHocSession: Bool = false
	private var objectsArePositionedInAdHocSession = false
    private var planeDetectionAlignment: ARWorldTrackingConfiguration.PlaneDetection = .horizontal
	private var unanchoredModelKeys = [String]()
	
	private var logTimer: Timer? {
		willSet { logTimer?.invalidate() }
	}
	private var reconcilationTimout: Timer? {
		willSet { reconcilationTimout?.invalidate() }
	}

	private var currentGesture: Gesture? {
		get {
			return objectController.currentGesture
		}
		set {
			objectController.currentGesture = newValue
		}
	}
	private let sceneView = ARSCNView()
	private let logView = LogView()
	private var screenCenter = UIScreen.main.bounds.size.mid
	private var sessionObjects = [String: VirtualObject]()
	private var mapSize: Int = 0 {
		didSet {
			logView.mapSize = mapSize
		}
	}
	private var hintView: HintView?

	private var isWorldMapped = false
	
	@available(iOS 13.0, *)
    private lazy var coachingOverlay = ARCoachingOverlayView()
    @available(iOS 13.0, *)
    private lazy var coachingOverlayGoal: ARCoachingOverlayView.Goal = .horizontalPlane
	
	public var isMissionCompleted = false
	
	var restartAsAdHocButtonConstraint = NSLayoutConstraint()

    init(at portal: CFPortal, preselectedWorldMap: WorldMap? = nil, options: [PortalSessionViewController.Options] = []) {
		self.portal = portal

		let localWorldMap = preselectedWorldMap as? LocalWorldMap
		self.localWorldMap = localWorldMap
		let contentfulWorldMap = options.contains(.isAdHocSession) ? nil : (preselectedWorldMap as? CFWorldMap ?? (preselectedWorldMap == nil ? portal.worldMaps?.first : nil))
		self.contentfulWorldMap = contentfulWorldMap
		self.isInitialWorldMapPresent = localWorldMap != nil || contentfulWorldMap != nil

		self.objectController = VirtualObjectManipulator(sceneView)
		
        super.init(nibName: nil, bundle: nil)
		
		set(options: options)
		if !showDebuggingHelper { portalController = PortalController(sceneView) }
		
		Planes.largestHorizontalPlaneSoFar = nil
    }

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("PortalSessionViewController deinitialized")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		sceneView.delegate = self
		sceneView.session.delegate = self
		if showStatistics {
			sceneView.showsStatistics = true
			setupLogView()
		}
		sceneView.add(to: view, activate: [
			sceneView.topAnchor.constraint(equalTo: view.topAnchor),
			sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
			sceneView.leftAnchor.constraint(equalTo: view.leftAnchor)
		])
		
		let restartAsAdHocButton: UIButton = {
			let button = UIButton()
			button.titleLabel?.font = UIFont(name: "simple-line-icons", size: 28)
			button.setTitle("", for: .normal)
			return button
		}()
		restartAsAdHocButton.addTarget(self, action: #selector(resetAsAdhoc), for: .touchUpInside)
		restartAsAdHocButtonConstraint = restartAsAdHocButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 30)
		restartAsAdHocButton.add(to: view, activate: [
			restartAsAdHocButton.widthAnchor.constraint(equalToConstant: 30),
			restartAsAdHocButton.heightAnchor.constraint(equalToConstant: 30),
			restartAsAdHocButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
			restartAsAdHocButtonConstraint
		])
		
		if showCoaching, #available(iOS 13.0, *) {
            setupCoachingOverlay()
        }

		if isReadOnly, !isAdHocSession, let hintImageURL = portal.hintImage?.localURL {
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
				if !self.isWorldMapped {
					self.hintView = HintView(imageURL: hintImageURL, addTo: self.view)
					self.hintView?.set(visible: true)
				}
			}
		}
		
		if isReadOnly {
			navigationController?.setNavigationBarHidden(true, animated: false)
			let closeButton = UIButton.systemCloseButton()
			closeButton.addTarget(self, action: #selector(closeButtonPressed(sender:)), for: .touchUpInside)
			closeButton.add(to: view, activate: [
				closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
				closeButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
			])
		}
		else {
			let autosaveView = UIView(frame: CGRect(x: 0, y: 0, width: 74, height: 31))
			let autosaveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 33, height: 31))
			autosaveLabel.text = "Auto-\nsave"
			autosaveLabel.numberOfLines = 2
			autosaveLabel.font = .systemFont(ofSize: 10)
			autosaveView.addSubview(autosaveLabel)
			let autosaveSwitch = UISwitch.init(frame: CGRect(x: 33, y: 0, width: 51, height: 31))
			autosaveSwitch.isOn = updateWorldMapDuringSession
			autosaveSwitch.addTarget(self, action: #selector(autosaveSwitchValueChanged(sender:)), for: .valueChanged)
			autosaveView.addSubview(autosaveSwitch)
			let rightBarButtonItem = UIBarButtonItem()
			rightBarButtonItem.customView = autosaveView
			navigationItem.rightBarButtonItem = rightBarButtonItem

			var leftBarButtonItems = [UIBarButtonItem.systemCloseButton(target: self, action: #selector(closeButtonPressed(sender:)))]
			if !isReadOnly {
				let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed(sender:)))
				saveButton.isEnabled = !updateWorldMapDuringSession
				leftBarButtonItems.append(saveButton)
			}
			navigationItem.leftBarButtonItems = leftBarButtonItems
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		startSession()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if updateWorldMapDuringSession {
			saveWorldMap()
		}
		sceneView.session.pause()
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		screenCenter = size.mid
	}

	override var prefersHomeIndicatorAutoHidden: Bool {
		return true
	}
	
	// MARK: -
	
	private func set(options: [PortalSessionViewController.Options]) {
		for option in options {
			switch option {
			case .showStatistics:
				showStatistics = true
			case .showDebuggingHelper:
				showDebuggingHelper = true
			case .updateWorldMapDuringSession:
				updateWorldMapDuringSession = true
			case .isReadOnly:
				isReadOnly = true
            case .planeDetection(let alignments):
                planeDetectionAlignment = alignments
			case .isAdHocSession:
                isAdHocSession = true
			case .showCoaching:
				showCoaching = true
			}
		}
	}

	private func setupLogView() {
		logView.mapTitle = portal.title ?? "[Portal Title Missing]"
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
			reconcilationTimout = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (_) in
				self.showResetButton()
			})
		}

		let options: ARSession.RunOptions = [.removeExistingAnchors]
        let configuration: ARWorldTrackingConfiguration = isAdHocSession ? setupAdHocConfiguration() : setupWorldMapConfiguration()

		sceneView.session.run(configuration, options: options)

		if showDebuggingHelper {
			sceneView.debugOptions = .showFeaturePoints
		}
	}
	
	private func setupAdHocSession() {
//		Requirements.sessionObjectswithHorizontalAlignment = sessionObjects.filter({ $0.value.desiredAlignment == .horizontal })
		Requirements.sessionObjectswithHorizontalAlignment = sessionObjects.filter({ $0.value.desiredAlignment == .horizontal || $0.value.desiredAlignment == .vertical || $0.value.desiredAlignment == .horizontalVertical || $0.value.desiredAlignment == .horizontalVerticalIfAvailable
		})
		
		Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
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
		
		for object in portal.objects ?? [] {
//			if let sessionObject = object as? CFSessionObject {
//				sessionObjects[sessionObject.id] = VirtualObject(from: sessionObject, controller: objectController)
//			}
//			else if
//				let fragment = object as? CFSessionObjectFragment,
//				let parentObject = fragment.parentObject
//			{
//				sessionObjects[fragment.id] = VirtualObject(from: parentObject, controller: objectController, fragment: fragment)
//			} else {
//				print("Error: a session object is falling through")
//			}
			
			if let fragmentation = object.fragmentation, fragmentation > 1 {
				for fragmentIndex in 0..<fragmentation {
					print("Creating session object fragment »\(object.title ?? "---")« \(fragmentIndex+1)/\(fragmentation) …")
					let objectKey = "\(object.sys.id)_\(fragmentIndex)"
					sessionObjects[objectKey] = VirtualObject(from: object, controller: objectController, fragmentIndex: fragmentIndex)
					sessionObjectKeys.append(objectKey)
				}
			}
			else {
				print("Creating session object »\(object.title ?? "---")« …")
				sessionObjects[object.sys.id] = VirtualObject(from: object, controller: objectController)
				sessionObjectKeys.append(object.sys.id)
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
		print("unanchoredModelKeys: \(unanchoredModelKeys)")
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
        if let map = localWorldMap, map.isInitialWorldMapPresent {
            worldMap = map.arWorldMap
        } else if let map = contentfulWorldMap {
            worldMap = map.arWorldMap
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

	public func saveWorldMap() {
		guard let worldMap = localWorldMap else { return }

		switch sceneView.session.currentFrame?.worldMappingStatus {
		case .mapped, .extending:
			break
		default:
			print("Not saving world map due to insufficient mapping status.")
			return
		}
		
		sceneView.session.getCurrentWorldMap(completionHandler: { (updatedMap, error) in
			guard let map = updatedMap else {
				print("Error getting current worldMap: \(error?.localizedDescription ?? "(No error description)")")
				return
			}
			worldMap.save(map: map)
		})
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
		
		let center = SCNVector3.positionFromTransform(horizontalAnchor.center)
		let transform = SCNVector3.positionFromTransform(horizontalAnchor.transform)
		let centerOfPlane = SCNVector3(x: transform.x + center.x, y: transform.y, z: transform.z + center.z)
		
		// Position the portal in the center of the plane first
		var portal: VirtualObject?
		for (i, sessionObject) in sessionObjectsOnHorizontal.enumerated() {
			if sessionObject.name == StandardObjectType.portal.id {
				portal = sessionObject
				sessionObjectsOnHorizontal.remove(at: i)
				break
			}
		}
		
		// Calculate the offset angle in between the new position of the camera and the center of the plane
		var offset: Float = 0
		if let cameraTransform = sceneView.session.currentFrame?.camera.transform {
			let cameraPosition = SCNVector3.positionFromTransform(cameraTransform)
			offset = atan2(cameraPosition.x - centerOfPlane.x, cameraPosition.z - centerOfPlane.z)
		}
		
		if let portal = portal {
			portal.position = centerOfPlane
			portal.eulerAngles.y = offset
			sceneView.scene.rootNode.addChildNode(portal)
			
			portal.updateAnchor(in: sceneView.session, requireExistingAnchor: false)
		}

		// Distribute objects over 180° (< 4 objects) resp. 270° (>= 4 objects)
		let completeArc = /*sessionObjectsOnHorizontal.count < 4 ? Float.pi :*/ 3/2 * Float.pi
		let arcOffset = .pi - completeArc / 2
		let objectArc = completeArc / Float(max(sessionObjectsOnHorizontal.count, 1))
		for (i, object) in sessionObjectsOnHorizontal.enumerated() {
			let positionOnObjectArc = sessionObjectsOnHorizontal.count == 1 ? Float.random(in: 0...1) : 1/2
			let angle = arcOffset + (Float(i) + positionOnObjectArc)  * objectArc - offset
			
			let objectDepth = abs(object.boundingBox.max.z - object.boundingBox.min.z)
			let position = SCNVector3.onCircle(origin: centerOfPlane, radius: Float(Requirements.minimalRequiredHorizontalPlaneSize.width + CGFloat(objectDepth/2)) / 2, angle: angle)
			object.position = SCNVector3Make(position.x, centerOfPlane.y, position.z)
			
			// Rotate the node based on the position in the circle, so that it is facing inward
			object.eulerAngles.y = -angle + .pi // Additional 180 degrees rotation, because 3d objects are oriented to +z in their scn-files opposed to the scene, which is oriented along -z
			
			sceneView.scene.rootNode.addChildNode(object)
			
			object.updateAnchor(in: sceneView.session, requireExistingAnchor: false)
		}
    }
	
	// MARK: - Interaction Helper Functions
    
	@objc
    private func autosaveSwitchValueChanged(sender: UISwitch) {
		updateWorldMapDuringSession = sender.isOn
		if let items = navigationItem.leftBarButtonItems, items.count >= 2 {
			items.last?.isEnabled = !sender.isOn
		}
	}
    
	@objc private func closeButtonPressed(sender: Any) {
		logTimer = nil
        
		if !isReadOnly, !updateWorldMapDuringSession {
			let alert = UIAlertController(title: "Save changes?", message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Save", style: .default) { (_) in
				self.saveWorldMap()
				self.close()
			})
			alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { (_) in
				self.close()
			}))
			alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItems?.first
			present(alert, animated: true)
		}
		else {
			close()
		}
	}
	
	private func close() {
		if let navController = navigationController {
			if let settingsViewController = navController.viewControllers.first(where: { $0 is NavigationSettingsViewController }) {
				navigationController?.setNavigationBarHidden(false, animated: false) // because it is set to hidden in .isReadOnly mode
				navController.popToViewController(settingsViewController, animated: true)
			}
			else {
				navigationController?.setNavigationBarHidden(false, animated: false) // because it is set to hidden in .isReadOnly mode
				navController.popViewController(animated: true)
			}
        } else {
			if let compassNavigationVC = self.presentingViewController as? CompassNavigationViewController {
				dismiss(animated: true) {
					compassNavigationVC.dismiss(animated: false)
				}
			}
			else {
				dismiss(animated: true)
			}
        }
	}

	@objc private func saveButtonPressed(sender: Any) {
		saveWorldMap()
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
        
        if showDebuggingHelper, let planeAnchor = anchor as? ARPlaneAnchor {
            node.addChildNode(planeAnchor.debugNode())
        }
		
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
		print("anchor.name: \(anchor.name ?? "---")")
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

		object.anchor = anchor

		if updateWorldMapDuringSession {
			saveWorldMap()
		}
		return object
	}
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if showDebuggingHelper, let planeAnchor = anchor as? ARPlaneAnchor {
            planeAnchor.updateDebugNode(in: node)
        }
    }

	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if isReadOnly, isMissionCompleted, portalController?.outside == true {
			Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (_) in
				DispatchQueue.main.async { self.close() }
			}
		}
		
		guard let currentFrame = sceneView.session.currentFrame else { return }

		if !isWorldMapped, currentFrame.worldMappingStatus == .mapped {
			isWorldMapped = true
			hintView?.set(visible: false)
			hideResetButton()
		}
		
		let cameraWorldPos = SCNVector3.positionFromTransform(currentFrame.camera.transform)
		let planeHitTestResults = sceneView.hitTest(screenCenter, options: [.boundingBoxOnly: true])

		let portalCollisionDetected = portalController?.checkForCollision(result: planeHitTestResults.first, position: cameraWorldPos) ?? false
	}
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("Anchor removed")
    }

	// MARK: - Reset
	
	func showResetButton() {
		DispatchQueue.main.async {
			self.restartAsAdHocButtonConstraint.constant = -30
		}
	}
	func hideResetButton() {
		reconcilationTimout = nil
		DispatchQueue.main.async {
			self.restartAsAdHocButtonConstraint.constant = 30
		}
	}
	
	@objc func resetAsAdhoc() {
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
	
	// MARK: - ARCoachingOverlayViewDelegate
    
    @available(iOS 13.0, *)
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
		resetSession()
	}

	// MARK: - Gesture Recognizers

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if isReadOnly {
			if touches.count == 1 {
				let touch = touches[touches.index(touches.startIndex, offsetBy: 0)]
				
				guard let selectedObject = virtualObjectForHitTest(touch: touch) else {
					print("Warning: No virtual Object selected")
					return
				}
				
				selectedObject.triggerAction(for: .touch)
			}
		}
        
		if !isReadOnly {
			if let currentGesture = currentGesture {
				self.currentGesture = currentGesture.updateGestureFromTouches(touches, .touchBegan)
			} else {
				self.currentGesture = Gesture.startGestureFromTouches(touches, sceneView, sessionObjects)
			}
		}
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !isReadOnly {
			currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)
		}
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !isReadOnly {
			if
				showDebuggingHelper,
				touches.count == 1,
				currentGesture?.virtualObject == nil,
				let touch = touches[safe: touches.index(touches.startIndex, offsetBy: 0)],
				let planeAnchor = planeAnchorForHitTest(touch: touch)
			{
				self.sceneView.session.remove(anchor: planeAnchor)
			}
			
			else {
				currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
				currentGesture = nil
			}
		}
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !isReadOnly {
			currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
			currentGesture = nil
		}
	}
}

extension PortalSessionViewController {
    
	func planeAnchorForHitTest(touch: UITouch) -> ARPlaneAnchor? {
		let touchLocation = touch.location(in: sceneView)
		return sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent).first?.anchor as? ARPlaneAnchor
	}
	
	func virtualObjectForHitTest(touch: UITouch) -> VirtualObject? {
        let touchLocation = touch.location(in: sceneView)
        
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        let results: [SCNHitTestResult] = sceneView.hitTest(touchLocation, options: hitTestOptions)
        
        for result in results {
            let selectedObject: VirtualObject? = VirtualObject.hitVirtualObject(node: result.node, virtualObjects: sessionObjects)
            if selectedObject != nil {
                return selectedObject
            }
        }
        return nil
	}
}
