import Foundation
import Contentful

class NewPlaceClass: Codable {

}

class PlaceManager {
	static let shared = PlaceManager()

	public var places: [NewPlaceClass] = []

	private let urlKey = "Places"
	private let contentfulManager = ContentfulManager.shared

	private init() {
		// load the locally stored version of places
		if let data = UserDefaults.standard.object(forKey: urlKey) as? Data {
		  places = (try? JSONDecoder().decode([NewPlaceClass].self, from: data)) ?? []
		}

		NotificationCenter.default.addObserver(self, selector: #selector(placesFetched), name: .placesFetched, object: nil)
		contentfulManager.fetchPlaces()

		// load all the places from Contentful and store in an array

		// Then compare the fetched places with the currently stored places
		// & update whatever properties need to be updated

		// Then save the new array again
	}

	private func savePlaces() {
	  if let encoded = try? JSONEncoder().encode(places) {
		UserDefaults.standard.set(encoded, forKey: urlKey)
	  }
	}

	@objc
	private func placesFetched() {

	}
}
