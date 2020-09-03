import Foundation

class StoredData {
	public static let shared = StoredData()

	private enum Key: String {
		case localWorldMaps
	}

	public var localWorldMaps: [String: LocalWorldMap] = [:]

	private init() {
		loadLocalWorldMaps()
	}

	public func add(localWorldMap map: LocalWorldMap) {
		localWorldMaps[map.id] = map
		storeLocalWorldMaps()
	}

	public func remove(localWorldMap map: LocalWorldMap) {
		localWorldMaps.removeValue(forKey: map.id)
		storeLocalWorldMaps()
	}
	
	public func loadLocalWorldMaps() {
		var dict: [String: LocalWorldMap] = [:]

		if let data = UserDefaults.standard.value(forKey: StoredData.Key.localWorldMaps.rawValue) as? Data {
			if let localWorldMaps = try? JSONDecoder().decode([LocalWorldMap].self, from: data) {
				for map in localWorldMaps {
					dict[map.id] = map
				}
			}
		}
		localWorldMaps = dict
	}

	private func storeLocalWorldMaps() {
//		var array: [LocalWorldMap] = []
//
//		for map in localWorldMaps {
//			array.append(map.value)
//		}

		if let data = try? JSONEncoder().encode(Array(localWorldMaps.values)) {
			UserDefaults.standard.set(data, forKey: StoredData.Key.localWorldMaps.rawValue)
		}
		print("\(#function) – \(localWorldMaps)")
	}
}
