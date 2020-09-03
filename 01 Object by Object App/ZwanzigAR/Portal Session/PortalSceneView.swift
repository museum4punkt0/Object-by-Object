import UIKit
import ARKit

protocol InteractiveARSessionController: class {
	func sceneViewTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void
	func sceneViewTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) -> Void
	func sceneViewTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) -> Void
	func sceneViewTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) -> Void
}

class InteractiveARSceneView: ARSCNView {
	public weak var sessionController: InteractiveARSessionController?
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		sessionController?.sceneViewTouchesBegan(touches, with: event)
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		sessionController?.sceneViewTouchesMoved(touches, with: event)
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		sessionController?.sceneViewTouchesEnded(touches, with: event)
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		sessionController?.sceneViewTouchesCancelled(touches, with: event)
	}
}
