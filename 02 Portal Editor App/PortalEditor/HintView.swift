import UIKit

class HintView: UIPassThroughView {

	public struct Const {
		static let hintImageMaxSize = CGSize(width: 355, height: 250)
		static let hintImageCornerRadius = CGFloat(8)
		static let bottomInset = CGFloat(20)
	}

    private var viewBottomConstraint = NSLayoutConstraint()
	private var imageBottomConstraint = NSLayoutConstraint()

	init(imageURL: URL, addTo containerView: UIView) {
		super.init(frame: .zero)
		containerView.addSubview(self)
		self.setup(with: imageURL, containerView: containerView)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup(with imageURL: URL, containerView: UIView) {
		guard
			let data = try? Data(contentsOf: imageURL),
			let image = UIImage(data: data)
		else {
			print("Error: No hint image has been set")
			return
		}

		let viewSize = Const.hintImageMaxSize.aspectFit(image.size)

		// Own constraints
		translatesAutoresizingMaskIntoConstraints = false
		viewBottomConstraint = bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: containerView.safeAreaInsets.bottom)
		NSLayoutConstraint.activate([
			centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
			viewBottomConstraint,
			widthAnchor.constraint(equalToConstant: viewSize.width),
			heightAnchor.constraint(equalToConstant: viewSize.height)
		])
		
		// Show Hint Button
		let showHintButton = UIButton()
		showHintButton.setTitle("Hinweis-Bild", for: .normal)
		showHintButton.addTarget(self, action: #selector(showHintImageButtonPressed(sender:)), for: .touchUpInside)
		showHintButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
		showHintButton.backgroundColor = .black
		showHintButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
		showHintButton.addCornerRadius(4)
		showHintButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(showHintButton)
		
		NSLayoutConstraint.activate([
			showHintButton.bottomAnchor.constraint(equalTo: bottomAnchor),
			showHintButton.centerXAnchor.constraint(equalTo: centerXAnchor)
		])

		// Image View
		let hintImageView = UIImageView(image: image)
		hintImageView.addCornerRadius(Const.hintImageCornerRadius)
		hintImageView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(hintImageView)
		
		imageBottomConstraint = hintImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: viewSize.height + containerView.safeAreaInsets.bottom)
		NSLayoutConstraint.activate([
			hintImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
			imageBottomConstraint,
			hintImageView.widthAnchor.constraint(equalTo: widthAnchor),
			hintImageView.heightAnchor.constraint(equalTo: heightAnchor)
		])

		let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(gesture:)))
		swipeDown.direction = .down
		hintImageView.addGestureRecognizer(swipeDown)
		hintImageView.isUserInteractionEnabled = true
	}

	func set(visible: Bool) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.3, animations: {
				let bottomInsets = self.superview?.safeAreaInsets.bottom ?? 0
				self.viewBottomConstraint.constant = visible ? -bottomInsets : self.frame.size.height + bottomInsets
				self.superview?.layoutIfNeeded()
			})
		}
	}
	
    @objc
	private func showHintImageButtonPressed(sender: UIButton) {
		setImage(visible: true)
    }
	
	@objc
	private func handleSwipeDown(gesture: UISwipeGestureRecognizer) {
		setImage(visible: false)
	}
	
	private func setImage(visible: Bool) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.3, animations: {
				self.imageBottomConstraint.constant = visible ? 0 : self.frame.size.height + (self.superview?.safeAreaInsets.bottom ?? 0)
				self.superview?.layoutIfNeeded()
			})
		}
	}
}
