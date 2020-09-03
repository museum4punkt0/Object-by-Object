import UIKit
import SceneKit

class ClueObjectSceneView: SCNView {
	
	let clueObject: ClueObject
	let container = SCNNode()
	let cameraNode = SCNNode()

	var autoRotateKey = "autoRotate"

	init(clueObject: ClueObject) {
		self.clueObject = clueObject
		super.init(frame: .zero, options: nil)

		backgroundColor = .clear
		self.setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup() {
        // create a new scene
		let scene = SCNScene()
		scene.rootNode.addChildNode(container)
        
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // create and add to the scene a ring of lights
		for position in [SCNVector3(x: 0, y: 10, z: 10), SCNVector3(x: 0, y: 10, z: -10), SCNVector3(x: 10, y: 10, z: 0), SCNVector3(x: -10, y: 10, z: 0)] {
			let lightNode = SCNNode()
			lightNode.light = SCNLight()
			lightNode.light!.type = .omni
			lightNode.light?.intensity = 400
			lightNode.position = position
			scene.rootNode.addChildNode(lightNode)
		}

		
        // create and add an ambient light to the scene
		let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // set the scene to the view
		self.scene = scene
        
        // allows the user to manipulate the camera
        allowsCameraControl = true
        
        // show statistics such as fps and timing information
        showsStatistics = false
		
		loadModel(clueObject: clueObject)
		
		if GameStateManager.shared.game?.isPersistentClueObjectSwipeIntroCompleted != true {
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) { [weak self] in
				self?.presentSwipeHint()
			}
		}
	}
	
	func loadModel(clueObject: ClueObject) {
//		prepareForLoad()

        // place the camera
		cameraNode.position = SCNVector3(x: 0, y: 3, z: 10)
		cameraNode.eulerAngles.x = -0.3

		guard let sceneNode = clueObject.sceneNode else { return }
		sceneNode.position = sceneNode.boundingSphere.center * (-1)

		container.addChildNode(sceneNode)
		
		prepareContainer(referenceNode: sceneNode)
	}

	func prepareContainer(referenceNode: SCNNode) {
		var radius = referenceNode.boundingSphere.radius
		if radius == 0 {
			for childNode in referenceNode.childNodes {
				if childNode.boundingSphere.radius > radius { radius = childNode.boundingSphere.radius }
			}
		}
		let scaleFactor = 2.5 / radius
		container.scale = SCNVector3.init(scaleFactor, scaleFactor, scaleFactor)
		container.removeAllActions()
		container.eulerAngles.x = 0
		let autoRotate = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 5))
//		let autoRotate = SCNAction.repeat(SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 5), count: 1)
		container.runAction(autoRotate)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		container.removeAllActions()
		dismissSwipeHint()
		GameStateManager.shared.game?.didCompletePersistentClueObjectSwipeIntro()
	}
	
	// MARK: - Swipe Hint
	
	private var swipeHintTimeout: Timer? {
		willSet { swipeHintTimeout?.invalidate() }
	}

	private var swipeHint: UIPassThroughView?

	private var swipeHintDismissed = false
	
	private func presentSwipeHint() {
		let swipeTouch = UIPassThroughImageView(image: UIImage(named: "Swipe Hint Touchpoint"))
		let swipeHand = UIPassThroughImageView(image: UIImage(named: "Swipe Hint"))
		swipeTouch.alpha = 0
		swipeHand.alpha = 0

		let swipeHint = UIPassThroughView()
		swipeHint.add(swipeTouch)
		swipeHint.add(swipeHand)

		let swipeHintConstraintX = swipeHint.centerXAnchor.constraint(equalTo: self.centerXAnchor)
		let swipeHintConstraintY = swipeHint.centerYAnchor.constraint(equalTo: self.centerYAnchor)
		
		add(swipeHint, activate: [
			swipeHintConstraintX,
			swipeHintConstraintY,
			swipeHint.widthAnchor.constraint(equalToConstant: swipeHand.image?.size.width ?? 0),
			swipeHint.heightAnchor.constraint(equalToConstant: swipeHand.image?.size.height ?? 0)
		])
		self.swipeHint = swipeHint
		
		let cycleTime: TimeInterval = 8
		let translationTime: TimeInterval = 1.2
		let fadeTime: TimeInterval = 0.2
		let intermissionTime: TimeInterval = 0.8

		let swipeHintDeltaX: CGFloat = 80
		let swipeHintDeltaY: CGFloat = 20

		swipeHintTimeout = Timer.scheduledTimer(withTimeInterval: cycleTime, repeats: true, block: { (_) in
			if self.swipeHintDismissed { return }
			// Move to bottom right
			swipeHintConstraintX.constant = swipeHintDeltaX
			swipeHintConstraintY.constant = swipeHintDeltaY
			self.layoutIfNeeded()
			UIView.animate(withDuration: fadeTime, animations: {
				// Fade in
				swipeHand.alpha = 1
			}) { (_) in
				if self.swipeHintDismissed { return }
				// Fade touchpoint in and out
				UIView.animate(withDuration: fadeTime, animations: { swipeTouch.alpha = 1 }) { (_) in
					if self.swipeHintDismissed { return }
					UIView.animate(withDuration: fadeTime, delay: translationTime-2*fadeTime, options: [], animations: { swipeTouch.alpha = 0 })
				}
				UIView.animate(withDuration: translationTime, animations: {
					// Translate to top left
					swipeHintConstraintX.constant = -swipeHintDeltaX
					swipeHintConstraintY.constant = -swipeHintDeltaY
					self.layoutIfNeeded()
				}) { (_) in
					if self.swipeHintDismissed { return }
					UIView.animate(withDuration: fadeTime, animations: {
						// Fade out
						swipeHand.alpha = 0
					}) { (_) in
						if self.swipeHintDismissed { return }
						// Move to top right
						swipeHintConstraintY.constant = swipeHintDeltaY
						self.layoutIfNeeded()
						UIView.animate(withDuration: fadeTime, delay: intermissionTime, options: [], animations: {
							// Fade in
							swipeHand.alpha = 1
						}) { (_) in
							if self.swipeHintDismissed { return }
							// Fade touchpoint in and out
							UIView.animate(withDuration: fadeTime, animations: { swipeTouch.alpha = 1 }) { (_) in
								UIView.animate(withDuration: fadeTime, delay: translationTime-2*fadeTime, options: [], animations: { swipeTouch.alpha = 0 })
							}
							UIView.animate(withDuration: translationTime, animations: {
								// Translate to bottom left
								swipeHintConstraintX.constant = swipeHintDeltaX
								swipeHintConstraintY.constant = -swipeHintDeltaY
								self.layoutIfNeeded()
							}) { (_) in
								if self.swipeHintDismissed { return }
								UIView.animate(withDuration: fadeTime) {
									// Fade out
									swipeHand.alpha = 0
								}
							}
						}
					}
				}
			}
		})
		swipeHintTimeout?.fire()
	}
	
	public func dismissSwipeHint() {
		swipeHintTimeout = nil
		swipeHintDismissed = true
		guard let swipeHint = swipeHint else { return }
		UIView.animate(withDuration: 0.4, animations: {
			swipeHint.alpha = 0
		}) { (_) in
			swipeHint.layer.removeAllAnimations()
			swipeHint.removeFromSuperview()
		}
	}
}
