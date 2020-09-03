import Foundation
import ARKit

class Gesture {
	enum TouchEventType {
		case touchBegan
		case touchMoved
		case touchEnded
		case touchCancelled
	}
	
	var currentTouches = Set<UITouch>()
	weak var sceneView: ARSCNView?
	let virtualObjects: [String: VirtualObject]
	var virtualObject: VirtualObject?
	
	var refreshTimer: Timer?
	
	init(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObjects: [String: VirtualObject]) {
		currentTouches = touches
		self.sceneView = sceneView
		self.virtualObjects = virtualObjects
		
		// Refresh the current gesture at 60 Hz - This ensures smooth updates even when no
		// new touch events are incoming (but the camera might have moved).
		self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.016_667, repeats: true, block: { _ in
			self.refreshCurrentGesture()
		})
	}

	deinit {
		print("Gesture is deallocated")
	}
	
	static func startGestureFromTouches(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObjects: [String: VirtualObject]) -> Gesture? {
		if touches.count == 1 {
			return SingleFingerGesture(touches, sceneView, virtualObjects)
		} else if touches.count == 2 {
			return TwoFingerGesture(touches, sceneView, virtualObjects)
		} else {
			return nil
		}
	}
	
	func refreshCurrentGesture() {
		if let singleFingerGesture = self as? SingleFingerGesture {
			singleFingerGesture.updateGesture()
		} else if let twoFingerGesture = self as? TwoFingerGesture {
			twoFingerGesture.updateGesture()
		}
	}
	
	func updateGestureFromTouches(_ touches: Set<UITouch>, _ type: TouchEventType) -> Gesture? {
		guard let sceneView = sceneView else { return nil }
		
		if touches.isEmpty {
			// No touches -> Do nothing.
			return self
		}
		
		// Update the set of current touches.
		if type == .touchBegan || type == .touchMoved {
			currentTouches = touches.union(currentTouches)
		} else if type == .touchEnded || type == .touchCancelled {
			currentTouches.subtract(touches)
		}
		
		if let singleFingerGesture = self as? SingleFingerGesture {
			
			if currentTouches.count == 1 {
				// Update this gesture.
				singleFingerGesture.updateGesture()
				return singleFingerGesture
			} else {
				// Finish this single finger gesture and switch to two finger or no gesture.
				singleFingerGesture.finishGesture()
				singleFingerGesture.refreshTimer?.invalidate()
				singleFingerGesture.refreshTimer = nil
				return Gesture.startGestureFromTouches(currentTouches, sceneView, virtualObjects)
			}
		} else if let twoFingerGesture = self as? TwoFingerGesture {
			
			if currentTouches.count == 2 {
				// Update this gesture.
				twoFingerGesture.updateGesture()
				return twoFingerGesture
			} else {
				// Finish this two finger gesture and switch to no gesture -> The user
				// will have to release all other fingers and touch the screen again
				// to start a new gesture.
				twoFingerGesture.finishGesture()
				twoFingerGesture.refreshTimer?.invalidate()
				twoFingerGesture.refreshTimer = nil
				return nil
			}
		} else {
			return self
		}
	}
}

class SingleFingerGesture: Gesture {
	
	var initialTouchLocation = CGPoint()
	var latestTouchLocation = CGPoint()
	
	let translationThreshold: CGFloat = 30
	var translationThresholdPassed = false
	var hasMovedObject = false
	var firstTouchWasOnObject = false

	var dragOffset = CGPoint()
	
	override init(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObjects: [String: VirtualObject]) {
		super.init(touches, sceneView, virtualObjects)
		
		let touch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
		initialTouchLocation = touch.location(in: sceneView)
		latestTouchLocation = initialTouchLocation
		
		// Check if the initial touch was on the object or not.
		
		let results = sceneView.hitTest(initialTouchLocation, options: [.boundingBoxOnly: true, .searchMode: SCNHitTestSearchMode.all.rawValue])
		for result in results {
			let selectedObject: VirtualObject? = VirtualObject.hitVirtualObject(node: result.node, virtualObjects: virtualObjects)
            let textureCoordinates = result.textureCoordinates(withMappingChannel: SCNMaterial().transparent.mappingChannel)

            if let selectedObject = selectedObject, !selectedObject.isTransparent(at: textureCoordinates) {
				firstTouchWasOnObject = true
				virtualObject = selectedObject
                break
			}
		}
	}
	
	func updateGesture() {
		guard
			let sceneView = sceneView,
			let virtualObject: VirtualObject = virtualObject
		else { return }

		let touch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
		latestTouchLocation = touch.location(in: sceneView)
		
		if !translationThresholdPassed {
			let initialLocationToCurrentLocation = latestTouchLocation - initialTouchLocation
			let distanceFromStartLocation = initialLocationToCurrentLocation.length()
			if distanceFromStartLocation >= translationThreshold {
				translationThresholdPassed = true
				
				let currentObjectLocation = CGPoint(sceneView.projectPoint(virtualObject.position))
				dragOffset = latestTouchLocation - currentObjectLocation
			}
		}
		
		// A single finger drag will occur if the drag started on the object and the threshold has been passed.
		if translationThresholdPassed && firstTouchWasOnObject {
			
			let offsetPos = latestTouchLocation - dragOffset
			
			virtualObject.translateBasedOnScreenPos(offsetPos, instantly: false, infinitePlane: true)
			hasMovedObject = true
		}
	}
	
	func finishGesture() {
		guard let sceneView = sceneView else { return }

		virtualObject?.updateAnchor(in: sceneView.session)
		virtualObject = nil
		// Single finger touch allows teleporting the object or interacting with it.
		
		// Do not do anything if this gesture is being finished because
		// another finger has started touching the screen.
		if currentTouches.count > 1 {
			return
		}
		
		// Do not do anything either if the touch has dragged the object around.
		if hasMovedObject {
			return
		}
	}
	
	func approxScreenSpaceCoveredByTheObject() -> Float {
		guard
			let sceneView = sceneView,
			let virtualObject = virtualObject
		else { return Float(0) }
		// Perform a bunch of hit tests in a grid across the entire screen against
		// the bounding box of the virtual object to get a rough estimate
		// of how much screen space is covered by the virtual object.
		
		let xAxisSamples = 6
		let yAxisSamples = 6
		let fieldOfViewWidth: CGFloat = 0.8
		let fieldOfViewHeight: CGFloat = 0.8
		
		let xAxisOffset: CGFloat = (1 - fieldOfViewWidth) / 2
		let yAxisOffset: CGFloat = (1 - fieldOfViewHeight) / 2
		
		let stepX = fieldOfViewWidth / CGFloat(xAxisSamples - 1)
		let stepY = fieldOfViewHeight / CGFloat(yAxisSamples - 1)
		
		var successfulHits: Float = 0
		
		var screenSpaceX: CGFloat = xAxisOffset
		var screenSpaceY: CGFloat = yAxisOffset
		
		var hitTestOptions = [SCNHitTestOption: Any]()
		hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
		
		for x in 0 ..< xAxisSamples {
			screenSpaceX = xAxisOffset + (CGFloat(x) * stepX)
			for y in 0 ..< yAxisSamples {
				screenSpaceY = yAxisOffset + (CGFloat(y) * stepY)
				
				let point = CGPoint(x: screenSpaceX * sceneView.frame.width, y: screenSpaceY * sceneView.frame.height)
				
				let results: [SCNHitTestResult] = sceneView.hitTest(point, options: hitTestOptions)
				for result in results {
					if VirtualObject.isNodePartOfVirtualObject(node: result.node, virtualObject: virtualObject) {
						successfulHits += 1
						break
					}
				}
			}
		}
		
		return successfulHits / (Float)(xAxisSamples * yAxisSamples)
	}
}

class TwoFingerGesture: Gesture {
	
	var firstTouch = UITouch()
	var secondTouch = UITouch()
	
	let translationThreshold: CGFloat = 40
	let translationThresholdHarder: CGFloat = 70
	var translationThresholdPassed = false
	var allowTranslation = false
	var dragOffset = CGPoint()
	var initialMidPoint = CGPoint(x: 0, y: 0)
	
	let rotationThreshold: Float = Float.pi / 15 // (12°)
	let rotationThresholdHarder: Float = Float.pi / 10 // (18°)
	var rotationThresholdPassed = false
	var allowRotation = false
	var initialFingerAngle: Float = 0
	var initialObjectAngle: Float = 0

	var initialDistanceBetweenFingers: CGFloat = 0
	var baseDistanceBetweenFingers: CGFloat = 0
	var objectBaseScale: CGFloat = 1.0

	override init(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObjects: [String: VirtualObject]) {
		super.init(touches, sceneView, virtualObjects)
		
		firstTouch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
		secondTouch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 1)]
		
		let loc1 = firstTouch.location(in: sceneView)
		let loc2 = secondTouch.location(in: sceneView)
		
		let mp = (loc1 + loc2) / 2
		initialMidPoint = mp
		
		// Check if any of the two fingers or their midpoint is touching the object.
		// Based on that, translation, rotation and scale will be enabled or disabled.
		var firstTouchWasOnObject = false
		
		// Compute the two other corners of the rectangle defined by the two fingers
		// and compute the points in between.
		let oc1 = CGPoint(x: loc1.x, y: loc2.y)
		let oc2 = CGPoint(x: loc2.x, y: loc1.y)
		
		//  Compute points in between.
		let dp1 = (oc1 + loc1) / 2
		let dp2 = (oc1 + loc2) / 2
		let dp3 = (oc2 + loc1) / 2
		let dp4 = (oc2 + loc2) / 2
		let dp5 = (mp + loc1) / 2
		let dp6 = (mp + loc2) / 2
		let dp7 = (mp + oc1) / 2
		let dp8 = (mp + oc2) / 2
		
		var hitTestOptions = [SCNHitTestOption: Any]()
		hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
		var hitTestResults = [SCNHitTestResult]()
		hitTestResults.append(contentsOf: sceneView.hitTest(loc1, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(loc2, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(oc1, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(oc2, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp1, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp2, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp3, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp4, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp5, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp6, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp7, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(dp8, options: hitTestOptions))
		hitTestResults.append(contentsOf: sceneView.hitTest(mp, options: hitTestOptions))

		var hitsPerObject = [String: Int]()
		for (key, _) in virtualObjects {
			hitsPerObject[key] = 0
		}
		for result in hitTestResults {
			if let hitObject = VirtualObject.hitVirtualObject(node: result.node, virtualObjects: virtualObjects) {
				let key = hitObject.id
				if let hitsPerObjectEntry = hitsPerObject[key] {
					hitsPerObject[key] = hitsPerObjectEntry + 1
				}
			}
		}

		if
			let maxHit = (hitsPerObject.sorted { $0.value > $1.value }).first,
			maxHit.value > 0
		{
			firstTouchWasOnObject = true
			virtualObject = virtualObjects[maxHit.key]
		}
		
		allowTranslation = firstTouchWasOnObject
		allowRotation = firstTouchWasOnObject
		
		let loc2ToLoc1 = loc1 - loc2
		initialDistanceBetweenFingers = loc2ToLoc1.length()
		
		let midPointToLoc1 = loc2ToLoc1 / 2
		initialFingerAngle = atan2(Float(midPointToLoc1.x), Float(midPointToLoc1.y))

		guard let virtualObject = virtualObject else { return }
		initialObjectAngle = virtualObject.eulerAngles.y
	}
	
	func updateGesture() {
		
		// First: Update the touches.
		let newTouch1 = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
		let newTouch2 = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 1)]
		
		if newTouch1.hashValue == firstTouch.hashValue {
			firstTouch = newTouch1
			secondTouch = newTouch2
		} else {
			firstTouch = newTouch2
			secondTouch = newTouch1
		}
		
		let loc1 = firstTouch.location(in: sceneView)
		let loc2 = secondTouch.location(in: sceneView)
		
        if allowTranslation {
            // 1. Translation using the midpoint between the two fingers.
            updateTranslation(midpoint: loc1.midpoint(loc2))
        }
		
		let spanBetweenTouches = loc1 - loc2
        if allowRotation {
            // 2. Rotation based on the relative rotation of the fingers on a unit circle.
            updateRotation(span: spanBetweenTouches)
        }
	}

    func updateTranslation(midpoint: CGPoint) {
		guard
			let sceneView = sceneView,
			let virtualObject = virtualObject
		else { return }

		if !translationThresholdPassed {

            let initialLocationTocurrentLocation = midpoint - initialMidPoint
            let distanceFromStartLocation = initialLocationTocurrentLocation.length()

            // Check if the translate gesture has crossed the threshold.
            // If the user is already rotating and or scaling we use a bigger threshold.

            var threshold = translationThreshold
            if rotationThresholdPassed {
                threshold = translationThresholdHarder
            }

            if distanceFromStartLocation >= threshold {
                translationThresholdPassed = true

                let currentObjectLocation = CGPoint(sceneView.projectPoint(virtualObject.position))
                dragOffset = midpoint - currentObjectLocation
            }
        }

        if translationThresholdPassed {
            let offsetPos = midpoint - dragOffset
			virtualObject.translateBasedOnScreenPos(offsetPos, instantly: false, infinitePlane: true)
        }
    }

    func updateRotation(span: CGPoint) {
		guard let virtualObject = virtualObject else { return }

        let midpointToFirstTouch = span / 2
        let currentAngle = atan2(Float(midpointToFirstTouch.x), Float(midpointToFirstTouch.y)) // ?

        let currentAngleToInitialFingerAngle = initialFingerAngle - currentAngle

        if !rotationThresholdPassed {
            var threshold = rotationThreshold

            if translationThresholdPassed {
                threshold = rotationThresholdHarder
            }

            if abs(currentAngleToInitialFingerAngle) > threshold {

                rotationThresholdPassed = true

                // Change the initial object angle to prevent a sudden jump after crossing the threshold.
                if currentAngleToInitialFingerAngle > 0 {
                    initialObjectAngle += threshold
                } else {
                    initialObjectAngle -= threshold
                }
            }
        }

        if rotationThresholdPassed {
            // Note:
            // For looking down on the object (99% of all use cases), we need to subtract the angle.
            // To make rotation also work correctly when looking from below the object one would have to
            // flip the sign of the angle depending on whether the object is above or below the camera...
            virtualObject.eulerAngles.y = initialObjectAngle - currentAngleToInitialFingerAngle
        }
    }
	
	func finishGesture() {
		guard let sceneView = sceneView else { return }
		virtualObject?.updateAnchor(in: sceneView.session)
		virtualObject = nil
	}
}
