import Contentful
import MapKit

extension Location {
	public var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
}
