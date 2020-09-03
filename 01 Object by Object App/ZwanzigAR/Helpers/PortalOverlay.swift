import MapKit

class PortalMapOverlay: NSObject, MKOverlay {
	public let coordinate: CLLocationCoordinate2D
	public let boundingMapRect: MKMapRect
	private let portal: Portal

	public let image = UIImage(named: "img_board_portal_small") ?? UIImage()

	init(portal: Portal) {
		self.portal = portal
		let coordinate = portal.location?.coordinate ?? CLLocationCoordinate2D()
		let imageSize = image.size
		self.coordinate = coordinate
		let estimatedTopLeftCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude+0.00021,
																longitude: coordinate.longitude-0.00031)
		self.boundingMapRect = MKMapRect(origin: MKMapPoint(estimatedTopLeftCoordinate),
										 size: MKMapSize(width: Double(imageSize.width*5),
														 height: Double(imageSize.height*5)))
	}
}

class PortalOverlayRenderer: MKOverlayRenderer {
	override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
		guard let overlay = self.overlay as? PortalMapOverlay else { return }

		let rect = self.rect(for: overlay.boundingMapRect)

		UIGraphicsPushContext(context)
		overlay.image.draw(in: rect)
		UIGraphicsPopContext()
	}
}
