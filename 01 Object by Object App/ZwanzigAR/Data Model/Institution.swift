import Foundation
import CoreData
import Contentful
import ContentfulPersistence

class Institution: NSManagedObject, EntryPersistable {
	static var contentTypeId: ContentTypeId = "cpInstitution"
	
	static func fieldMapping() -> [FieldName : String] {
		[
			"title": "title",
//			"adress": "address",
			"url": "url",
			"logo": "logo"
		]
	}
	

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<CFInstitution> {
//        return NSFetchRequest<CFInstitution>(entityName: "Institution")
//    }

//    @NSManaged public var address: Contentful.Location?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var url: String?

	@NSManaged public var logo: Asset?
    @NSManaged public var institutionInverse: NSSet

}

//// MARK: Generated accessors for objects
//extension CFInstitution {
//
//    @objc(addObjectsObject:)
//    @NSManaged public func addToObjects(_ value: Object)
//
//    @objc(removeObjectsObject:)
//    @NSManaged public func removeFromObjects(_ value: Object)
//
//    @objc(addObjects:)
//    @NSManaged public func addToObjects(_ values: NSSet)
//
//    @objc(removeObjects:)
//    @NSManaged public func removeFromObjects(_ values: NSSet)
//
//}
