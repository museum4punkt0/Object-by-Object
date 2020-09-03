import UIKit

class NavigatorButton: UIView {
	private var tool: NavigationTool?
	private var navigationAction: () -> Void
	private var collectionAction: () -> Void
	private var imageView = UIImageView()

	init(_ tool: NavigationTool?, navigationAction: @escaping () -> Void, collectionAction: @escaping () -> Void) {
		self.tool = tool
		self.navigationAction = navigationAction
		self.collectionAction = collectionAction
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		isUserInteractionEnabled = true

		add(imageView, activate: [
//			imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
//			imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
			imageView.topAnchor.constraint(equalTo: topAnchor),
			imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
			imageView.leftAnchor.constraint(equalTo: leftAnchor),
			imageView.rightAnchor.constraint(equalTo: rightAnchor)
		])
		
//		NSLayoutConstraint.activate([
//			widthAnchor.constraint(equalTo: imageView.widthAnchor),
//			heightAnchor.constraint(equalTo: imageView.heightAnchor)
//		])

	}

	public func update(_ tool: NavigationTool?) {
		self.tool = tool
		if let tool = self.tool {
			imageView.image = tool.buttonImage
		}
		else {
			imageView.image = UIImage(named: "btn_collection")
		}
		imageView.addShadow()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
		impactFeedbackGenerator.prepare()
		impactFeedbackGenerator.impactOccurred()
		tool != nil ? navigationAction() : collectionAction()
	}
}
