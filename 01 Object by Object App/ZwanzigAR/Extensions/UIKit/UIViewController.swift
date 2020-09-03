import UIKit

extension UIViewController {
	static var topMost: UIViewController? {
//		guard var topController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
		guard var topController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
		while let presentedViewController = topController.presentedViewController {
			topController = presentedViewController
		}
		return topController
	}
	
	func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

	func add(_ child: UIViewController, activate constraints: [NSLayoutConstraint]) {
        addChild(child)
		view.add(child.view, activate: constraints)
        child.didMove(toParent: self)
    }

    func remove() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
