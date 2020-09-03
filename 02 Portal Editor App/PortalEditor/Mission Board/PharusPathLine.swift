import MapKit

class PharusPathLine: MKPolyline {
	enum LineType {
		case outline
		case center
	}

	var color: UIColor?
	var type: LineType?

	var renderer: MKPolylineRenderer {
		let renderer = MKPolylineRenderer(polyline: self)
		renderer.lineWidth = type == .center ? 4 : 6
		renderer.alpha = 1.0
		renderer.strokeColor = type == .center ? color : .dark80Branded
		return renderer
	}

	convenience init(color: UIColor, coordinates: UnsafePointer<CLLocationCoordinate2D>, count: Int) {
		self.init(coordinates: coordinates, count: count)
		self.color = color
	}
}
