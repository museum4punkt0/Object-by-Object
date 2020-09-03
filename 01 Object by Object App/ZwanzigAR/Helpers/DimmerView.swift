import UIKit

class DimmerView: UIPassThroughView {
	init() {
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = UIColor.dark90Branded.withAlphaComponent(0.0)
	}

	public func hide() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: {
				self.backgroundColor = UIColor.dark90Branded.withAlphaComponent(0.0)
			})
		}
	}

	public func show() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: {
				self.backgroundColor = UIColor.dark90Branded.withAlphaComponent(0.8)
			})
		}
	}
}
