import Foundation
import CoreData
import Contentful
import ContentfulPersistence
import ARKit

class WorldMap: NSManagedObject, EntryPersistable {
	static var contentTypeId: ContentTypeId = "worldmap"
	
	static func fieldMapping() -> [FieldName : String] {[
		"title": "title",
		"mapFile": "mapFile"
	]}
	
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var title: String?

	@NSManaged public var mapFile: Asset?
    @NSManaged public var worldMapsInverse: NSSet

	private var loadedWorldMap: ARWorldMap?
}

extension WorldMap {
	public var arWorldMap: ARWorldMap? {
		guard let asset = mapFile else { return nil }

		if let loadedWorldMap = loadedWorldMap {
			return loadedWorldMap
		}
		
		if let worldMap = asset.loadWorldMap() {//} ContentfulManager.loadWorldMap(id: asset.id) {
			loadedWorldMap = worldMap
			return worldMap
		} else {
			print("ContentfulWorldMap: Error loading WorldMap")
			return nil
		}
	}
}
