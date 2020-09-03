import MapKit

class MapAnnotation: NSObject, MKAnnotation {
	var coordinate: CLLocationCoordinate2D // TODO: Why do I need to define them again? Why not simply override?
	var title: String?

	init(title: String?, coordinate: CLLocationCoordinate2D) {
		self.title = title
		self.coordinate = coordinate
	}
}

class CustomMKMarkerSubclass:  MKMarkerAnnotationView {
	override var annotation: MKAnnotation? {
		willSet {
			if newValue != nil {
				// Set the displayPriority to display annotation also when userLocation is in close proximity
				displayPriority = MKFeatureDisplayPriority.required
				canShowCallout = true
			}
		}
	}
}
