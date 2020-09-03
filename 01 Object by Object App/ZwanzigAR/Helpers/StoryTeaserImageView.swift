import UIKit

class StoryTeaserImageView: UIView {
	public struct Constants {
		static let diamondImageViewDimension: CGFloat = 248
	}
	
	private var imageView: UIImageView
	private lazy var gradientOverlayImageView = UIImageView(image: UIImage(named: "Tour Diamond Image Shadow Overlay"))
	private lazy var maskImageView = UIImageView(image: UIImage(named: "Tour Diamond Image Mask"))
	
	init(story: Story) {
		imageView = UIImageView.init(image: story.teaserImage?.loadImage() ?? UIImage(named: "Tour Diamond Image Placeholder"))
		imageView.contentMode = .scaleAspectFill
		imageView.layer.masksToBounds = true
		
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		let containerView = UIView()
		containerView.mask = maskImageView
		add(containerView)
		
		containerView.add(imageView)
		containerView.add(gradientOverlayImageView)

		addShadow()
	}
}
