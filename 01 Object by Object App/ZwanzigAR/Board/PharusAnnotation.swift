import MapKit

// FIXME: Interim Implementation
class PharusAnnotation: MKPointAnnotation {
	let portal: Portal

	init(portal: Portal) {
		self.portal = portal
		super.init()
		self.coordinate = portal.location?.clLocation.coordinate ?? CLLocationCoordinate2D()
//		self.title = portal.title
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// FIXME: Interim Implementation
class PharusPin: MKMarkerAnnotationView {

	static let reuseIdentifier = String(describing: PharusPin.self)

	init(annotation: PharusAnnotation) {
		super.init(annotation: annotation, reuseIdentifier: PharusPin.reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// - Tag: DisplayConfiguration
    override func prepareForDisplay() {
        super.prepareForDisplay()
		markerTintColor = .blueBranded
		glyphImage = UIImage(named: "Pin Glyph")
    }
}
