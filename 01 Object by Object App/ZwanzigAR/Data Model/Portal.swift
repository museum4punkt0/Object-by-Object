import Foundation
import CoreData
import Contentful
import ContentfulPersistence
import ARKit

class Portal: NSManagedObject, EntryPersistable, PortalSessionSource {
	static var contentTypeId: ContentTypeId = "cpPortal"
	
	static func fieldMapping() -> [FieldName : String] {[
		"title": "title",
		"location": "location",
		"hintText": "hintText",
		"hintImage": "hintImage",
		"teaserImage": "teaserImage",
		"cpObjects": "objectSet",
		"cpNavigationObjectType": "hostedNavigationToolString",
		"cpClueObject": "hostedClueObject",
		"portalStory": "portalStory",
		"worldMaps": "worldMapSet"
	]}

    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

	@NSManaged public var title: String?
	@NSManaged public var location: Contentful.Location?
	@NSManaged public var hostedNavigationToolString: String?
	@NSManaged public var hintText: String?
	
	@NSManaged public var hintImage: Asset?
	@NSManaged public var teaserImage: Asset?
    @NSManaged public var objectSet: NSOrderedSet
	@NSManaged public var hostedClueObject: ClueObject?
    @NSManaged public var portalStory: TextObject?
    @NSManaged public var story: Story?
    @NSManaged public var worldMapSet: NSOrderedSet

}

extension Portal {
	public var objects: [Object]? { objectSet.array as? [Object] }
	public var worldMap: ARWorldMap? {
		return worldMaps?.first?.arWorldMap ?? nil
	}
	public var worldMaps: [WorldMap]? { worldMapSet.array as? [WorldMap] }
	public var numberOfCollectedObjects: Int {
		guard let objects = objects else { return 0 }
		var counter = 0

		for object in objects {
			if object.state == .collected {
				counter += 1
			}
		}
		return counter
	}
	public var navigatorTool: NavigatorToolObjectType? {
		guard let toolString = lastInStory ? NavigatorToolObjectType.collectionLink.rawValue : hostedNavigationToolString else { return nil }
		return NavigatorToolObjectType(rawValue: toolString)
	}
}

extension Portal {
	
	@NSManaged private var persistentHostedNavigationToolState: String?
	
	public var hostedNavigationToolState: NavigationToolState { NavigationToolState(rawValue: persistentHostedNavigationToolState ?? "") ?? .hidden }
	
	public func setHostedNavigationToolState(_ state: NavigationToolState) {
		persistentHostedNavigationToolState = state.rawValue
		ContentfulDataManager.shared.save()
	}

	
	@NSManaged private var persistentCurrentNavigationToolString: String?

	public func downgradeNavigationTool(to newTool: NavigationTool) {
		switch newTool {
		case .compass:
			persistentCurrentNavigationToolString = NavigationToolTypeString.compass.rawValue
		case .pharusPin:
			persistentCurrentNavigationToolString = NavigationToolTypeString.pharusPin.rawValue
		default:
			print("Error: unexpected tool downgrade type")
			return
		}
		ContentfulDataManager.shared.save()
	}
	
	public func resetNavigationToolToDefault() {
		persistentCurrentNavigationToolString = nil
		ContentfulDataManager.shared.save()
	}

	public var defaultNavigationTool: NavigationTool? {
		story?.defaultNavigationTool(leadingTo: self)
	}
	
	public var currentNavigationTool: NavigationTool? {
		switch defaultNavigationTool {
		case .compass, .pharusPin:
			return defaultNavigationTool
		case .clueObject(_):
			guard let persistentCurrentNavigationToolString = persistentCurrentNavigationToolString else {
				return defaultNavigationTool
			}
			switch NavigationToolTypeString(rawValue: persistentCurrentNavigationToolString) {
			case .compass:
				return .compass
			case .pharusPin:
				return .pharusPin
			case .clueObject:
				return defaultNavigationTool
			default:
				return nil
			}
		default: return nil
		}
	}
	
	public var wasDowngraded: Bool { currentNavigationTool != defaultNavigationTool }

	public var hasAchievement: Bool {
		switch state {
		case .hidden:
			return false
		default:
			switch currentNavigationTool {
			case .clueObject(_):
				return true
			default:
				return false
			}
		}
	}

	public var hostedNavigationTool: NavigationTool? {
		guard let hostedToolString = hostedNavigationToolString else { return nil }
		switch NavigationToolTypeString(rawValue: hostedToolString) {
		case .compass:
			return .compass
		case .pharusPin:
			return .pharusPin
		case .clueObject:
			guard let hostedClueObject = hostedClueObject else { return .compass }
			return .clueObject(hostedClueObject)
		default:
			return nil
		}
	}

	public var lastInStory: Bool {
		story?.portals?.count == numberInStory
	}
	
	public var numberInStory: Int {
		((story?.portals ?? []).firstIndex(of: self) ?? -1) + 1
	}

	public var statusText: String {
		switch state {
		case .completed:
			return "Abgeschlossen"
		case .allObjectsCollected:
			return "Navigations-Artefakt vergessen"
		default:
			return "\(numberOfCollectedObjects)/\(objects?.count ?? 0) Objekte"
		}
	}

	public var statusColor: UIColor {
		switch state {
		case .completed:
			return .greenBranded
		default:
			return .yellowBranded
		}
	}
}


extension Portal {
	enum State: String {
		case hidden
//		case inNavigation
//		case visited
		case appeared
		case entered
		case allObjectsCollected
		case completed
	}

	enum PortalStoryState: String {
		case hidden
		case seen
		case collected
	}

	@NSManaged private var persistentState: String?
	@NSManaged private var persistentPortalStoryState: String?

	public var state: State { State(rawValue: persistentState ?? "") ?? .hidden }
	public var portalStoryState: PortalStoryState { PortalStoryState(rawValue: persistentPortalStoryState ?? "") ?? .hidden }

	public func setState(_ state: State) {
		if lastInStory, state == .allObjectsCollected {
			// Last portal in story gets .completed state immediately when all objects are collected
			persistentState = State.completed.rawValue
		}
		else {
			persistentState = state.rawValue
		}
		ContentfulDataManager.shared.save()
	}
	public func setPortalStoryState(_ state: PortalStoryState) {
		persistentPortalStoryState = state.rawValue
		ContentfulDataManager.shared.save()
	}
}

extension Portal {
	public func reset() {
		setState(.hidden)
		resetNavigationToolToDefault()
		setPortalStoryState(.hidden)
		for object in objects ?? [] {
			object.setState(.hidden)
		}
	}
	
	public func setSolved() {
		setState(.completed)
		setPortalStoryState(.collected)
		for object in objects ?? [] {
			object.setState(.collected)
		}
	}
}
