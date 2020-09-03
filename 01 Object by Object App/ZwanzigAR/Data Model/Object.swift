import Foundation
import CoreData
import Contentful
import ContentfulPersistence

class Object: NSManagedObject, EntryPersistable {
	static var contentTypeId: ContentTypeId = "cpObject"
	
	static func fieldMapping() -> [FieldName : String] {[
		"title": "title",
		"media": "mediaSet",
		"objectStory": "objectStory",
		"institution": "institution",
		"clearedForSharing": "clearedForSharing",
		"containerType": "containerTypeString",
		"anchorAlignment": "anchorAlignmentString",
		"longDimension": "longDimension",
		"fragmentation": "fragmentation"
	]}
	
    @NSManaged public var anchorAlignmentString: String?
    @NSManaged public var containerTypeString: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var fragmentation: NSNumber?
    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var longDimension: NSNumber?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
	
    @NSManaged public var institution: Institution?
	@NSManaged private var clearedForSharing: NSNumber?
    @NSManaged public var mediaSet: NSOrderedSet
    @NSManaged public var objectStory: TextObject?
    @NSManaged public var portalSet: NSSet
}

extension Object {
	public var media: [Asset]? { mediaSet.array as? [Asset] }

	public var containerType: ContainerObjectType {
		return ContainerObjectType.forString(containerTypeString) ?? .selfContained
    }

	public var desiredAlignment: AnchorAlignment {
        return AnchorAlignment.forString(anchorAlignmentString) ?? .horizontal
    }
}

extension Object {
	enum State: String {
		case hidden
		case seen
		case collected
	}
	
	@NSManaged private var persistentState: String?
	
	public var state: State { State(rawValue: persistentState ?? "") ?? .hidden }
	
	public func setState(_ state: State) {
		persistentState = state.rawValue
		ContentfulDataManager.shared.save()
	}
	
	public var isClearedForSharing: Bool { clearedForSharing?.boolValue ?? false }
}
