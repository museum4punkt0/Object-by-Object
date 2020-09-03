import UIKit

class UICircleImageView: UIImageView {
	override func layoutSubviews() {
		super.layoutSubviews()
		
		layer.masksToBounds = true
		layer.cornerRadius = min(frame.size.width, frame.size.height) / 2
	}
}
