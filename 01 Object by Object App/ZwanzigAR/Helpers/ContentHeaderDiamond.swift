import UIKit
import Contentful

class ContentHeaderDiamond: UIView {

	struct Constants {
		static let size = CGSize(width: 192, height: 100)
		static let thumb3DFitSize = CGSize(width: 192, height: 160)
		static let thumb2DHorizontalMargin: CGFloat = 36
		static let thumb2DBottomMargin: CGFloat = 40
	}
	
	let story: Story?
	let portal: Portal?
	let object: Object?
	let storyColor: UIColor
	
	init(story: Story) {
		self.story = story
		self.portal = nil
		self.object = nil
		self.storyColor = story.color
		super.init(frame: CGRect(origin: .zero, size: Constants.size))

		setup()
	}
	
	init(portal: Portal, storyColor: UIColor) {
		self.story = nil
		self.portal = portal
		self.object = nil
		self.storyColor = storyColor
		super.init(frame: CGRect(origin: .zero, size: Constants.size))

		setup()
	}
	
	init(object: Object, storyColor: UIColor) {
		self.story = nil
		self.portal = nil
		self.object = object
		self.storyColor = storyColor
		super.init(frame: CGRect(origin: .zero, size: Constants.size))

		setup()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func setup() {
		
		let maskContainer = UIView()
		add(maskContainer)
		
		let params: [(CGColor?, CGColor?, CGFloat)] = [
			(UIColor.dark90Branded.cgColor, UIColor.dark80Branded.cgColor, 10),
			(nil, storyColor.cgColor, 2)
		]
		
		for (fillColor, strokeColor, borderWidth) in params {
			let diamond = CAShapeLayer.diamondShape(bounds: CGRect(origin: .zero, size: Constants.size))
			diamond.fillColor = fillColor
			diamond.strokeColor = strokeColor
			diamond.lineWidth = borderWidth * 2
			diamond.lineJoin = CAShapeLayerLineJoin.miter
			maskContainer.layer.addSublayer(diamond)
		}
		let mask = CAShapeLayer.diamondShape(bounds: CGRect(origin: .zero, size: Constants.size))
		mask.fillColor = UIColor.white.cgColor
		maskContainer.layer.mask = mask
		
		
		
		if let _ = story {
			guard let thumbImage = UIImage(named: "Story Intro Card Header Placeholder") else { return }
			let thumbView = UIImageView(image: thumbImage)
			add(thumbView, activate: [
				thumbView.centerXAnchor.constraint(equalTo: centerXAnchor),
				thumbView.bottomAnchor.constraint(equalTo: bottomAnchor),
				thumbView.widthAnchor.constraint(equalToConstant: Constants.size.width),
				thumbView.heightAnchor.constraint(equalToConstant: Constants.size.width * thumbImage.size.height/thumbImage.size.width)
			])
		}

		else if let portal = portal {
			let indexLabel = UILabel.label(for: .portalHeaderNumber(portal), text: String(portal.numberInStory), alignment: .center)
			add(indexLabel)
		}
		
		else if let object = object, let imageAsset = object.media?.first(where: { $0.isOfType([.image])}) {
			guard let thumbImage = imageAsset.loadImage() else { return }
			
			let objectIs3D = object.media?.first(where: { $0.isOfType([.scn, .usdz]) }) != nil
			
			let thumbView = UIImageView(image: thumbImage)
			if !objectIs3D {
				thumbView.addBorder(color: .whiteBranded, width: 5)
			}

			let thumbFitSize = CGSize(
				width: Constants.thumb3DFitSize.width - (objectIs3D ? 0 : 2 * Constants.thumb2DHorizontalMargin),
				height: Constants.thumb3DFitSize.height - (objectIs3D ? 0 : Constants.thumb2DBottomMargin)
			)
			
			
			let imageSize = (thumbFitSize).aspectFit(thumbImage.size)
			
			add(thumbView, activate: [
				thumbView.centerXAnchor.constraint(equalTo: centerXAnchor),
				thumbView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: objectIs3D ? 0 : -Constants.thumb2DBottomMargin),
				thumbView.widthAnchor.constraint(equalToConstant: imageSize.width),
				thumbView.heightAnchor.constraint(equalToConstant: imageSize.height)
			])
		}
	}
}
