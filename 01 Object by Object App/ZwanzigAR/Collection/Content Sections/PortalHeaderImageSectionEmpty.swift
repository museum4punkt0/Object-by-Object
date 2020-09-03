import UIKit

class PortalHeaderImageSectionEmpty: UIView {
	struct Constants {
		static let imageHeight: CGFloat = 400
	}

	init() {
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark80Branded

		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: Constants.imageHeight),
		])
	}
}
