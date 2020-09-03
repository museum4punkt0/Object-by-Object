import UIKit

extension UIAlertController {
	static func presentAlert(_ alert: UIAlertController, in viewController: UIViewController? = nil) {
		DispatchQueue.main.async {
			(viewController ?? UIViewController.topMost)?.present(alert, animated: true)
		}
	}
	
	static func presentSimpleAlert(title: String, message: String, in viewController: UIViewController? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		presentAlert(alert, in: viewController)
    }
}
