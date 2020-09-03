import Foundation
import CoreData
import Contentful
import ContentfulPersistence

class TextObject: NSManagedObject, EntryPersistable {
	static var contentTypeId: ContentTypeId = "objectText"
	
	static func fieldMapping() -> [FieldName : String] {[
		"text": "text",
		"phoneticTranscript": "phoneticTranscript"
	]}
	

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorldMap> {
//        return NSFetchRequest<WorldMap>(entityName: "WorldMap")
//    }

    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
	@NSManaged public var text: String
	@NSManaged public var phoneticTranscript: String
	
	@NSManaged public var conclusionInverse: NSSet
	@NSManaged public var introductionInverse: NSSet
	@NSManaged public var objectStoryInverse: NSSet
	@NSManaged public var portalStoryInverse: NSSet
}
