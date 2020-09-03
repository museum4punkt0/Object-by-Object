import Foundation
import SceneKit
import ARKit
import Contentful

class VirtualObject: SCNNode {
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

	
	public let object: CFObject?
	private let fragmentIndex: Int?
	
    public let objectType: ObjectType
    public weak var controller: VirtualObjectManipulator?
    
    private var action: Action = Action()
    
    public let id: String
    public var anchor: ARAnchor?
	public var desiredAlignment: AnchorAlignment

	var imageLayout: ImageLayout? = nil
	
	private let embedmentType: EmbedmentType

	init(from object: CFObject, controller: VirtualObjectManipulator? = nil, fragmentIndex: Int? = nil, embedmentType: EmbedmentType = .ar) {
		self.object = object
		self.objectType = .contentful(object.containerType)
		self.controller = controller
		self.fragmentIndex = fragmentIndex
		self.embedmentType = embedmentType
		self.desiredAlignment = object.desiredAlignment
		self.id = {
			if let fragmentIndex = fragmentIndex { return "\(object.sys.id)_\(fragmentIndex)" }
			return object.sys.id
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
        }
        
        guard let node = loadedNode else {
            print("Error: No node loaded")
            return
        }
        
        addChildNode(node)
        preloadedModels[id] = node
        
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
//				SCNTransaction.begin()
//				SCNTransaction.animationDuration = 0.2
//
//
//				var formerEmissionContent = [Any?]()
//
//				// highlight
//				for material in node.allMaterials {
//					formerEmissionContent.append(material.emission.contents)
//					material.emission.contents = UIColor(red: 0.30, green: 0.15, blue: 0, alpha: 1)
//				}
//
//				// unhighlight on completion
//				SCNTransaction.completionBlock = {
//					SCNTransaction.begin()
//					SCNTransaction.animationDuration = 0.6
//
//					for (i, material) in node.allMaterials.enumerated() {
//						material.emission.contents = formerEmissionContent[safe: i] ?? UIColor.black
//					}
//
//					SCNTransaction.commit()
//				}
//
//				SCNTransaction.commit()
//
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
				guard
					let asset = objectAssets.first(where: { $0.isOfType([.scn, .usdz]) }),
					let modelNode = SCNReferenceNode(url: asset.localURL)
				else {
					print("Error: asset for self-contained object missing or mediaObject localURL empty")
					return nil
				}
				
				modelNode.load()
				containerNode.addChildNode(modelNode)
				
				return containerNode
			case .cameraOnTripod, .slideProjector, .slideProjectorWithScreen:
				guard
					let asset = objectAssets.first(where: { $0.isOfType([.image])}),
					let imageInfo = asset.file?.details?.imageInfo,
					let imageNode = containerNode.childNode(withName: "photo_plane", recursively: true),
					let imagePlane = imageNode.geometry as? SCNPlane,
					let data: Data = try? Data(contentsOf: asset.localURL),
					let image: UIImage = UIImage(data: data)
				else {
					print("Error: Photo or photo_node not found")
					return nil
				}
				
				let originalBoundingBox = imageNode.boundingBox.max - imageNode.boundingBox.min
				let scaleFactor: Float = Float(imageInfo.height / imageInfo.width) * Float(imagePlane.width / imagePlane.height)
				
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
				
				return containerNode
            case .film:
                // Loading of video files is sometimes not working
                // The video file is found but not properly attached to the player
                // -> result: player.currentItem?.asset.tracks.length = 0
                // Redownloading the assets helps
                
                guard
					let asset = objectAssets.first(where: { $0.isOfType([.video]) })
                else {
                    print("Error: Film URL not found")
                    return nil
                }
            
                let player = AVPlayer(url: asset.localURL)
            
                guard let filmNode = containerNode.childNodes.first else {
                    print("Error: FilmNode has no children or video has no tracks")
                    return nil
                }
                
				let longDimension = CGFloat(object.longDimension ?? 1)
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
                    let imageInfo = asset.file?.details?.imageInfo
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

				imageLayout = imageInfo.width > imageInfo.height ? .landscape : .portrait

				var displacementIntensity = CGFloat(0.05)
				if embedmentType == .ar, let longDimension = object.longDimension {
					if imageInfo.width > imageInfo.height {
						// Landscape
						containerNode.scale = SCNVector3(x: Float(longDimension), y: 1.0, z: Float(longDimension * imageInfo.height/imageInfo.width))
					}
					else {
						// Portrait
						containerNode.scale = SCNVector3(x: Float(longDimension * imageInfo.width/imageInfo.height), y: 1.0, z: Float(longDimension))
					}
					displacementIntensity = CGFloat(longDimension/10)
				}
				else {
					containerNode.scale = SCNVector3(x: Float(imageInfo.width/imageInfo.height), y: 1.0, z: 1.0)
				}
                
                let material = SCNMaterial()
                material.diffuse.contents = image
				material.metalness.contents = 0
				material.roughness.contents = 0.8
                material.displacement.contents = UIImage(named: "Displacement-Textur")
                material.displacement.intensity = displacementIntensity
				material.lightingModel = .physicallyBased
				material.isDoubleSided = true
				
				if fragmentIndex == 0 {
					material.emission.contents = UIColor(red: 0.30, green: 0.15, blue: 0, alpha: 1)
				}
				
                if let maskImage = maskImage {
                    material.transparent.contents = maskImage
                    material.transparencyMode = .aOne // Use alpha channel of mask to determine transparency
                }
                
				paperNode.geometry?.firstMaterial = material
                
                return containerNode
				
			case .pictureFrame:
				guard
					let asset = objectAssets.first(where: { $0.isOfType([.image]) }),
					let imageInfo = asset.file?.details?.imageInfo,
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
			
				let isPortrait = imageInfo.height > imageInfo.width
				pictureFramePortraitNode.isHidden = !isPortrait
				pictureFrameLandscapeNode.isHidden = isPortrait
				
				let scaleFactor = isPortrait ? imageInfo.height / imageInfo.width : imageInfo.width / imageInfo.height
				imageNode.scale = isPortrait ? SCNVector3(1.0, scaleFactor, 1.0) : SCNVector3(scaleFactor, 1.0, 1.0)
				
				imageNode.geometry?.firstMaterial?.diffuse.contents = image
				
				return containerNode
        }
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
			let fragmentCount = object?.fragmentation,
			let fragmentIndex = fragmentIndex, fragmentIndex != 0,
			let imageLayout = imageLayout
		else {
			print("Error: totalCount, index or imageLayout not setup")
            return nil
        }
		guard let image = UIImage(named: String(format: "Fragment_\(imageLayout == .landscape ? "l" : "p")%02d%02d", fragmentCount, fragmentIndex+1)) else {
            print("Error: mask image for fragment not found")
            return nil
		}
		print("Returning mask image »\(String(format: "Fragment_%02d%02d", fragmentCount, fragmentIndex+1)))«")
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
