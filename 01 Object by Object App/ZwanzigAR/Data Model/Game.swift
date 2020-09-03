import Foundation
import CoreData
import Contentful
import ContentfulPersistence

class Game: NSManagedObject, EntryPersistable {
	static var contentTypeId: ContentTypeId = "cpGame"
	
	static func fieldMapping() -> [FieldName : String] {[
		"title": "title",
		"cpStories": "storySet"
	]}

    @NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

	@NSManaged public var title: String?
    @NSManaged public var storySet: NSOrderedSet
}

extension Game {
	public var stories: [Story]? { storySet.array as? [Story] }
}

extension Game {
	@NSManaged private var persistentIntroCompleted: Bool
	@NSManaged private var persistentARIntroCompleted: Bool
	@NSManaged private var persistentBoardIntroCompleted: Bool
	@NSManaged private var persistentClueObjectSwipeIntroCompleted: Bool

	var currentStory: Story? {
		
		return stories?.sorted {
			if
				let lastSelectedAt0 = $0.lastSelectedAt,
				let lastSelectedAt1 = $1.lastSelectedAt
			{
				return lastSelectedAt0 < lastSelectedAt1
			}
			return $0.lastSelectedAt == nil
		}.last
	}
	
	public var isIntroCompleted: Bool { return persistentIntroCompleted }
	public func didCompleteIntro() {
		persistentIntroCompleted = true
		ContentfulDataManager.shared.save()
	}
	
	public var isARIntroCompleted: Bool { return persistentARIntroCompleted }
	public func didCompleteARIntro() {
		persistentARIntroCompleted = true
		ContentfulDataManager.shared.save()
	}
	
	public var isBoardIntroCompleted: Bool { return persistentBoardIntroCompleted }
	public func didCompleteBoardIntro() {
		persistentBoardIntroCompleted = true
		ContentfulDataManager.shared.save()
	}
	
	public var isPersistentClueObjectSwipeIntroCompleted: Bool { return persistentClueObjectSwipeIntroCompleted }
	public func didCompletePersistentClueObjectSwipeIntro() {
		persistentClueObjectSwipeIntroCompleted = true
		ContentfulDataManager.shared.save()
	}
}

extension Game {
	enum Intro {
		case game, ar, board, clueObjectSwipe
	}
	
	public func reset() {
		resetIntros([.game, .ar, .board, .clueObjectSwipe])
		for story in stories ?? [] {
			story.reset()
		}
	}
	
	public func resetIntros(_ intros: [Intro]) {
		if intros.contains(.game) { persistentIntroCompleted = false }
		if intros.contains(.ar) { persistentARIntroCompleted = false }
		if intros.contains(.board) {persistentBoardIntroCompleted = false}
		if intros.contains(.clueObjectSwipe) {persistentClueObjectSwipeIntroCompleted = false}
		
		ContentfulDataManager.shared.save()
	}
	
	public func setSolved() {
		didCompleteIntro()
		didCompleteARIntro()
		didCompleteBoardIntro()
		didCompletePersistentClueObjectSwipeIntro()
		for story in stories ?? [] {
			story.setSolved()
		}
	}
}
