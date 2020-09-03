import Foundation
import SceneKit
import ARKit
import Contentful

class VirtualObject: SCNNode {
    
	struct Constants {
		static let fragmentPlaneName = "fragmentPlane"
		static let puzzleInterlockAllowance: Float = 0.06
	}
	
	enum CombinationState: String {
		case complete
		case incomplete
		case completeMoveable
		case incompleteMoveable
	}
	
	enum InteractionType: String {
        case touch
        case pickup
        case drop
    }
	
	enum EmbedmentType {
		case scene
		case ar
	}
	
    enum ObjectType {
        case standard(StandardObjectType)
        case contentful(ContainerObjectType)
		case navigatorTool(NavigatorToolObjectType)
    }
	
	enum ImageLayout {
		case landscape
		case portrait
	}

    struct Action {
		var onTouchActions = [() -> SCNAction]()
        var onTouch: SCNAction {
            get { SCNAction.group(onTouchActions.map({ $0() })) }
        }
		var onDropActions = [() -> SCNAction]()
        var onDrop: SCNAction {
            get { SCNAction.group(onDropActions.map({ $0() })) }
        }
		var onPickupActions = [() -> SCNAction]()
        var onPickup: SCNAction {
            get { SCNAction.group(onPickupActions.map({ $0() })) }
        }
        
        var isPlaying: Bool = false
    }

	// Pre CP 2.0
//    public let sessionObject: CFSessionObject?
//    private let fragment: CFSessionObjectFragment?
//	public var portalObject: PortalObject? { fragment ?? sessionObject }
//	public var isLinkObject: Bool { portalObject?.isLinkObject ?? false }
//	public var isCollectionObject: Bool { portalObject?.isCollectionObject ?? false }

	
	public let object: Object?
	public let fragmentIndex: Int?
	public weak var fragmentReferenceObject: VirtualObject?
	public var fragmentSecondaryObjects = [VirtualObject]()
	public weak var fragmentPlane: SCNNode?
	public weak var fragmentReferencePlane: SCNNode? {
		fragmentPlane ?? fragmentReferenceObject?.fragmentReferencePlane
	}
	public var transformOnPickup: SCNMatrix4?
	public var localHitCoordinatesOnPickup = SCNVector3.zero

    public let objectType: ObjectType
    public weak var controller: VirtualObjectManipulator?
    
    public var action: Action = Action()
    
    public let id: String
    public var anchor: ARAnchor?
	public var desiredAlignment: AnchorAlignment

	private var combineableComplete = false
	public var combinationState: CombinationState {
		if fragmentIndex == nil {
			return .complete
		}
		if combineableComplete == true {
			return fragmentIndex == 0 ? .complete : .completeMoveable
		}
		return fragmentIndex == 0 ? .incomplete : .incompleteMoveable
	}
	var isAnimating = false
	var imageLayout: ImageLayout? = nil
	
	private let embedmentType: EmbedmentType
	
	var storedBoundingBox: (min: SCNVector3, max: SCNVector3) = (min: SCNVector3(uniform: 0), max: SCNVector3(uniform: 0))
 
	init(from object: Object, controller: VirtualObjectManipulator? = nil, fragmentIndex: Int? = nil, fragmentReferenceObject: VirtualObject? = nil, embedmentType: EmbedmentType = .ar) {
		self.object = object
		self.objectType = .contentful(object.containerType)
		self.controller = controller
		self.fragmentIndex = fragmentIndex
		self.fragmentReferenceObject = fragmentReferenceObject
		self.embedmentType = embedmentType
		self.desiredAlignment = object.desiredAlignment
		self.id = {
			if let fragmentIndex = fragmentIndex { return "\(object.id)_\(fragmentIndex)" }
			return object.id
		}()
		
		super.init()
		self.name = self.id
	}
	
//	init(from object: CFSessionObject, controller: VirtualObjectManipulator? = nil, fragment: CFSessionObjectFragment? = nil, embedmentType: EmbedmentType = .ar) {
//        self.objectType = .contentful(object.containerType)
//        self.sessionObject = object
//        self.controller = controller
//        self.fragment = fragment
//		self.embedmentType = embedmentType
//        
//        if let fragment = fragment {
//            self.desiredAlignment = fragment.desiredAlignment
//        } else {
//            self.desiredAlignment = object.desiredAlignment
//        }
//		
//        self.id = fragment?.id ?? object.id
//        
//        super.init()
//        self.name = self.id
//	}
	
    init(from objectType: StandardObjectType, controller: VirtualObjectManipulator, embedmentType: EmbedmentType = .ar) {
		self.objectType = .standard(objectType)
		self.object = nil
        self.controller = controller
        self.fragmentIndex = nil
		self.fragmentReferenceObject = nil
		self.desiredAlignment = objectType.desiredAlignment
        self.id = objectType.id
		self.embedmentType = embedmentType
        
        super.init()
        self.name = objectType.id
    }

	init(from objectType: NavigatorToolObjectType, controller: VirtualObjectManipulator, embedmentType: EmbedmentType = .ar) {
		self.objectType = .navigatorTool(objectType)
		self.object = nil
        self.controller = controller
        self.fragmentIndex = nil
		self.fragmentReferenceObject = nil
		self.desiredAlignment = objectType.desiredAlignment
        self.id = objectType.id
		self.embedmentType = embedmentType

        super.init()
        self.name = objectType.id
	}
	
	required init?(coder aDejcoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("Virtual Object Deallocated")
	}

	public static var randomOffset: SCNVector3 {
		return SCNVector3(
			Float.random(in: -0.2...1.5), 0,
			Float.random(in: -3...0))
	}

	// MARK: -

	func loadModel(preloadedModels: inout [String: SCNNode]) {
        var loadedNode: SCNNode?

		// FIXME: Add additional check for already existent models to minimize loading efforts
		// How do we make sure to clone a container, but replace the material of it?
//		if let existingModel = models[id] {
//			addChildNode(existingModel.clone())
//		}
        
        switch objectType {
        case .contentful(let containerType):
            guard let node = loadContainer(for: containerType) else {
                print("Error: Loading container")
                return
            }
            
            loadedNode = node
        case .standard(let objectType):
            guard
                let node = objectType.node
            else {
                print("Error: Loading object node")
                return
            }
            node.load()
            node.set(lightingModel: .physicallyBased)
            loadedNode = node
		case .navigatorTool(let objectType):
			guard
				let node = objectType.node
			else {
				print("Error loading object node")
				return
			}
			node.load()
			node.set(lightingModel: .physicallyBased)
			loadedNode = node
        }
        
        guard let node = loadedNode else {
            print("Error: No node loaded")
            return
        }
        
        addChildNode(node)
        preloadedModels[id] = node
        
		storedBoundingBox = boundingBox
		
        return
	}
    
    func loadContainer(for containerType: ContainerObjectType) -> SCNNode? {
        guard
            let object = object,
            let containerNode = containerType.node
        else {
            print("Error: Loading sessionObject unsuccessful")
            return nil
        }
        
        containerNode.load()
        containerNode.set(lightingModel: .physicallyBased)	
        
		// Flash objects of interest
		action.onTouchActions.append {
			SCNAction.run { (node) in
				
				switch containerType {
				case .cameraOnTripod, .slideProjector, .slideProjectorWithScreen:
					break
				default:
					SCNTransaction.begin()
					SCNTransaction.animationDuration = 0.2
					
//					var formerEmissionContent = [Any?]()
					var formerEmissionContents = [SCNMaterial: Any?]()
					
					// highlight
					for material in node.allMaterials {
//						formerEmissionContent.append(material.emission.contents)
						formerEmissionContents[material] = material.emission.contents
						material.emission.contents = UIColor(red: 0.30, green: 0.15, blue: 0, alpha: 1)
					}
					
					// unhighlight on completion
					SCNTransaction.completionBlock = {
						SCNTransaction.begin()
						SCNTransaction.animationDuration = 0.6
						
//						for (i, material) in node.allMaterials.enumerated() {
//							material.emission.contents = formerEmissionContent[safe: i] ?? UIColor.black
//						}
						for (material, contents) in formerEmissionContents {
							material.emission.contents = contents
						}
						
						SCNTransaction.commit()
					}
					
					SCNTransaction.commit()
				}

				let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
				impactFeedbackgenerator.prepare()
				impactFeedbackgenerator.impactOccurred()
			}
		}
		
		let objectAssets = object.media ?? []
		// This info is not used at the moment. Implement later
//		let objectText: [CFObjectText] = object.textContent
        
        switch containerType {
            case .selfContained:
				print("Self-contained object: \(object.title ?? "---") assets: \(objectAssets.map({ $0.localURL.absoluteString }))")
				guard
					let asset = objectAssets.first(where: { $0.isOfType([.scn, .usdz]) }),
					let modelNode = SCNReferenceNode(url: asset.localURL)
				else {
					print("Error: MediaObject localURL empty")
					return nil
				}

				DispatchQueue.main.async {
					modelNode.load()
					containerNode.addChildNode(modelNode)
				}
				
				return containerNode
			
			case .cameraOnTripod, .slideProjector, .slideProjectorWithScreen:
				guard
					let asset = objectAssets.first(where: { $0.isOfType([.image])}),
					let imageWidth = asset.width?.doubleValue,
					let imageHeight = asset.height?.doubleValue,
					let imageNode = containerNode.childNode(withName: "photo_plane", recursively: true),
					let imagePlane = imageNode.geometry as? SCNPlane,
					let data: Data = try? Data(contentsOf: asset.localURL),
					let image: UIImage = UIImage(data: data)
				else {
					print("Error: Photo or photo_node not found")
					return nil
				}
				
				let originalBoundingBox = imageNode.boundingBox.max - imageNode.boundingBox.min
				let scaleFactor: Float = Float(imageHeight / imageWidth) * Float(imagePlane.width / imagePlane.height)
				
				if containerType == .cameraOnTripod {
					imageNode.scale = SCNVector3(1.0, scaleFactor, 1.0)
					imageNode.position.y -= originalBoundingBox.y * (scaleFactor - 1.0) / 2.0
				}
				else {
					if scaleFactor < 1 {
						imageNode.scale = SCNVector3(1.0, scaleFactor, 1.0)
					}
					else {
						imageNode.scale = SCNVector3(1/scaleFactor, 1.0, 1.0)
					}
				}
				imageNode.geometry?.firstMaterial?.diffuse.contents = image

				imageNode.opacity = 0
				
				return containerNode
			
            case .film:
                // Loading of video files is sometimes not working
                // The video file is found but not properly attached to the player
                // -> result: player.currentItem?.asset.tracks.length = 0
                // Redownloading the assets helps
                
                guard let asset = objectAssets.first(where: { $0.isOfType([.video]) }) else {
                    print("Error: Film URL not found")
                    return nil
                }
            
                let player = AVPlayer(url: asset.localURL)
            
                guard let filmNode = containerNode.childNodes.first else {
                    print("Error: FilmNode has no children or video has no tracks")
                    return nil
                }

				let longDimension = CGFloat(object.longDimension?.doubleValue ?? 1)
				var width = longDimension
				var height = longDimension
				if let videoTrack = AVURLAsset(url: asset.localURL).tracks(withMediaType: AVMediaType.video).first {
					let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
					if videoSize.width > videoSize.height {
						height = width * videoSize.height / videoSize.width
					}
					else {
						width = height * videoSize.width / videoSize.height
					}
				}
				filmNode.scale = SCNVector3(x: Float(width), y: Float(height), z: 0.001)
				
				filmNode.geometry?.firstMaterial?.isDoubleSided = false
                filmNode.geometry?.firstMaterial?.diffuse.contents = player
                
                let playVideoAction = SCNAction.run({ _ in  
					if let item = player.currentItem, CMTimeGetSeconds(item.currentTime()) >= CMTimeGetSeconds(item.duration) * 0.95 {
						player.seek(to: .zero)
					}
					player.play()
                })
                
                let pauseVideoAction = SCNAction.run({ _ in
                    player.pause()
                })
                
				action.onTouchActions.append({
                    let isPlaying = self.action.isPlaying
                    self.action.isPlaying.toggle()
                    return isPlaying ? pauseVideoAction : playVideoAction
                })
            
//				return nil // Makes the whole session crash sometimes due to an invalid metal texture (WTF?!)21
				return containerNode
				
            case .gramophone:
                guard
					let asset = objectAssets.first(where: { $0.isOfType([.audio]) }),
                    let audio = SCNAudioSource(url: asset.localURL)
                else {
                    print("Error: No audio found")
                    return nil
                }
                
                audio.load() // Preload the audio
                audio.loops = true // Idea: Audio loops continously – can only be paused
                
                let playAudioAction = SCNAction.run({ (node) in
                    let audioPlayer = SCNAudioPlayer(source: audio)
                    self.addAudioPlayer(audioPlayer)
//                    Proper implementation of pausing for the future:
//                    Problem: engine is nil
//                    if let engine = self.audioPlayers.first?.audioNode?.engine {
//                        try? engine.start()
//                    } else {
//                        print("Error: No engine")
//                    }
                })
                let pauseAudioAction = SCNAction.run({ (node) in
                    self.removeAllAudioPlayers()
                    
//                    Proper implementation of pausing for the future:
//                    Problem: engine is nil
//                    if let engine = self.audioPlayers.first?.audioNode?.engine {
//                        engine.stop()
//                    } else {
//                        print("Error: No engine")
//                    }
                })
                
                action.onTouchActions.append({
                    let isPlaying = self.action.isPlaying
                    self.action.isPlaying.toggle()
                    return isPlaying ? pauseAudioAction : playAudioAction
                })
            
                return containerNode
			
            case .paper:
                guard
					let asset = objectAssets.first(where: { $0.isOfType([.image]) }),
					let imageWidth = asset.width?.doubleValue,
					let imageHeight = asset.height?.doubleValue
                else {
                    print("Error: No image found")
                    return nil
                }
                
                guard
                    let data: Data = try? Data(contentsOf: asset.localURL),
                    let image: UIImage = UIImage(data: data)
                else {
                    print("Error: Creating Image")
                    return nil
                }
                
                guard let paperNode = containerNode.childNodes.first else {
                    print("Error: Childnode not found")
                    return nil
                }
				
				imageLayout = imageWidth > imageHeight ? .landscape : .portrait

				var displacementIntensity = CGFloat(0.05)
				if embedmentType == .ar, let longDimension = object.longDimension?.doubleValue {
					if imageWidth > imageHeight {
						// Landscape
						paperNode.scale = SCNVector3(x: Float(longDimension), y: Float(longDimension * imageHeight/imageWidth), z: 1.0)
					}
					else {
						// Portrait
						paperNode.scale = SCNVector3(x: Float(longDimension * imageWidth/imageHeight), y: Float(longDimension), z: 1.0)
					}
					displacementIntensity = CGFloat(longDimension/10)
				}
				else {
					paperNode.scale = SCNVector3(x: Float(imageWidth/imageHeight), y: 1.0, z: 1.0)
				}
				
                print("»\(object.title ?? "---")« paperNode image asset – width: \(imageWidth), height: \(imageHeight), scale: \(paperNode.scale.friendlyString())")
				
                let material = SCNMaterial()
                material.diffuse.contents = image
				material.metalness.contents = 0
				material.roughness.contents = 0.8
                material.displacement.contents = UIImage(named: "Displacement-Textur")
                material.displacement.intensity = displacementIntensity
				material.lightingModel = .physicallyBased
				material.isDoubleSided = true

                if let maskImage = maskImage {
                    material.transparent.contents = maskImage//.resized(CGSize(width: CGFloat(paperNode.scale.x), height: CGFloat(paperNode.scale.z)))
                    material.transparencyMode = .aOne // Use alpha channel of mask to determine transparency
                }
                
				paperNode.geometry?.firstMaterial = material
                

                if fragmentIndex == 0 {
					let plane = SCNPlane(width: CGFloat(containerNode.boundingSize.x * 2), height: CGFloat(containerNode.boundingSize.x * 3))
					plane.firstMaterial?.lightingModel = .physicallyBased
					plane.firstMaterial?.diffuse.contents = UIColor.clear
					let fragmentPlane = SCNNode(geometry: plane)
					fragmentPlane.eulerAngles.x = -.pi/2
					fragmentPlane.name = Constants.fragmentPlaneName
					containerNode.addChildNode(fragmentPlane)
					self.fragmentPlane = fragmentPlane
				}

				return containerNode
			
			case .pictureFrame:
				guard
					let asset = objectAssets.first(where: { $0.isOfType([.image]) }),
					let imageWidth = asset.width?.doubleValue,
					let imageHeight = asset.height?.doubleValue,
					let imageNode = containerNode.childNode(withName: "image_plane", recursively: true),
					let pictureFramePortraitNode = containerNode.childNode(withName: "picture_frame_portrait", recursively: true),
					let pictureFrameLandscapeNode = containerNode.childNode(withName: "picture_frame_landscape", recursively: true)
				else {
					print("Error: pictureFrame image not found")
					return nil
				}
				
				guard
					let data: Data = try? Data(contentsOf: asset.localURL),
					let image: UIImage = UIImage(data: data)
				else {
					return nil
				}
			
				let isPortrait = imageHeight > imageWidth
				pictureFramePortraitNode.isHidden = !isPortrait
				pictureFrameLandscapeNode.isHidden = isPortrait
				
				let scaleFactor = isPortrait ? imageHeight / imageWidth : imageWidth / imageHeight
				imageNode.scale = isPortrait ? SCNVector3(1.0, scaleFactor, 1.0) : SCNVector3(scaleFactor, 1.0, 1.0)
				
				imageNode.geometry?.firstMaterial?.diffuse.contents = image
				
				return containerNode
        }
    }
	
	public func loadBillboard() {
		switch objectType {
		case .contentful(let containerType):
			guard
				let containerNode = childNodes.first,
				let billboard = billboard(centered: [ContainerObjectType.selfContained, .gramophone].contains(containerType))
			else { return }
			
			switch containerType {
			case .selfContained, .gramophone:
				guard childNode(withName: "billboard", recursively: true) == nil else { return }
				billboard.position.y = containerNode.boundingSize.y + 0.1
				billboard.constraints = [{
					let constraint = SCNBillboardConstraint()
					constraint.freeAxes = [.X, .Y]
					return constraint
				}()]
				addChildNode(billboard)

			case .paper, .pictureFrame, .film:
				guard childNode(withName: "billboard", recursively: true) == nil else { return }
				billboard.eulerAngles.x = -.pi/2
				billboard.position.x = -(containerNode.boundingSize.x / 2)
				billboard.position.z = containerNode.boundingSize.z / 2 + billboard.boundingSize.y + 0.05
				billboard.position.y = containerNode.boundingSize.y / 2

				addChildNode(billboard)
				
			case .cameraOnTripod:
				guard
					let imageNode = containerNode.childNode(withName: "photo_plane", recursively: true),
					imageNode.childNode(withName: "billboard", recursively: true) == nil
				else { return }
				imageNode.runAction(SCNAction.fadeIn(duration: 0.4))
				
				billboard.position.x = imageNode.boundingSize.x / 2 + 0.05
				billboard.position.y = -imageNode.boundingSize.y / 2
				billboard.scale.x = 1/imageNode.scale.x
				billboard.scale.y = 1/imageNode.scale.y
				imageNode.addChildNode(billboard)
				
			case .slideProjector, .slideProjectorWithScreen:
				guard
					let imageNode = containerNode.childNode(withName: "photo_plane", recursively: true),
					imageNode.childNode(withName: "billboard", recursively: true) == nil,
					let projectorLightNode = containerNode.childNode(withName: "projector_light", recursively: true)
				else { return }
				imageNode.runAction(SCNAction.fadeIn(duration: 0.4))
				projectorLightNode.runAction(SCNAction.fadeIn(duration: 0.4))

				billboard.position.x = imageNode.boundingSize.x / 2 + 0.05
				billboard.position.y = -imageNode.boundingSize.y / 2
				billboard.scale.x = 1/imageNode.scale.x
				billboard.scale.y = 1/imageNode.scale.y
				imageNode.addChildNode(billboard)
			}
			
			billboard.opacity = 0
			billboard.runAction(SCNAction.fadeIn(duration: 2.5))
			print("billboard position from self: \(containerNode.convertPosition(billboard.position, from: self))")

		default:
			return
		}
	}
    
	private func billboard(centered: Bool) -> SCNNode? {
		guard
			let objectTitle = object?.title
		else { return nil }

		let text = SCNText.init(string: objectTitle.withLineBreaksAfterWords(lineLength: 25), extrusionDepth: 1)
		text.font = UIFont.font(for: .billboard)
//		text.font = .systemFont(ofSize: 64)
//		if centered { text.alignmentMode = CATextLayerAlignmentMode.center.rawValue }
		let textMaterial = SCNMaterial()
		textMaterial.diffuse.contents = UIColor.whiteBranded
		textMaterial.metalness.contents = 0
		textMaterial.roughness.contents = 0.8
		textMaterial.lightingModel = .physicallyBased
		textMaterial.emission.contents = UIColor(white: 1, alpha: 1)
		text.firstMaterial = textMaterial
		
		let scale: Float = 0.001
		
		let textNode = SCNNode(geometry: text)
		textNode.scale = SCNVector3(uniform: scale)
		if centered {
			textNode.position.x -= textNode.boundingSize.x * scale / 2
//			textNode.pivot = SCNMatrix4MakeTranslation(-textNode.position.x, 0, 0)
		}
		let containerNode = SCNNode()
		containerNode.addChildNode(textNode)
		containerNode.name = "billboard"
		return containerNode
	}
	
    // MARK: - Interactions
    
    public func triggerAction(for interactionType: InteractionType) {
        guard
            let action = action(for: interactionType)
        else {
            print("Warning: No attached actions for \(interactionType.rawValue)")
            return
        }
        runAction(action)
    }
    
    private func action(for interactionType: InteractionType) -> SCNAction? {
        switch interactionType {
            case .touch:
                return action.onTouch
            case .drop:
                return action.onDrop
            case .pickup:
                return action.onPickup
        }
    }

	public func navigatorToolPosition(playerPosition: SCNVector3, portalPosition: SCNVector3, portalRotation: Float, distanceToPortal: Float) -> SCNVector3 {
		// spawn the navigatorTool on the side of the portal that is closest to the usern

		let pointAtFront = SCNVector3.onCircle(origin: portalPosition, radius: distanceToPortal, angle: -.pi - portalRotation)
		let pointAtBack = SCNVector3.onCircle(origin: portalPosition, radius: distanceToPortal, angle: -portalRotation)

		let distanceToFront = (pointAtFront-playerPosition).length()
		let distanceToBack = (pointAtBack-playerPosition).length()

		return distanceToFront < distanceToBack ? pointAtFront : pointAtBack
	}
  
	
    // MARK: - Helpers
    
	func translateBasedOnScreenPos(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
		guard let controller = controller else { return }

		let result = controller.worldPositionFromScreenPosition(pos, objectPos: self.position, infinitePlane: infinitePlane)
		controller.moveVirtualObjectToPosition(result.position, result.transform, instantly, !result.hitAPlane)
	}
    
    func isTransparent(at textureCoordinate: CGPoint) -> Bool {
        guard let maskImage = maskImage else { return false }
        
        let point = CGPoint(x: textureCoordinate.x * maskImage.size.width, y: textureCoordinate.y * maskImage.size.height)
        
        guard
            let alphaValue = maskImage.getPixelColor(at: point)?.cgColor.alpha
        else { return false }
        
        return alphaValue < 1.0
    }
    
    var maskImage: UIImage? {
		guard
			let fragmentCount = object?.fragmentation?.intValue,
			let fragmentIndex = fragmentIndex,
			let imageLayout = imageLayout
		else {
			print("Error: totalCount or index not setup")
            return nil
        }
		let imageName = String(format: "Fragment_\(imageLayout == .landscape ? "l" : "p")%02d%02d", fragmentCount, fragmentIndex+1)
		
		guard let image = UIImage(named: imageName) else {
            print("Error: mask image »\(String(format: "Fragment_%02d%02d", fragmentCount, fragmentIndex+1))« for fragment not found")
            return nil
		}
		print("Returning mask image »\(String(format: "Fragment_%02d%02d", fragmentCount, fragmentIndex+1))«")
		return image
    }
	
	// MARK: - ARAnchor
	
	func updateAnchor(in session: ARSession, requireExistingAnchor: Bool = true) {
		if let anchor = anchor {
			session.remove(anchor: anchor)
		}
		else if requireExistingAnchor {
			debugPrint("WARNING: In requireExistingAnchor mode, an existing anchor must be removed before adding a new one.")
			return
		}
		
		let newAnchor = ARAnchor(name: id, transform: simdWorldTransform)
		anchor = newAnchor
		session.add(anchor: newAnchor)
	}
}

// Moving Object

extension VirtualObject {
	public func saveTransform(localHitCoordinates: SCNVector3) {
		transformOnPickup = transform
		localHitCoordinatesOnPickup = localHitCoordinates
	}

	func attachToPointOfView(sceneView: ARSCNView, touch: UITouch) {
		guard
			let rootNode = parent,
			let pointOfView = sceneView.pointOfView
		else { return }

		let newPosition = SCNVector3(
			x: 0,//Float(touch.location(in: sceneView).x)-localHitCoordinatesOnPickup.x,
			y: 0,//Float(touch.location(in: sceneView).y)-localHitCoordinatesOnPickup.y,
			z: -1)
		
		let newTransform = rootNode.convertTransform(SCNMatrix4(position: newPosition, eulerAngles: SCNVector3(x: .pi/2, y: 0, z: 0)), from: pointOfView)

//		transform = newTransform
		
		let distance = (SCNVector3.positionFromTransform(matrix_float4x4(newTransform)) - position).length()

		if distance < 0.01 {
			transform = newTransform
			return
		}

		SCNTransaction.begin()
		SCNTransaction.animationDuration = CFTimeInterval(distance/5)
		transform = newTransform
		SCNTransaction.commit()
	}
	
	
	func attachToTargetPlane(targetPlaneCoordinates: SCNVector3, release: Bool = false, session: ARSession, completionAction: (() -> ())) {
		guard
			let rootNode = parent,
			let targetPlane = fragmentReferencePlane,
			let referenceObject = fragmentReferenceObject
		else { return }
		
		var newPosition = self.scale * targetPlaneCoordinates
		newPosition.z = 0.001 * Float(fragmentIndex ?? 1)

		if release, newPosition.length() < Constants.puzzleInterlockAllowance {
			// Interlock
			triggerAction(for: .touch)
			combineableComplete = true
			if referenceObject.checkFragmentsComplete() {
				completionAction()
				return
			}
			
			removeAllAnimations()
			newPosition = .zero
		}
		
		let newTransform = rootNode.convertTransform(SCNMatrix4(position: newPosition, eulerAngles: SCNVector3(x: .pi/2, y: 0, z: 0)), from: targetPlane)
		
		let distance = (position-SCNVector3.positionFromTransform(newTransform)).length()

		if distance < 0.05 {
			transform = newTransform
			if release { updateAnchor(in: session) }
			return
		}

		isAnimating = true
		SCNTransaction.begin()
		SCNTransaction.animationDuration = CFTimeInterval(distance/5)

		transform = newTransform
		
		SCNTransaction.completionBlock = { [weak self] in
			if release { self?.updateAnchor(in: session) }
			self?.isAnimating = false
		}
		SCNTransaction.commit()
	}
	
	func dropAtPickup(sceneView: ARSCNView) {
		guard let transformOnPickup = transformOnPickup else { return }
		
		let targetPosition = SCNVector3.positionFromTransform(matrix_float4x4(transformOnPickup))
		let distance = (position - targetPosition).length()
		
		SCNTransaction.begin()
		SCNTransaction.animationDuration = CFTimeInterval(distance/1.5)

		transform = transformOnPickup

		SCNTransaction.commit()

		self.transformOnPickup = nil
	}

	func checkFragmentsComplete() -> Bool {
		guard
			let fragmentPlane = fragmentPlane,
			let objectFragmentCount = object?.fragmentation?.intValue
		else { return false }

		let completedFragments = fragmentSecondaryObjects.filter({ $0.combinationState == .completeMoveable })

		if completedFragments.count + 1 == objectFragmentCount {
			// Puzzle is complete

			combineableComplete = true
			
			_ = fragmentSecondaryObjects.map({ $0.removeFromParentNode() })
			
			// Remove secondary fragments
			fragmentPlane.removeFromParentNode()
			// Remove mask from own paperNode
			childNodes.first?.childNodes.first?.geometry?.firstMaterial?.transparent.contents = nil
			
			triggerAction(for: .touch)
			
			return true
		}
		return false
	}
}

extension VirtualObject {
	static func isNodePartOfVirtualObject(node: SCNNode, virtualObject: VirtualObject) -> Bool {
		if node.name == virtualObject.id {
			return true
		}
		if node.parent != nil {
			return isNodePartOfVirtualObject(node: node.parent!, virtualObject: virtualObject)
		}
		return false
	}

	static func hitVirtualObject(node: SCNNode, virtualObjects: [String: VirtualObject]) -> VirtualObject? {
		for (_, object) in virtualObjects where node.name == object.id {
			return object
		}

		if node.parent != nil {
			return hitVirtualObject(node: node.parent!, virtualObjects: virtualObjects)
		}
		return nil
	}
}

extension VirtualObject {
	var transformedBoundingBox: (min: SCNVector3, max: SCNVector3) {
		let oldMin = transform * storedBoundingBox.min
		let oldMax = transform * storedBoundingBox.max
		
		let newMin = SCNVector3(min(oldMin.x, oldMax.x), min(oldMin.y, oldMax.y), min(oldMin.z, oldMax.z))
		let newMax = SCNVector3(max(oldMin.x, oldMax.x), max(oldMin.y, oldMax.y), max(oldMin.z, oldMax.z))
		
		return (min: newMin, max: newMax)
	}
}

// MARK: -

enum ContainerObjectType: String, CaseIterable  {
	case selfContained
	case paper
	case pictureFrame
	case cameraOnTripod
	case gramophone
	case film
	case slideProjector
	case slideProjectorWithScreen

    static func forString(_ string: String?) -> ContainerObjectType? {
		guard let string = string else { return nil }
		for type in ContainerObjectType.allCases {
            if string == type.rawValue {
                return type
            }
        }
        return nil
    }
    
    var modelName: String {
        return "container_\(self.rawValue)"
    }
    
    // is this used?
    var node: SCNReferenceNode? {
        // FIXME: Watch out to work with copies when possible; same scn-file should not be loaded twice
        guard
            let url = Bundle.main.url(forResource: modelName, withExtension: "scn", subdirectory: "art.scnassets"),
            let node = SCNReferenceNode(url: url)
            else {
                print("Error: ContainerObject node not found")
                return nil
        }
        
        return node
    }
}

enum NavigatorToolObjectType: String {
	case compass
	case pharusPin
	case clueObject
	case collectionLink

	var id: String {
        return self.rawValue
    }

    var modelName: String {
		return "navigatorTool_\(self.rawValue)"
    }

	var desiredAlignment: AnchorAlignment {
        switch self {
        default:
            return .horizontal
        }
    }

    var node: SCNReferenceNode? {
        guard
            let url = Bundle.main.url(forResource: modelName, withExtension: "scn", subdirectory: "art.scnassets"),
            let node = SCNReferenceNode(url: url)
            else {
                print("Error: ContainerObject node not found")
                return nil
        }

        return node
    }

	var color: UIColor {
		switch self {
		case .pharusPin:
			return .pharusPinColor
		case .compass:
			return .compassColor
		case .clueObject:
			return .clueObjectColor
		case .collectionLink:
			return .collectionLinkColor
		}
	}

//	static func forString(_ string: String) -> NavigatorToolObjectType? {
//		if string == "compass" {
//			return .compass
//		} else if string == "pharusPin" {
//			return .pharusPin
//		} else if string == "clueObject" {
//			return .clueObject
//		}
//		return nil
//	}
}

enum StandardObjectType: String, CaseIterable {
	case portal
	case portalArrow
	case indexHand
    
    var id: String {
        return self.rawValue
    }
    
    var modelName: String {
        return "object3D_\(self.rawValue)"
    }
	
	var desiredAlignment: AnchorAlignment {
        switch self {
        default:
            return .horizontal
        }
    }
    
    var node: SCNReferenceNode? {
        guard
            let url = Bundle.main.url(forResource: modelName, withExtension: "scn", subdirectory: "art.scnassets"),
            let node = SCNReferenceNode(url: url)
            else {
                print("Error: ContainerObject node not found")
                return nil
        }
        return node
    }
}

// MARK: -
enum AnchorAlignment: String, CaseIterable {
    case horizontal
    case vertical
    case horizontalVertical
    case horizontalVerticalIfAvailable

    static func forString(_ string: String?) -> AnchorAlignment? {
        guard let string = string else { return nil }

        for type in AnchorAlignment.allCases {
            if string == type.rawValue {
                return type
            }
        }
        return nil
    }
}

