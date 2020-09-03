import Contentful
import ARKit

class CFWorldMap: EntryDecodable, FieldKeysQueryable, Resource, WorldMap {
	static let contentTypeId: String = "worldmap"

	enum FieldKeys: String, CodingKey {
		case title
		case mapFile
		case weatherType
		case daytimeType
	}

	public let sys: Sys
	public let title: String
	public var weatherType: String?
	public var daytimeType: String?
	public var mapFile: Asset?

	public required init(from decoder: Decoder) throws {
		sys = try decoder.sys()

		let fields = try decoder.contentfulFieldsContainer(keyedBy: CFWorldMap.FieldKeys.self)

		title = try fields.decode(String.self, forKey: .title)
		weatherType = try fields.decodeIfPresent(String.self, forKey: .weatherType)
		daytimeType = try fields.decodeIfPresent(String.self, forKey: .daytimeType)

		try fields.resolveLink(forKey: .mapFile, decoder: decoder) { [weak self] asset in
			self?.mapFile = asset as? Asset
		}
	}

	enum Origin: String {
		case local
		case fetched
	}

	private var loadedWorldMap: ARWorldMap?
	
	public var arWorldMap: ARWorldMap? {
		guard let asset = mapFile else { return nil }

		if let loadedWorldMap = loadedWorldMap {
			return loadedWorldMap
		}
		
		if let worldMap = asset.loadWorldMap() {//} ContentfulManager.loadWorldMap(id: asset.id) {
			loadedWorldMap = worldMap
			return worldMap
		} else {
			print("ContentfulWorldMap: Error loading WorldMap")
			return nil
		}
	}
	
	public var timeStamp: Date? {
		var components = mapFile?.title?.components(separatedBy: " ") ?? []
		if components.count < 2 { return nil }
		
		// Throw away place ID
		components.removeFirst()
		
		return Date.date(from: components.removeFirst())
	}
	
	public var fileSize: Int? {
		return mapFile?.file?.details?.size
	}
	
	public var displayTitle: String {
		var components = mapFile?.title?.components(separatedBy: " ") ?? []
		if components.count < 2 { return title }
		
		// Throw away place ID
		components.removeFirst()
		
		guard let timeStamp = Date.date(from: components.removeFirst())?.string(style: .display) else { return title }
		components.insert(timeStamp, at: 0)

		return components.joined(separator: " ")
	}
}
