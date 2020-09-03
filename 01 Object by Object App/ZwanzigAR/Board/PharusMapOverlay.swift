import MapKit

// MARK: PharusMapOverlay

class PharusMapOverlay : NSObject, MKOverlay {
    let image: UIImage
    let boundingMapRect: MKMapRect
    let coordinate: CLLocationCoordinate2D

    init(image: UIImage, rect: MKMapRect) {
        self.image = image
        self.boundingMapRect = rect
		self.coordinate = CLLocationCoordinate2D(latitude: rect.origin.y - rect.height/2, longitude: rect.origin.x + rect.width/2)
    }
}

class PharusMapOverlayRenderer : MKOverlayRenderer {

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = self.overlay as? PharusMapOverlay else {
            return
        }

        let rect = self.rect(for: overlay.boundingMapRect)

        UIGraphicsPushContext(context)
		overlay.image.draw(in: rect)
        UIGraphicsPopContext()
    }
}
