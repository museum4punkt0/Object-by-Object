import UIKit
import SceneKit
import ARKit

class VirtualObjectManipulator {
	private var recentVirtualObjectDistances = [CGFloat]()
	public weak var currentGesture: Gesture? // remove currentGesture on this class
	public weak var sceneView: ARSCNView?
	public var dragOnInfinitePlanesEnabled: Bool = true

	init(_ sceneView: ARSCNView) {
		self.sceneView = sceneView
	}

	deinit {
		print("VirtualObjectManipulator Deallocated")
	}

	public func moveVirtualObjectToPosition(_ pos: SCNVector3?, _ transform: simd_float4x4?, _ instantly: Bool, _ filterPosition: Bool) {
		guard let newPosition = pos else {
			return
		}

		if instantly {
			setNewVirtualObjectPosition(newPosition, transform)
		} else {
			updateVirtualObjectPosition(newPosition, transform, filterPosition)
		}
	}

	private func setNewVirtualObjectPosition(_ pos: SCNVector3, _ transform: simd_float4x4?) {
		guard let cameraTransform = sceneView?.session.currentFrame?.camera.transform else {
			return
		}

		guard let object: VirtualObject = currentGesture?.virtualObject else { return }

		recentVirtualObjectDistances.removeAll()

		let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
		var cameraToPosition = pos - cameraWorldPos

		// Limit the distance of the object from the camera to a maximum of 10 meters.
		cameraToPosition.setMaximumLength(10)
        
        if let transform = transform {
            object.transform = SCNMatrix4(transform)
        }
		object.position = cameraWorldPos + cameraToPosition

		if object.parent == nil {
			sceneView?.scene.rootNode.addChildNode(object)
		}
    }

	private func updateVirtualObjectPosition(_ pos: SCNVector3, _ transform: simd_float4x4?, _ filterPosition: Bool) {
		guard let object: VirtualObject = currentGesture?.virtualObject else { return }

		guard let cameraTransform = sceneView?.session.currentFrame?.camera.transform else {
			return
		}

		let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
		var cameraToPosition = pos - cameraWorldPos

		// Limit the distance of the object from the camera to a maximum of 10 meters.
		cameraToPosition.setMaximumLength(10)

		// Compute the average distance of the object from the camera over the last ten
		// updates. If filterPosition is true, compute a new position for the object
		// with this average. Notice that the distance is applied to the vector from
		// the camera to the content, so it only affects the percieved distance of the
		// object - the averaging does _not_ make the content "lag".
		let hitTestResultDistance = CGFloat(cameraToPosition.length())

		recentVirtualObjectDistances.append(hitTestResultDistance)
		recentVirtualObjectDistances.keepLast(10)

        let scale = object.scale
        
        if let transform = transform {
            object.transform = SCNMatrix4(transform) // Only need rotation; scale and position are reset
            object.scale = scale
        }
        
		if filterPosition {
			let averageDistance = recentVirtualObjectDistances.average!

			cameraToPosition.setLength(Float(averageDistance))
			let averagedDistancePos = cameraWorldPos + cameraToPosition
            
			object.position = averagedDistancePos
		} else {
			object.position = cameraWorldPos + cameraToPosition
		}
    }

	public func worldPositionFromScreenPosition(_ position: CGPoint,
	                                     objectPos: SCNVector3?,
	                                     infinitePlane: Bool = false) -> (position: SCNVector3?, transform: simd_float4x4?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {

		guard let sceneView = sceneView else { return (nil, nil, nil, false) }
		
		// -------------------------------------------------------------------------------
		// 1. Always do a hit test against exisiting plane anchors first.
		//    (If any such anchors exist & only within their extents.)

		let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
		if let result = planeHitTestResults.first {

			let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeHitTestTransform = result.worldTransform // QUESTION: How to use this
			let planeAnchor = result.anchor

			// Return immediately - this is the best possible outcome.
			return (planeHitTestPosition, planeHitTestTransform, planeAnchor as? ARPlaneAnchor, true)
		}

		// -------------------------------------------------------------------------------
		// 2. Collect more information about the environment by hit testing against
		//    the feature point cloud, but do not return the result yet.

		var featureHitTestPosition: SCNVector3?
		var highQualityFeatureHitTestResult = false

		let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)

		if !highQualityfeatureHitTestResults.isEmpty {
			let result = highQualityfeatureHitTestResults[0]
			featureHitTestPosition = result.position
			highQualityFeatureHitTestResult = true
		}

		// -------------------------------------------------------------------------------
		// 3. If desired or necessary (no good feature hit test result): Hit test
		//    against an infinite, horizontal plane (ignoring the real world).

		if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {

			let pointOnPlane = objectPos ?? SCNVector3Zero

			let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
			if pointOnInfinitePlane != nil {
				return (pointOnInfinitePlane, nil, nil, true)
			}
		}

		// -------------------------------------------------------------------------------
		// 4. If available, return the result of the hit test against high quality
		//    features if the hit tests against infinite planes were skipped or no
		//    infinite plane was hit.

		if highQualityFeatureHitTestResult {
			return (featureHitTestPosition, nil, nil, false)
		}

		// -------------------------------------------------------------------------------
		// 5. As a last resort, perform a second, unfiltered hit test against features.
		//    If there are no features in the scene, the result returned here will be nil.

		let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
		if !unfilteredFeatureHitTestResults.isEmpty {
			let result = unfilteredFeatureHitTestResults[0]
			return (result.position, nil, nil, false)
		}

		return (nil, nil, nil, false)
	}

	func checkIfObjectShouldMoveOntoPlane(anchor: ARPlaneAnchor) {
		guard let planeAnchorNode = sceneView?.node(for: anchor) else {
			return
		}

		guard let object: VirtualObject = currentGesture?.virtualObject else { return }

		// Get the object's position in the plane's coordinate system.
		let objectPos = planeAnchorNode.convertPosition(object.position, from: object.parent)

		if objectPos.y == 0 {
			return; // The object is already on the plane - nothing to do here.
		}

		// Add 10% tolerance to the corners of the plane.
		let tolerance: Float = 0.1

		let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
		let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
		let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
		let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance

		if objectPos.x < minX || objectPos.x > maxX || objectPos.z < minZ || objectPos.z > maxZ {
			return
		}

		// Drop the object onto the plane if it is near it.
		let verticalAllowance: Float = 0.03
		if objectPos.y > -verticalAllowance && objectPos.y < verticalAllowance {
			SCNTransaction.begin()
			SCNTransaction.animationDuration = 0.5
			SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
			object.position.y = anchor.transform.columns.3.y
			SCNTransaction.commit()
		}
	}
}
