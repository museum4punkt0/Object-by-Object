import ARKit

class LocalWorldMap: Codable, WorldMap {
	var id: String {
		portalID + "_" + timeStamp.string(style: .filename) + "_" + title.replacingOccurrences(of: " ", with: "_")
	}
	let title: String
	var timeStamp: Date
	var isInitialWorldMapPresent: Bool
	let portalID: String
	var url: URL {
		return FileManager.default.documentSubfolderURL(.locallyGenerated).appendingPathComponent("\(id)").appendingPathExtension("map")
	}

	init(title: String, isInitialWorldMapPresent: Bool = false, portalID: String) {
		self.title = title
		self.isInitialWorldMapPresent = isInitialWorldMapPresent
		self.timeStamp = Date()
		self.portalID = portalID
	}

	public var arWorldMap: ARWorldMap? {
		guard let data = try? Data(contentsOf: url) else { return nil }
		do {
			let worldMap = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ARWorldMap
			isInitialWorldMapPresent = true
			return worldMap
		} catch {
			print("LocalWorldMap – error loading data: \(error.localizedDescription)")
			return nil
		}
	}

	public var fileSize: Int? {
		return try? Data(contentsOf: url).count
	}

	public func save(map: ARWorldMap) {
		do {
			let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
			try data.write(to: url)
			isInitialWorldMapPresent =  true
		} catch {
			print("LocalWorldMap: Error storing data")
		}
	}

	public func removeMapFile() {
		do {
			try FileManager.default.removeItem(at: url)
		} catch {
			print("LocalWorldMap: Error removing data")
		}
	}
	
	public var displayTitle: String {
		return "\(timeStamp.string(style: .display)) \(title)"
	}
	
	
}

extension Date {
//	public func string(_ style: DateFormatter.Style) -> String {
//		let formatter = DateFormatter()
//		formatter.dateStyle = .short
//		formatter.timeStyle = .short
//		return formatter.string(from: self)
//	}

	public enum TimeStampStyle: String, CaseIterable {
		case display = "yy.MM.dd HH:mm:ss"
		case filename = "yyMMddHHmmss"
	}
	
	public func string(style: TimeStampStyle) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = style.rawValue
		return formatter.string(from: self)
	}
	
	public static func date(from string: String) -> Date? {
		for style in TimeStampStyle.allCases {
			let dateFormatter = DateFormatter()
//			dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
			dateFormatter.dateFormat = style.rawValue
			if let date = dateFormatter.date(from: string) { return date }
		}
		return nil
	}
}
