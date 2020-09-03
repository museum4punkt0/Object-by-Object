import UIKit
import ARKit

class PortalController {
	public var outside = true

	private let sceneView: ARSCNView
	private var closeToGate = false
	private var gateAhead = false

	public var techniques = [SCNTechnique]()

	init(_ sceneView: ARSCNView) {
		self.sceneView = sceneView
		setupPortal()
		updateSceneTechniques()
	}

	deinit {
		print("PortalController deallocated")
	}

	private func setupPortal() {
		for side in ["Outside", "Inside"].map({"portal\($0)"}) {
			if
				let path = Bundle.main.path(forResource: side, ofType: "plist"),
				let plistDict = NSDictionary(contentsOfFile: path),
				let plistStrDict = plistDict as? [String: AnyObject],
				let technique = SCNTechnique(dictionary: plistStrDict)
			{
				techniques.append(technique)
			}
		}
	}

	public func checkForCollision(result: SCNHitTestResult?, position: SCNVector3) -> Bool {
		var collisionDetected = false
		
		if let result = result, result.node.name == "gate" {
			let distanceToGate = (result.worldCoordinates-position).length()
			closeToGate = distanceToGate < 0.1

			if !gateAhead && closeToGate {
				// Walked backwards through gate
				outside.toggle()
				updateSceneTechniques()
				collisionDetected = true
			}
			gateAhead = true
		} else {
			if gateAhead && closeToGate {
				outside.toggle()
				updateSceneTechniques()
				collisionDetected = true
			}
			gateAhead = false
		}
		return collisionDetected
	}
	
	private func updateSceneTechniques() {
		sceneView.technique = techniques[outside ? 0 : 1]
	}

}
