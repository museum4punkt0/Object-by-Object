import UIKit

class SyncIndicatorViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()

//		view.backgroundColor = UIColor.red.withAlphaComponent(0.25)
		
		let backgroundDimension: CGFloat = 80
		let background = UIView(frame: CGRect(x: 0, y: 0, width: backgroundDimension, height: backgroundDimension))
		background.backgroundColor = UIColor.dark90Branded.withAlphaComponent(0.5)
		background.addCornerRadius()
		view.add(background, activate: [
			background.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			background.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			background.widthAnchor.constraint(equalToConstant: backgroundDimension),
			background.heightAnchor.constraint(equalToConstant: backgroundDimension)
		])
		
		let spinner = UIActivityIndicatorView(style: .large)
		spinner.color = .white
		view.add(spinner, activate: [
			spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		spinner.startAnimating()
	}
}
