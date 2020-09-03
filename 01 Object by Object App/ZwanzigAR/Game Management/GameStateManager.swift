import UIKit
import CoreLocation
import Contentful

protocol GameStateManagerDelegate {
	func updateContent() -> Void
}

protocol PortalSessionPresentationDelegate: class {
	var portalSessionHasBeenCompleted: Bool { get set }
}

protocol PortalSessionDelegate: class {
	func portalAppeared() -> Void
	func portalEntered() -> Void
	func storyIntroCollected() -> Void
	func storyOutroCollected() -> Void
	func portalStoryCollected() -> Void
	func objectCollected() -> Void
	func allObjectsCollected() -> Void
	func navigatorToolAppeared() -> Void
	func navigatorToolCollected() -> Void
	func hideDialogueCard() -> Void
}

class GameStateManager {
	enum GameEvent {
		case selectStory(Story)
		case portalAppeared(PortalSessionSource)
		case portalEntered(PortalSessionSource)
		case portalStoryCollected(Portal)
		case objectCollected(Object)
		case allObjectsCollected(Portal)
		case navigatorToolAppeared(PortalSessionSource)
		case navigatorToolCollected(PortalSessionSource)
		case storyIntroCollected(Story)
		case storyOutroCollected(Story)
		case hideDialogueCard
	}

	static let shared = GameStateManager()

	public var game: Game?
	public var stories = [Story]()
	public var gameStateManagerDelegate: GameStateManagerDelegate?
	public weak var portalSessionDelegate: PortalSessionDelegate?
	public weak var portalSessionPresentationDelegate: PortalSessionPresentationDelegate?

//	public var storyLastSelected: Story? {
//		var lastSelectedStory: Story? = nil
//		var mostCurrentSelection: Date? = nil
//		for story in stories {
//			guard let lastSelected = story.lastSelectedAt else { continue }
//			
//			if let mostCurrent = mostCurrentSelection {
//				if lastSelected > mostCurrent {
//					mostCurrentSelection = lastSelected
//					lastSelectedStory = story
//				}
//			}
//			else {
//				mostCurrentSelection = lastSelected
//				lastSelectedStory = story
//			}
//		}
//		return lastSelectedStory
//	}

	public var currentStory: Story? { game?.currentStory }
	public var currentPortal: Portal? { currentStory?.currentPortal }
	public var currentTool: NavigationTool? {
		if currentStory?.state == Story.State.completed { return nil }
		return currentPortal?.currentNavigationTool
	}


	// MARK: Event Management

	public func trigger(_ event: GameEvent) {
		switch event {
		case .selectStory(let story):
			print("GameStateManager: Story selected")
			story.select()
//			currentStory = story
			gameStateManagerDelegate?.updateContent()
		case .portalAppeared(let source):
			print("GameStateManager: Portal appeared")
			if let portal = source  as? Portal, portal.state == .hidden {
				portal.setState(.appeared)
			}
			gameStateManagerDelegate?.updateContent()
			portalSessionDelegate?.portalAppeared()
		case .portalEntered(let source):
			print("GameStateManager: Portal entered")
			if let portal = source as? Portal, portal.state == .appeared {
				portal.setState(.entered)
				portal.setPortalStoryState(.seen)
			}
			portalSessionDelegate?.portalEntered()
		case .portalStoryCollected(let portal):
			portal.setPortalStoryState(.collected)
			portalSessionDelegate?.portalStoryCollected()
		case .objectCollected(let object):
			if object.state != .collected {
				object.setState(.collected)
				portalSessionDelegate?.objectCollected()
			}
		case .allObjectsCollected(let portal):
			print("GameStateManager: All objects collected")
			portal.setState(.allObjectsCollected)
			portalSessionDelegate?.allObjectsCollected()
			gameStateManagerDelegate?.updateContent()
		case .navigatorToolAppeared(_):
			print("GameStateManager: Navigator Tool appeared")
			portalSessionDelegate?.navigatorToolAppeared()
		case .navigatorToolCollected(let source):
			print("GameStateManager: Navigator Tool collected")
			portalSessionPresentationDelegate?.portalSessionHasBeenCompleted = true
			portalSessionDelegate?.navigatorToolCollected()
			if let story = source as? Story {
//				currentStory = story
				story.setEntryNavigationToolState(.collected)
				gameStateManagerDelegate?.updateContent()
			} else if let portal = source as? Portal {
				portal.setState(.completed)
				gameStateManagerDelegate?.updateContent()
			}
		case .storyIntroCollected(_):
			portalSessionDelegate?.storyIntroCollected()
		case .storyOutroCollected(let story):
			for portal in story.portals ?? [] {
				if portal.state != .completed { portal.setState(.completed) }
			}
			portalSessionDelegate?.storyOutroCollected()
			gameStateManagerDelegate?.updateContent()
		case .hideDialogueCard:
			portalSessionDelegate?.hideDialogueCard()
		}
	}

	// MARK: Contentful Management
	
	public func syncContentful(viewController: UIViewController) {
		// 1. Sync to core data
		ContentfulDataManager.shared.performSynchronization() { result in
			switch result {
			case .success:
				print("Sync Success")

			case .error(let error):
				let message = (error as? Contentful.APIError)?.message ?? error.localizedDescription
				print("Sync Error: \(message)")
			}

			// 2. Fetch from core data
			let game = (ContentfulDataManager.shared.fetch() as [Game]).first
			self.game = game
			self.stories = game?.stories ?? []

			for followUp in ContentfulDataManager.shared.finishedFetchingResourcesFollowUps { followUp() }
			
			// 3. Sync Assets
			self.syncAssets(viewController: viewController)
			
			for story in self.stories {
				print("Story: \(story.title ?? "---") – \(story.portals?.count ?? 0) portals")
				for portal in story.portals ?? [] {
					print("    Portal »\(portal.title ?? "---")«")
					for object in portal.objects ?? [] {
						print("        Object »\(object.title ?? "---")« cleared for sharing: \(object.isClearedForSharing)")
					}
				}
			}
		}
	}
	
	private func syncAssets(viewController: UIViewController) {
		var assets = [Asset]()
		for story in stories {
			if let teaserImage = story.teaserImage { assets += [teaserImage] }
			assets += story.entryClueObject?.media ?? []
			for portal in story.portals ?? [] {
				if let teaserImage = portal.teaserImage { assets += [teaserImage] }
				assets += portal.hostedClueObject?.media ?? []
				if let hintImage = portal.hintImage { assets += [hintImage] }
				assets += portal.worldMaps?.compactMap({ $0.mapFile }) ?? []
				for object in portal.objects ?? [] {
					assets += object.media ?? []
					if let logo = object.institution?.logo {
						assets += [logo]
					}
				}
			}
		}
		
		if assets.count > 0 {
			let syncIndicatorViewController = SyncIndicatorViewController()
			syncIndicatorViewController.view.translatesAutoresizingMaskIntoConstraints = false
			viewController.add(syncIndicatorViewController)

			NSLayoutConstraint.activate([
				syncIndicatorViewController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
				syncIndicatorViewController.view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor),
				syncIndicatorViewController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
				syncIndicatorViewController.view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor)
			])
			
			fetchNextAsset(assets: assets, syncIndicatorViewController: syncIndicatorViewController)
		}
	}
	
	func fetchNextAsset(assets: [Asset], syncIndicatorViewController: SyncIndicatorViewController) {
		var mutableAssets = assets
		guard let asset = mutableAssets.popLast() else {
			DispatchQueue.main.async { syncIndicatorViewController.remove() }
			return
		}
		
		guard
			asset.needsLocalUpdate,
			let urlString = asset.urlString,
			let url = URL(string: urlString)
		else {
			self.fetchNextAsset(assets: mutableAssets, syncIndicatorViewController: syncIndicatorViewController)
			return
		}

		let start = Date()
		print("Started asset fetch \(asset.id)")
		_ = ContentfulDataManager.shared.client.fetch(url: url, then: { result in
			switch result {
			case .success(let data):
				asset.updateLocalData(with: data)
			case .error(let error):
				print("Error fetching asset: \(error.localizedDescription)")
			}
			print("Finished asset fetch \(asset.id) – took \(Date().timeIntervalSince(start))")
			print("\(mutableAssets.count) asset(s) left to fetch")
			self.fetchNextAsset(assets: mutableAssets, syncIndicatorViewController: syncIndicatorViewController)
		})
	}
}
