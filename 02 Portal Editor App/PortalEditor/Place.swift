// REMOVE
// ALL
// THIS



import CoreLocation
import SceneKit

class Place {
	public let name: String
	public let urlKey: String
	public let location: CLLocation
	private let modelTitles = ["Portal", "Gramophone01", "KalininBust01", "BronzeStatue"]
	private let modelNames = ["portal", "gramophone", "kalinin-bust", "bronze-statue"]
	public var objects: [String: VirtualObject] = [:]

	public var url: URL {
		return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(urlKey).map")
	}

	public var encoded: PlaceRaw {
		return PlaceRaw(name: name,
						   urlKey: urlKey,
						   latitude: location.coordinate.latitude,
						   longitude: location.coordinate.longitude)
	}

	init(from raw: PlaceRaw) {
		name = raw.name
		urlKey = raw.urlKey
		location = CLLocation(latitude: raw.latitude, longitude: raw.longitude)
	}

	init(name: String, urlName: String, location: CLLocation) {
		self.name = name
		self.urlKey = urlName
		self.location = location
	}

	deinit {
		print("Place deallocated")
	}

	public func distance(to location: CLLocation) -> Double {
		return self.location.distance(from: location)
	}

//	public func setupInitialObjects(controller: VirtualObjectManipulator) {
//		var initialObjects = [String: VirtualObject]()
//
//		for index in 0..<modelTitles.count {
//			let initialOffset = SCNVector3(Float.random(in: -0.2...1.5), 0, Float.random(in: -3...0))
//			initialObjects[modelTitles[index]] = VirtualObject(modelName: modelNames[index],
//														   title: modelTitles[index],
//														   controller: controller,
//														   initialOffset: initialOffset)
//		}
//		objects = initialObjects
//	}
}

struct PlaceRaw: Codable {
	public let name: String
	public let urlKey: String
	public let latitude: Double
	public let longitude: Double

	init(name: String, urlKey: String, latitude: Double, longitude: Double) {
		self.name = name
		self.urlKey = urlKey
		self.latitude = latitude
		self.longitude = longitude
	}
}
