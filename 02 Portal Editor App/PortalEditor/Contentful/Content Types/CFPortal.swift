import Contentful

final class CFPortal: EntryDecodable, FieldKeysQueryable, Equatable, Resource {

	static func == (lhs: CFPortal, rhs: CFPortal) -> Bool {
		lhs.id == rhs.id
	}
	
	enum FieldKeys: String, CodingKey {
		case title
		case portalStory
		case location
		case objects = "cpObjects"
		case worldMaps
		case hintImage
		case comments
	}

	static let contentTypeId: String = "cpPortal"

	public let sys: Sys
	public let title: String?
	public var portalStory: NarrativeContent?
	public let location: Location?
	public var objects: [CFObject]?
	public var worldMaps: [CFWorldMap]?
	public var hintImage: Asset?
	public let comments: String?

	public var localWorldMaps: [LocalWorldMap] = []

	public required init(from decoder: Decoder) throws {
		sys = try decoder.sys()

		let fields = try decoder.contentfulFieldsContainer(keyedBy: CFPortal.FieldKeys.self)

		title = try fields.decodeIfPresent(String.self, forKey: .title)
		location = try fields.decodeIfPresent(Location.self, forKey: .location)
		comments = try fields.decodeIfPresent(String.self, forKey: .comments)

		try fields.resolveLink(forKey: .portalStory, decoder: decoder) { [weak self] portalStory in
			self?.portalStory = portalStory as? NarrativeContent
		}
		try fields.resolveLinksArray(forKey: .objects, decoder: decoder) { [weak self] objects in
			self?.objects = objects as? [CFObject]
		}
		try fields.resolveLinksArray(forKey: .worldMaps, decoder: decoder) { [weak self] asset in
			self?.worldMaps = asset as? [CFWorldMap]
        }
		try fields.resolveLink(forKey: .hintImage, decoder: decoder) { [weak self] asset in
			self?.hintImage = asset as? Asset
		}
		
		loadLocalWorldMaps()
	}
}

extension CFPortal {
	public var storyColor: UIColor {
		let stories = ContentfulManager.shared.stories
		for (_, story) in stories {
			guard let portals = story.portals else { continue }
			for portal in portals {
				if portal.id == self.id {
					return story.color
				}
			}
		}
		return .champagneBranded
	}

	public func loadLocalWorldMaps() {
		localWorldMaps = StoredData.shared.localWorldMaps.filter {
			$0.0.components(separatedBy: "_").first ?? "" == self.id
		}.values.sorted {
			$0.displayTitle > $1.displayTitle
		}
	}

	public func findLocalMatchesOfFetchedWorldMaps() {
		for fetchedWorldMap in worldMaps ?? [] {
			guard
				let fetchedTimeStamp = fetchedWorldMap.timeStamp?.string(style: .filename),
				let fetchedSize = fetchedWorldMap.mapFile?.localSize
			else { continue }
			
			for (i, localWorldMap) in localWorldMaps.enumerated().reversed() {
				guard
					let localSize = localWorldMap.fileSize
				else { continue }
					
				let localTimeStamp = localWorldMap.timeStamp.string(style: .filename)
				let timeStampMatch: Bool = fetchedTimeStamp == localTimeStamp
				let sizeMatch: Bool = fetchedSize == localSize
				
				if timeStampMatch && sizeMatch {
					print("Removing matching local map")
					removeLocalWorldMap(at: i)
				}
			}
		}
	}

	public func removeLocalWorldMap(at index: Int) {
		guard let localWorldMap = localWorldMaps[safe: index] else {
			print("Error: localWordMap to remove does not exist at index \(index)")
			return
		}
		StoredData.shared.remove(localWorldMap: localWorldMap)
		localWorldMap.removeMapFile()
		localWorldMaps.remove(at: index)
	}
}
