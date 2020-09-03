import UIKit

class ActionView: UIView {
	private let action: () -> Void

	init(action: @escaping () -> Void ) {
		self.action = action
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true
		backgroundColor = .clear
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		action()
	}
}
