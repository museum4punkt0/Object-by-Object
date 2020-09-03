import UIKit

class PortalHeaderImageSection: UIView {
	struct Constants {
		static let imageHeight: CGFloat = 400
	}

	private let portal: Portal

	init(_ portal: Portal) {
		self.portal = portal
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark80Branded

		var constraints = [NSLayoutConstraint]()

		var teaserImage = portal.teaserImage?.loadImage()
		if teaserImage == nil {
			teaserImage = portal.hintImage?.loadImage()?.sepiaFilter(intensity: 0.9)
		}
		
		if let image = teaserImage {
			let imageView = UIImageView(image: image)
			imageView.contentMode = .scaleAspectFill
			add(imageView, accumulator: &constraints)
		}

		NSLayoutConstraint.activate(
			constraints +
			[heightAnchor.constraint(equalToConstant: Constants.imageHeight)]
		)
	}
}
