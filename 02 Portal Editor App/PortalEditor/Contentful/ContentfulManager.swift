import Contentful
import ARKit

class ContentfulManager {
	public static let shared = ContentfulManager()

	public var fetchingInProgress = false
	
	private let client = Client.preview()

	public var stories = [String: CFStory]()
	public var allPortals: [CFPortal] {
		var allPortals = [CFPortal]()
		for (_, story) in stories {
			guard let portals = story.portals else { continue }
			for portal in portals {
				allPortals.append(portal)
			}
		}
		return allPortals
	}
	
	// MARK: -
	
	public enum AssetType {
		case mapFile
		case image
	}

	public var startedFetchingResources: (() -> Void)?
	public var finishedFetchingResources: (() -> Void)?
	public var startedFetchingAssetFiles: (([Int]) -> Void)?
	public var finishedFetchingAssetFile: (() -> Void)?
	public var finishedFetchingResourcesFollowUps = [(() -> Void)]()

	private var fetchResourcesFunctions = [() -> ()]()
	
	private init() {}

	public func update() {
		fetchResourcesFunctions = [fetchStories, testResources]
		
		DispatchQueue.main.async {
			guard self.fetchingInProgress == false else { return }
			self.fetchingInProgress = true
			self.startedFetchingResources?()
			self.fetchNextRootResource()
			self.fetchAssets()
		}
	}
	
	public func fetchNextRootResource() {
		if fetchResourcesFunctions.count > 0 {
			(fetchResourcesFunctions.removeFirst())()
		}
		else {
			finishFetchingResources()
		}
	}

	// MARK: - Fetch Functions
	
	public func fetchStories() {
		client.fetchArray(of: CFStory.self, matching:  QueryOn<CFStory>.include(10)) { (result: Result<HomogeneousArrayResponse<CFStory>>) in
			switch result {
			case .success(let result):
				for story in result.items {
					self.stories[story.id] = story
				}
			case .error(let error):
				print("Error fetching stories: \(error.localizedDescription)")
			}
			self.fetchNextRootResource()
		}
	}

	public func fetchPortals() {
		client.fetchArray(of: CFPortal.self, matching: QueryOn<CFPortal>.include(10)) { (result: Result<HomogeneousArrayResponse<CFPortal>>) in
			switch result {
			case .success(let result):
				var portals = [CFPortal]()
				for portal in result.items {
					portals.append(portal)
				}
			case .error(let error):
				print("Error fetching portals: \(error.localizedDescription)")
			}
			self.fetchNextRootResource()
		}
	}
	
	public func fetchObjects() {
		client.fetchArray(of: CFObject.self, matching: QueryOn<CFObject>.include(10)) { (result: Result<HomogeneousArrayResponse<CFObject>>) in
			switch result {
			case .success(let result):
				for object in result.items {
					print("Object \(object.title ?? "---") fragments: \(object.fragmentation ?? -1)")
				}
			case .error(let error):
				print("Error fetching stories: \(error.localizedDescription)")
			}
			self.fetchNextRootResource()
		}
	}

	public func fetchAssets() {
		let query = AssetQuery.limit(to: 1000)
//		let query = QueryOn<CFPlace>.limit(to: 1000)
		
		client.fetchArray(of: Asset.self, matching: query) { (result: Result<HomogeneousArrayResponse<Asset>>) in
			switch result {
			case .success(let result):
				let assets = result.items
				print("Assets on server: \(assets.count)")

				ContentfulManager.cleanUpAssetFiles(notAmong: assets.map { $0.localURL.lastPathComponent })
				
				let assetsToUpdate = assets.filter {
					return $0.needsLocalUpdate
				}
				let updateSize = assetsToUpdate.reduce(0) { (result, asset) -> Int in
					return result + (asset.serverSize ?? 0)
				}

				self.startedFetchingAssetFiles?(assetsToUpdate.map({ $0.file?.details?.size ?? 0 }))

				print("Total updates: \(assetsToUpdate.count), size: \((Float(updateSize) / 1_024 / 1_024).friendlyString()) MB")
				DispatchQueue.main.async {
					self.fetchAssetDataQueued(assets: assetsToUpdate)
				}
			case .error(let error):
				print("Error fetching assets: \(error.localizedDescription)")
			}
		}
	}

	
	private func fetchAssetDataQueued(assets: [Asset]) {
		var remainingAssets = assets
		guard let asset = remainingAssets.popLast() else {
			print("No remaining assets to fetch.")
			DispatchQueue.main.async {
				self.fetchingInProgress = false
			}
			return
		}
		
		print("\(#function) – remaining assets: \(remainingAssets.count)")

		guard let url = asset.url, !url.relativePath.isEmpty else {
			self.fetchAssetDataQueued(assets: remainingAssets)
			self.finishedFetchingAssetFile?()
			return
		}

		_ = client.fetch(url: url, then: { (result: Result<Data>) in
			switch result {
			case .success(let data):
				asset.updateLocalData(with: data)
			case .error(let error):
				print("Error fetching asset »\(url.relativePath)«: \(error.localizedDescription)")
			}
			DispatchQueue.main.async {
				self.fetchAssetDataQueued(assets: remainingAssets)
				self.finishedFetchingAssetFile?()
			}
		})
	}
	
	private static func cleanUpAssetFiles(notAmong filenames: [String]) {
		if
			let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
			let subfolders = try? FileManager.default.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
		{
			for subfolder in subfolders {
				if !FileManager.DocumentSubfolder.allCases.map({ $0.rawValue }).contains(subfolder.lastPathComponent) {
					do {
						try FileManager.default.removeItem(at: subfolder)
						print("Removing unknown documents subfolder »\(subfolder.lastPathComponent)«")
					}
					catch {
						print("Error removing unknown documents subfolder »\(subfolder.lastPathComponent)«")
					}
				}
			}
		}

		guard let localURLs = try? FileManager.default.contentsOfDirectory(at: FileManager.default.documentSubfolderURL(.fetchedAssets), includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions()) else { return }
		
		for localURL in localURLs {
			if !filenames.contains(localURL.lastPathComponent) {
				do {
					try FileManager.default.removeItem(at: localURL)
					print("Removing obsolete asset file »\(localURL.lastPathComponent)«")
				}
				catch {
					print("Error removing obsolete asset file »\(localURL.lastPathComponent)«")
				}
			}
		}
	}
	
	func finishFetchingResources() {
		for followUp in self.finishedFetchingResourcesFollowUps { followUp() }
		
		testResources()
	}
	
	func testResources() {
		self.finishedFetchingResources?()
	}
}
