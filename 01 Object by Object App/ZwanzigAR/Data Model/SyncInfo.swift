import Foundation
import CoreData
import ContentfulPersistence

class SyncInfo: NSManagedObject, SyncSpacePersistable {
    @NSManaged var syncToken: String?
}
