import CoreData
import Contentful
import ContentfulPersistence
//import Keys

class ContentfulDataManager {
	struct Constants {
		static let credentialsFilename = "CMS-Credentials"
		static let credentialsDictSpaceId = "spaceId"
		static let credentialsDictAccessToken = "accessToken"
	}

	static let shared = ContentfulDataManager()
	
	let client: Client
    let coreDataStore: CoreDataStore
    let managedObjectContext: NSManagedObjectContext
    let contentfulSynchronizer: SynchronizationManager
	
	public var finishedFetchingResourcesFollowUps = [(() -> Void)]()

    static let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).last?.appendingPathComponent("ZwanzigAR.sqlite")

    static func setupManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        let modelURL = Bundle(for: ContentfulDataManager.self).url(forResource: "ZwanzigAR", withExtension: "momd")!

        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		
		// CAREFUL!
		// During development of core data structure, SQLite file is being removed on startup.
//		try? FileManager.default.removeItem(at: ContentfulDataManager.storeURL!)
        
		do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: ContentfulDataManager.storeURL!, options: nil)
        } catch {
            fatalError()
        }

        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }

     init() {
        let model = PersistenceModel(spaceType: SyncInfo.self,
                                     assetType: Asset.self,
                                     entryTypes: [
										Game.self,
										Story.self,
										Portal.self,
										Object.self,
										ClueObject.self,
										Institution.self,
										TextObject.self,
										WorldMap.self
									 ])

        let managedObjectContext = ContentfulDataManager.setupManagedObjectContext()
        let coreDataStore  = CoreDataStore(context: managedObjectContext)
        self.managedObjectContext = managedObjectContext
        self.coreDataStore = coreDataStore
		
		// Delivery API
		guard
			let url = Bundle.main.url(forResource: Constants.credentialsFilename, withExtension: "plist"),
			let dict = NSDictionary(contentsOf: url) as? [String: String],
			let spaceId = dict[Constants.credentialsDictSpaceId],
			let accessToken = dict[Constants.credentialsDictAccessToken]
		else {
			fatalError()
		}
		client = Client(spaceId: spaceId, accessToken: accessToken)
		
		let contentfulSynchronizer = SynchronizationManager(client: client,
                                                            localizationScheme: .default,
                                                            persistenceStore: coreDataStore,
                                                            persistenceModel: model)
        self.contentfulSynchronizer = contentfulSynchronizer
    }

    func performSynchronization(completion: @escaping ResultsHandler<SyncSpace>) {
        contentfulSynchronizer.sync { result in
            completion(result)
        }
    }
	
	// MARK: -
	
	func save() {
		do {
			try managedObjectContext.save()
		}
		catch {
			print("ERROR saving managedObjectContext")
		}
	}
	
	// MARK: - Fetch Functions

	func fetch<T>(predicate: String? = nil) -> [T] {
		 let fetchPredicate = predicate != nil ? NSPredicate(format: predicate!) : NSPredicate(value: true)
		return try! coreDataStore.fetchAll(type: T.self, predicate: fetchPredicate)
	 }
	
	func fetchStories(predicate: String? = nil) -> [Story] {
		 let fetchPredicate = predicate != nil ? NSPredicate(format: predicate!) : NSPredicate(value: true)
		 return try! coreDataStore.fetchAll(type: Story.self, predicate: fetchPredicate)
	 }
}
