import UIKit

class PaddingSection: UIView {
	private let height: CGFloat

	init(height: CGFloat) {
		self.height = height
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark90Branded

		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: height)
		])
	}
}
