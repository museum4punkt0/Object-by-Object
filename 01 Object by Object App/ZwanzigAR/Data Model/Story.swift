import Foundation
import CoreData
import Contentful
import ContentfulPersistence
import ARKit

class Story: NSManagedObject, EntryPersistable, PortalSessionSource {
	static var contentTypeId: ContentTypeId = "cpStory"
	
	static func fieldMapping() -> [FieldName : String] {[
		"title": "title",
		"introduction": "introduction",
		"conclusion": "conclusion",
		"cpPortals": "portalSet",
		"cpNavigationObjectType": "entryNavigationToolString",
		"cpClueObject": "entryClueObject",
		"teaserImage": "teaserImage",
		"teaserText": "teaserText",
		"tourDuration": "tourDuration",
		"storyColor": "colorString"
	]}
	
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var title: String?
	@NSManaged public var teaserText: String?
    @NSManaged public var updatedAt: Date?
	
    @NSManaged public var conclusion: TextObject?
    @NSManaged public var introduction: TextObject?
	@NSManaged public var entryClueObject: ClueObject?
	@NSManaged public var teaserImage: Asset?
	@NSManaged public var tourDuration: NSNumber?
	@NSManaged private var colorString: String?
	
	@NSManaged public var entryNavigationToolString: String?
	
    @NSManaged public var portalSet: NSOrderedSet
	
	@NSManaged public var game: Game?
}

extension Story {
	// lastSelectedAt
	
	@NSManaged private var persistentLastSelectedAt: Date?
	
	public var lastSelectedAt: Date? {
		persistentLastSelectedAt
	}
	public func select() {
		persistentLastSelectedAt = Date()
		ContentfulDataManager.shared.save()
	}
	
	// entryNavigationToolState
	
	@NSManaged private var persistentEntryNavigationToolState: String?
	
	public var entryNavigationToolState: NavigationToolState { NavigationToolState(rawValue: persistentEntryNavigationToolState ?? "") ?? .hidden }
	
	public func setEntryNavigationToolState(_ state: NavigationToolState) {
		persistentEntryNavigationToolState = state.rawValue
		ContentfulDataManager.shared.save()
	}
}

extension Story {
	public var portals: [Portal]? { portalSet.array as? [Portal] }
}

extension Story {
	enum State: String {
		case notStarted
		case playing
		case completed
		case unknown
	}

	var state: State {
		guard let portals = portals else { return .unknown }

		if entryNavigationToolState != .collected { return .notStarted }
		
		if portals.filter({ $0.state != .completed }).count == 0 { return .completed }

		return .playing
	}

	var objects: [Object]? { return [] }
	var worldMap: ARWorldMap? { return nil }
	var navigatorTool: NavigatorToolObjectType? {
		guard let toolString = entryNavigationToolString else { return nil }
		return NavigatorToolObjectType(rawValue: toolString)
	}
	
	var currentPortal: Portal? { portals?.first(where: { $0.state != .completed }) }

	var numberOfCompletedPortals: Int {
		guard let portals = portals else { return 0 }
		var count: Int = 0
		for portal in portals {
			if portal.state == .completed {
				count += 1
			}
		}
		return count
	}

	var isBoardEmpty: Bool {
		return visiblePortals.count == 0
	}
}

extension Story {
	public var entryNavigationTool: NavigationTool? {
		guard let entryNavigationToolString = entryNavigationToolString else { return nil }
		switch NavigationToolTypeString(rawValue: entryNavigationToolString) {
		case .compass:
			return .compass
		case .pharusPin:
			return .pharusPin
		case .clueObject:
			guard let entryClueObject = entryClueObject else { return .compass }
			return .clueObject(entryClueObject)
		default:
			return nil
		}
	}

	
	private func predecessor(of portal: Portal) -> Portal? {
		guard let portalIndex = portals?.firstIndex(of: portal) else { return nil }
		return portals?[safe: portalIndex-1]
	}
	
	private func successor(of portal: Portal) -> Portal? {
		guard let portalIndex = portals?.firstIndex(of: portal) else { return nil }
		return portals?[safe: portalIndex+1]
	}
	
	public func defaultNavigationTool(leadingTo portal: Portal) -> NavigationTool? {
		guard let portalIndex = portals?.firstIndex(of: portal) else { return nil }
		if portalIndex == 0 {
			return entryNavigationTool
		}
		return predecessor(of: portal)?.hostedNavigationTool
	}
	
	public var visiblePortals: [Portal] {
		(portals ?? []).filter({ $0.state != .hidden })
	}
}

extension Story {

	enum StoryColor: String {
		case yellow, pink, red, brown, ochre, cyan
		case champagne
	}

	var color: UIColor {
		let c = UIColor.storyColor[StoryColor(rawValue: colorString ?? "champagne") ?? .champagne] ?? UIColor.champagneBranded
		print("COLOR: \(colorString ?? "---") -> \(c)")
		return UIColor.storyColor[StoryColor(rawValue: colorString ?? "champagne") ?? .champagne] ?? UIColor.champagneBranded
	}

//	public var color: UIColor {
//		storyColor
//	}
}

extension Story {
	public func reset() {
		setEntryNavigationToolState(.hidden)
		for portal in portals ?? [] {
			print("lastCompletePortal: \(portal.title ?? "---")")
			portal.reset()
		}
	}
	
	public func setSolved() {
		setEntryNavigationToolState(.collected)
		for portal in portals ?? [] {
			portal.setSolved()
		}
	}
}

enum NavigationToolState: String {
	case hidden
	case seen
	case collected
}
