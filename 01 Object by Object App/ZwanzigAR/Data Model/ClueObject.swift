import Foundation
import CoreData
import Contentful
import ContentfulPersistence
import SceneKit

class ClueObject: NSManagedObject, EntryPersistable {
	static var contentTypeId: ContentTypeId = "cpClueObject"
	
	static func fieldMapping() -> [FieldName : String] {[
		"title": "title",
		"media": "mediaSet"
	]}
	
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
	
    @NSManaged public var mediaSet: NSOrderedSet
}

extension ClueObject {
	public var media: [Asset]? { mediaSet.array as? [Asset] }
}

extension ClueObject {
	public var sceneNode: SCNNode? {
		guard
			let imageAssets = media?.filter({ $0.isOfType([.image]) }),
			let imageWidth = imageAssets.first?.width?.doubleValue,
			let imageHeight = imageAssets.first?.height?.doubleValue
		else {
			print("Error: No image found")
			return nil
		}
		
		print("\(#function) – image dimensions: (\(imageWidth), \(imageHeight))")
		
		let images = imageAssets.compactMap({ $0.loadImage() })

		guard
			let frontImage = images[safe: 0],
			let backImage = images[safe: 1]
		else { return nil }
		
		let parentNode = SCNNode()
		parentNode.scale = SCNVector3(x: Float(imageWidth/imageHeight), y: 1.0, z: 1.0)
		for (rotation, image) in [(Float(0), frontImage), (Float.pi, backImage)] {
			guard let containerNode = ContainerObjectType.paper.node else { continue }
			containerNode.load()
			guard
				let paperNode = containerNode.childNodes.first,
				let material = paperNode.geometry?.firstMaterial
				else { continue }
			
			let displacementIntensity = 0.001
			
			material.diffuse.contents = image
			material.metalness.contents = 0
			material.roughness.contents = 0.8
			material.displacement.contents = UIImage(named: rotation == 0 ? "paper_displacement" : "paper_displacement_inverse")
			material.displacement.intensity = CGFloat(displacementIntensity)
			material.lightingModel = .physicallyBased
			material.isDoubleSided = false
			
			paperNode.eulerAngles = SCNVector3(x: 0, y: rotation, z: 0)
			paperNode.position.z = Float(displacementIntensity * (rotation == 0 ? -0.5 : 0.5))
			print("paperNode.eulerAngles: \(paperNode.eulerAngles)")
			parentNode.addChildNode(paperNode)
		}
		
		
		print("parentNode with bounding sphere radius \(parentNode.boundingSphere.radius) center \(parentNode.boundingSphere.center)")
		for childNode in parentNode.childNodes {
			print("childNode with bounding sphere radius \(childNode.boundingSphere.radius) center \(childNode.boundingSphere.center)")
		}
		return parentNode
	}
}
