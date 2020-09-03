import MapKit

class UserLocationAnnotation: MKAnnotationView {
	static let reuseidentifier = String(describing: "User Location")

	init(annotation: MKAnnotation?) {
		super.init(annotation: annotation, reuseIdentifier: UserLocationAnnotation.reuseidentifier)
		image = UIImage(named: "img_user_location")
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
