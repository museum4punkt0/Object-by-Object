import MapKit

class PharusMapView: MKMapView, MKMapViewDelegate {
	struct Constants {
		static let pitch: CGFloat = 80
	}
	
	enum Style {
		case original
		case monochrome
		
		var mapImage: UIImage? {
			switch self {
			case .original:
//				return UIImage(named: "PharusMapOriginal")
				return UIImage(named: "Pharus_Map_Berlin_1929_fullResolution")
			case .monochrome:
				return UIImage(named: "PharusMapMonochrome")
			}
		}
	}
	
	enum Mode {
		case board
		case navigation

		var style: Style {
			switch self {
			case .board:
				return .original
			case .navigation:
				return .original
			}
		}
		
		var isUserInteractionEnabled: Bool {
			switch self {
			case .board:
				return true
			case .navigation:
				return false
			}
		}
		
		var cameraDistance: CLLocationDistance {
			switch self {
			case .board:
				return 3000
			case .navigation:
				return 2000
			}
		}
		
		var cameraZoomRange: MKMapView.CameraZoomRange? {
			switch self {
			case .board:
				return MKMapView.CameraZoomRange(minCenterCoordinateDistance: 2_000, maxCenterCoordinateDistance: 10_000)
			case .navigation:
//				return MKMapView.CameraZoomRange(minCenterCoordinateDistance: 250, maxCenterCoordinateDistance: 10_000)
				return MKMapView.CameraZoomRange(minCenterCoordinateDistance: 10, maxCenterCoordinateDistance: 10_000)
			}
		}
	}
	
	private let mode: Mode
	private var pharusMapOverlay: PharusMapOverlay?
	private var canvasOverlay: MKPolygon?
	
	public var updateableOverlays: [MKOverlay] {
		return overlays.filter({ !($0 is PharusMapOverlay || $0 is MKPolygon) })
	}
	
	init(mode: Mode) {
		self.mode = mode
		super.init(frame: .zero)
		setupOverlay()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func setupOverlay() {
		overrideUserInterfaceStyle = .light

		delegate = self

		showsUserLocation = true
		showsBuildings = false
		isRotateEnabled = false
		isPitchEnabled = false
		isUserInteractionEnabled = mode.isUserInteractionEnabled

		// add pharus pin overlay
		let north = 52.5559218//52.57
		let south = 52.4582616//52.447
		let west = 13.2587024//13.254
		let east = 13.4859393//13.495

		let centerCoordinate =  CLLocationCoordinate2D(latitude: south + (north-south)/2, longitude: west + (east-west)/2)

		let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: north, longitude: west))
		let bottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: south, longitude: east))
		let boundingRect = MKMapRect(x: topLeft.x, y: topLeft.y, width: fabs(bottomRight.x-topLeft.x), height: fabs(bottomRight.y-topLeft.y))

		let canvasCorners = [
			CLLocationCoordinate2D(latitude: north+0.1, longitude: west-0.1),
			CLLocationCoordinate2D(latitude: north+0.1, longitude: east+0.1),
			CLLocationCoordinate2D(latitude: south-0.1, longitude: east+0.1),
			CLLocationCoordinate2D(latitude: south-0.1, longitude: west-0.1)
		]

		
		let canvasOverlay = MKPolygon.init(coordinates: canvasCorners, count: canvasCorners.count)
		addOverlay(canvasOverlay)
		self.canvasOverlay = canvasOverlay

		if let mapImage = mode.style.mapImage {
			let pharusMapOverlay = PharusMapOverlay(image: mapImage, rect: boundingRect)
			addOverlay(pharusMapOverlay)
			self.pharusMapOverlay = pharusMapOverlay
		}
		
		// add camera
		let mapCamera = MKMapCamera(lookingAtCenter: centerCoordinate, fromDistance: mode.cameraDistance, pitch: Constants.pitch, heading: 0)
		camera = mapCamera
		
		// restrict panning on the map
		let boundaryRegion = MKCoordinateRegion(center: centerCoordinate, span: MKCoordinateSpan(latitudeDelta: north-south, longitudeDelta: east-west))
		let cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: boundaryRegion)
		self.cameraBoundary = cameraBoundary
		
		// restrict zooming on the map
		cameraZoomRange = mode.cameraZoomRange
	}
	
	func setMapOverlay(visible: Bool) {
		guard
			let pharusMapOverlay = pharusMapOverlay,
			let canvasOverlay = canvasOverlay
		else { return }
		if visible {
			addOverlays([canvasOverlay, pharusMapOverlay])
		}
		else {
			removeOverlays([pharusMapOverlay, canvasOverlay])
		}
	}
	
	// MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let pharusAnnotation = annotation as? PharusAnnotation {
			return PharusPin(annotation: pharusAnnotation)
		}
		if let portalAnnotation = annotation as? PortalAnnotation {
			return PortalAnnotationView(annotation: portalAnnotation)
		}

		if let userLocationAnnotation = annotation as? MKUserLocation {
			return UserLocationAnnotation(annotation: userLocationAnnotation)
		}
		return nil
    }

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let portalMapOverlay = overlay as? PortalMapOverlay {
			return PortalOverlayRenderer.init(overlay: portalMapOverlay)
		}

		if let pharusMapOverlay = overlay as? PharusMapOverlay {
			print("pharusMapOverlay: \(pharusMapOverlay.boundingMapRect)")
			return PharusMapOverlayRenderer.init(overlay: pharusMapOverlay)
		}

		if let polyline = overlay as? PharusPathLine {
//			let renderer = MKPolylineRenderer(polyline: polyline)
//			renderer.lineWidth = 5.0
//			renderer.alpha = 1.0
//			renderer.strokeColor = .dark80Branded
//			return renderer
			return polyline.renderer
		}
		
		if let canvasOverlay = overlay as? MKPolygon {
			print("canvasOverlay.coordinate: \(canvasOverlay.coordinate)")
			let renderer = MKPolygonRenderer(polygon: canvasOverlay)
			renderer.fillColor = .pharusOffWhite
			return renderer
		}
		
		print("Unexpected overlay")
		
		return MKOverlayRenderer()
	}

	private var currentlySelectedAnnotationView: MKAnnotationView?

	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		if let portalAnnotationView = view as? PortalAnnotationView {
			if currentlySelectedAnnotationView == nil {
				currentlySelectedAnnotationView = portalAnnotationView
				portalAnnotationView.showCallout(true)
			}
		}
	}

	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		if let portalAnnotationView = view as? PortalAnnotationView {
			if currentlySelectedAnnotationView == portalAnnotationView {
				if
					let lastTouchPosition = lastTouchPosition,
					let hitView = portalAnnotationView.hitTest(lastTouchPosition, with: .none) {
					guard let _ = hitView as? UIButton else {
						// Hide callout if button was tapped
						portalAnnotationView.showCallout(false)
						currentlySelectedAnnotationView = nil
						return
					}
					// Do nothing here
					// Continue to show the callout if another part of the callout was tapped
				} else {
					currentlySelectedAnnotationView = nil
					portalAnnotationView.showCallout(false)
				}
			}
		}
	}

	private var lastTouchPosition: CGPoint?
	public var touchesBeganAction: (() -> ())?

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)

		touchesBeganAction?()
		
		if let touch = touches.first {
			if let selectedAnnotationView = currentlySelectedAnnotationView {
				lastTouchPosition = touch.location(in: selectedAnnotationView)
			} else {
				lastTouchPosition = touch.location(in: self)
			}
		}
	}
}

class PharusPathLine: MKPolyline {
	enum LineType {
		case outline
		case center
	}
	
	var type: LineType?
	
	var renderer: MKPolylineRenderer {
		let renderer = MKPolylineRenderer(polyline: self)
		renderer.lineWidth = type == .center ? 8 : 16
		renderer.alpha = 1.0
		renderer.strokeColor = type == .center ? (GameStateManager.shared.currentStory?.color ?? .whiteBranded) : .dark80Branded
		return renderer
	}
}
