import UIKit
import ARKit

class ARSessionViewController: UIViewController, InteractiveARSessionController, ARSCNViewDelegate, ARSessionDelegate {
	struct Constants {
		static let horizontalPadding: CGFloat = 16
		static let topPadding: CGFloat = 16
	}

	private let object: Object
	private let objectController: VirtualObjectManipulator

	private var sessionObject: VirtualObject?
	private var currentGesture: Gesture? {
		get { return objectController.currentGesture }
		set { objectController.currentGesture = newValue }
	}

	private let sceneView = InteractiveARSceneView()

	private var objectIsPlaced: Bool = false

	// Layout
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
			self?.close()
		},
		bottomRightButtonAction: {}
	))

	init(object: Object) {
		self.object = object
		self.objectController = VirtualObjectManipulator(sceneView)
		super.init(nibName: nil, bundle: nil)
		self.sessionObject = VirtualObject(from: object, controller: objectController)
		self.sceneView.sessionController = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		var constraints = [NSLayoutConstraint]()

		sceneView.delegate = self
		sceneView.session.delegate = self

		sceneView.autoenablesDefaultLighting = true
		sceneView.automaticallyUpdatesLighting = true

		view.add(sceneView, constraints: [
			sceneView.topAnchor.constraint(equalTo: view.topAnchor),
			sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
			sceneView.leftAnchor.constraint(equalTo: view.leftAnchor)
		], accumulator: &constraints)

		view.add(closeButtonHub, constraints: [
			closeButtonHub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			closeButtonHub.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
			closeButtonHub.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.horizontalPadding)
		], accumulator: &constraints)

		NSLayoutConstraint.activate(constraints)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		guard let sessionObject = sessionObject else { return }

		var preloadedModels = [String: SCNNode]()
		sessionObject.loadModel(preloadedModels: &preloadedModels)

		var array: [SCNNode] = []
		for (_, value) in preloadedModels {
			array.append(value)
		}
		DispatchQueue.updateQueue.async { [weak self] in
			self?.sceneView.prepare(array, completionHandler: { result in
				print("Preparation successful: \(result)")
			})
		}

		let options: ARSession.RunOptions = [.removeExistingAnchors]
		let configuration = ARWorldTrackingConfiguration()
		if [ContainerObjectType.paper, .pictureFrame, .film].contains(object.containerType) {
			configuration.planeDetection = [.horizontal, .vertical]
		}
		else {
			configuration.planeDetection = .horizontal
		}

		sceneView.session.run(configuration, options: options)
	}

	private func close() {
		dismiss(animated: true)
	}

	// MARK: - ARSessionDelegate

	func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
		guard let sessionObject = sessionObject else { return }

		if let anchor = anchors[safe: 0], !objectIsPlaced {
			let anchorPosition = SCNVector3.positionFromTransform(anchor.transform)
			sessionObject.loadBillboard()
			sessionObject.position = anchorPosition
			sceneView.scene.rootNode.addChildNode(sessionObject)
			sessionObject.updateAnchor(in: sceneView.session, requireExistingAnchor: false)
			objectIsPlaced = true
		}
	}

	// MARK: - Interaction Handlers
	var currentTouch: UITouch?

	func sceneViewTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			currentTouch == nil,
			touches.count == 1,
			let sessionObject = sessionObject,
			object.containerType == .film || object.containerType == .gramophone
		else { return }

		let touch = touches[touches.index(touches.startIndex, offsetBy: 0)]
		let sessionObjects = [object.id: sessionObject]

		guard
			let (selectedObject, _) = sceneView.virtualObjectForHitTest(touch: touch, sessionObjects: sessionObjects)
		else {
			print("No virtual Object selected")
			return
		}

		selectedObject.triggerAction(for: .touch)
	}

	func sceneViewTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
	}

	func sceneViewTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
	}

	func sceneViewTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
	}
}
