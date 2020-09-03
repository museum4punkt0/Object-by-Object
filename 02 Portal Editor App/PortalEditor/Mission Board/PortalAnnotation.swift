import MapKit

class PortalAnnotation: MKPointAnnotation {
	let portal: CFPortal
	var color: UIColor

	init(portal: CFPortal, color: UIColor) {
		self.portal = portal
		self.color = color
		super.init()
		self.coordinate = portal.location?.clLocation.coordinate ?? CLLocationCoordinate2D()
		self.title = portal.title
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



class PortalPin: MKMarkerAnnotationView {
	static let reuseIdentifier = String(describing: PortalPin.self)
	let pharusAnnotation: PortalAnnotation

	init(annotation: PortalAnnotation) {
		self.pharusAnnotation = annotation
		super.init(annotation: annotation, reuseIdentifier: PortalPin.reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// - Tag: DisplayConfiguration
    override func prepareForDisplay() {
        super.prepareForDisplay()
		markerTintColor = pharusAnnotation.color
		glyphImage = UIImage(named: "Pharus_Glyph")
    }
}
