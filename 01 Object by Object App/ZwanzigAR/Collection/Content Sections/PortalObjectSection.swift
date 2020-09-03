import UIKit

class PortalObjectSection: UIView {
	struct Constants {
		static let topPadding: CGFloat = 96
		static let headlineTopPadding: CGFloat = 48
		static let verticalPadding: CGFloat = 16
		static let horizontalPadding: CGFloat = 16
		static let bottomPadding: CGFloat = 64
		static let arButtonRightInset: CGFloat = 6
		static let teaserImageWidthMax: CGFloat = 200
		static let teaserImageHeightMax: CGFloat = 200
		static let frameWidth: CGFloat = 4
		static let buttonHorizontalSpacer: CGFloat = 4
	}

	private let object: Object
	private let count: Int
	private let objectState: Object.State

	private var titleText: String {
		return object.title ?? "Dies ist der Titel"
	}
	private var bodyText: String {
		return object.objectStory?.text ?? "Es war einmal ein Objekt..."
	}
	private var emptyText: String {
		return "Hier fehlt noch etwas.\nFinden Sie es im Portal!"
	}
	private var objectImage: UIImage? {
		if object.containerType == .film {
			for media in object.media ?? [] {
				if media.isOfType([.video]) {
					return Video.frame(from: media.localURL, at: 0)
				}
			}
		} else if object.containerType == .gramophone {
			return UIImage(named: "img_gramophone")
		} else {
			for media in object.media ?? [] {
				if media.isOfType([.image]) {
					return media.loadImage()
				}
			}
		}
		return nil
	}

	private lazy var number = UILabel.label(for: .hugeNumber, text: "\(count)")
	private let decorativeTriangle = UIImageView(image: UIImage(named: "img_decorative_triangle"))
	private let secondBackground = UIView()
	private var sourceMuseum: SourceMuseumView?

	init(object: Object, count: Int) {
		self.object = object
		self.count = count
		self.objectState = object.state
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		setupBasicSection()

		switch objectState {
		case .hidden, .seen:
			setupEmptySection()
		case .collected:
			setupCollectedSection()
		}
	}

	private func setupBasicSection() {
		backgroundColor = .dark80Branded

		number.translatesAutoresizingMaskIntoConstraints = false
		addSubview(number)

		decorativeTriangle.translatesAutoresizingMaskIntoConstraints = false
		addSubview(decorativeTriangle)

		secondBackground.backgroundColor = .dark90Branded
		secondBackground.translatesAutoresizingMaskIntoConstraints = false
		addSubview(secondBackground)

		NSLayoutConstraint.activate([
			decorativeTriangle.topAnchor.constraint(equalTo: topAnchor, constant: Constants.topPadding),
			decorativeTriangle.centerXAnchor.constraint(equalTo: centerXAnchor),
			decorativeTriangle.widthAnchor.constraint(equalTo: widthAnchor),
			decorativeTriangle.heightAnchor.constraint(equalToConstant: decorativeTriangle.image?.size.height ?? 0),

			number.centerYAnchor.constraint(equalTo: decorativeTriangle.centerYAnchor),
			number.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -100),

			secondBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
			secondBackground.widthAnchor.constraint(equalTo: widthAnchor),
			secondBackground.topAnchor.constraint(equalTo: decorativeTriangle.bottomAnchor),
		])
	}

	private func setupEmptySection() {
		let objectImagePlaceholder = UIImageView(image: UIImage(named: "img_empty_object"))
		objectImagePlaceholder.translatesAutoresizingMaskIntoConstraints = false
		addSubview(objectImagePlaceholder)

		let emptyLabel = UILabel.label(for: .body, text: emptyText, alignment: .center)
		emptyLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(emptyLabel)

		NSLayoutConstraint.activate([
			objectImagePlaceholder.centerXAnchor.constraint(equalTo: centerXAnchor),
			objectImagePlaceholder.centerYAnchor.constraint(equalTo: decorativeTriangle.centerYAnchor, constant: 44),

			emptyLabel.topAnchor.constraint(equalTo: objectImagePlaceholder.bottomAnchor),
			emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			emptyLabel.bottomAnchor.constraint(equalTo: secondBackground.bottomAnchor, constant: -Constants.bottomPadding),

			secondBackground.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}

	private func setupCollectedSection() {
		let teaserImage = objectImage
		let aspectRatio = (teaserImage?.size.height ?? 1)/(teaserImage?.size.width ?? 1)
		let teaserImageWidth = Constants.teaserImageWidthMax * aspectRatio < Constants.teaserImageHeightMax ? Constants.teaserImageWidthMax : Constants.teaserImageHeightMax/aspectRatio
		let teaserImageHeight = teaserImageWidth * aspectRatio
		let imageView = UIImageView(image: teaserImage)
		imageView.contentMode = .scaleAspectFit
		imageView.translatesAutoresizingMaskIntoConstraints = false

		switch object.containerType {
		case .selfContained:
			addSubview(imageView)

			NSLayoutConstraint.activate([
				imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
				imageView.bottomAnchor.constraint(equalTo: decorativeTriangle.bottomAnchor, constant: 64),
				imageView.heightAnchor.constraint(equalToConstant: 300)
			])
		case .gramophone:
			addSubview(imageView)

			NSLayoutConstraint.activate([
				imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
				imageView.bottomAnchor.constraint(equalTo: decorativeTriangle.bottomAnchor, constant: 36),
				imageView.heightAnchor.constraint(equalToConstant: 240)
			])
		case .film:
			let frame = UIView()
			frame.backgroundColor = .whiteBranded
			frame.layer.shadowColor = UIColor.black.cgColor
			frame.layer.shadowOffset = CGSize(width: 0, height: 5)
			frame.layer.shadowRadius = 10
			frame.layer.shadowOpacity = 1.0
			frame.translatesAutoresizingMaskIntoConstraints = false
			frame.addSubview(imageView)
			addSubview(frame)

			let playSymbol = UIImageView(image: UIImage(named: "icon_video_play"))
			playSymbol.translatesAutoresizingMaskIntoConstraints = false
			addSubview(playSymbol)

			NSLayoutConstraint.activate([
				frame.widthAnchor.constraint(equalTo: imageView.widthAnchor, constant: Constants.frameWidth*2),
				frame.heightAnchor.constraint(equalTo: imageView.heightAnchor, constant: Constants.frameWidth*2),
				frame.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
				frame.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

				imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
				imageView.bottomAnchor.constraint(equalTo: decorativeTriangle.bottomAnchor, constant: 16),
				imageView.widthAnchor.constraint(equalToConstant: teaserImageWidth),
				imageView.heightAnchor.constraint(equalToConstant: teaserImageHeight),

				playSymbol.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
				playSymbol.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
			])
		case .cameraOnTripod, .paper, .pictureFrame, .slideProjector, .slideProjectorWithScreen:
			let frame = UIView()
			frame.backgroundColor = .whiteBranded
			frame.layer.shadowColor = UIColor.black.cgColor
			frame.layer.shadowOffset = CGSize(width: 0, height: 5)
			frame.layer.shadowRadius = 10
			frame.layer.shadowOpacity = 1.0
			frame.translatesAutoresizingMaskIntoConstraints = false
			frame.addSubview(imageView)
			addSubview(frame)

			NSLayoutConstraint.activate([
				frame.widthAnchor.constraint(equalTo: imageView.widthAnchor, constant: Constants.frameWidth*2),
				frame.heightAnchor.constraint(equalTo: imageView.heightAnchor, constant: Constants.frameWidth*2),
				frame.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
				frame.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

				imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
				imageView.bottomAnchor.constraint(equalTo: decorativeTriangle.bottomAnchor, constant: 16),
				imageView.widthAnchor.constraint(equalToConstant: teaserImageWidth),
				imageView.heightAnchor.constraint(equalToConstant: teaserImageHeight)
			])
		}

		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openObjectInAR))
		imageView.isUserInteractionEnabled = true
		imageView.addGestureRecognizer(tapGestureRecognizer)

		let arButton = DiamondButton(.augmentedReality, action: { [weak self] in
			self?.openObjectInAR()
		})
		arButton.translatesAutoresizingMaskIntoConstraints = false
		addSubview(arButton)

		let shareButton = DiamondButton(.share, action: { [weak self] in
			self?.share()
		})
		if object.isClearedForSharing {
			shareButton.translatesAutoresizingMaskIntoConstraints = false
			addSubview(shareButton)
		}
		
		let title = UILabel.label(for: .headline2, text: titleText)
		title.translatesAutoresizingMaskIntoConstraints = false
		addSubview(title)

		let body = UILabel.label(for: .body, text: bodyText)
		body.translatesAutoresizingMaskIntoConstraints = false
		addSubview(body)

		if let institution = object.institution {
			sourceMuseum = SourceMuseumView(title: institution.title ?? "",
												logo: institution.logo?.loadImage())
			sourceMuseum?.translatesAutoresizingMaskIntoConstraints = false
			addSubview(sourceMuseum!)
		}

		let arAndShareButtonConstraints = object.isClearedForSharing ? [
			arButton.rightAnchor.constraint(equalTo: centerXAnchor),
			arButton.topAnchor.constraint(equalTo: body.bottomAnchor, constant: Constants.verticalPadding),
			arButton.bottomAnchor.constraint(equalTo: secondBackground.bottomAnchor),

			shareButton.leftAnchor.constraint(equalTo: centerXAnchor),
			shareButton.topAnchor.constraint(equalTo: body.bottomAnchor, constant: Constants.verticalPadding),
			shareButton.bottomAnchor.constraint(equalTo: secondBackground.bottomAnchor)
		] : [
			arButton.centerXAnchor.constraint(equalTo: centerXAnchor),
			arButton.topAnchor.constraint(equalTo: body.bottomAnchor, constant: Constants.verticalPadding),
			arButton.bottomAnchor.constraint(equalTo: secondBackground.bottomAnchor)
		]
		
		NSLayoutConstraint.activate([
			title.centerXAnchor.constraint(equalTo: centerXAnchor),
			title.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			title.topAnchor.constraint(equalTo: secondBackground.topAnchor, constant: Constants.headlineTopPadding),

			body.centerXAnchor.constraint(equalTo: centerXAnchor),
			body.widthAnchor.constraint(equalTo: widthAnchor, constant: -Constants.horizontalPadding*2),
			body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Constants.verticalPadding),

			secondBackground.bottomAnchor.constraint(equalTo: sourceMuseum?.topAnchor ?? bottomAnchor)
		] + arAndShareButtonConstraints)

		if let sourceMuseum = sourceMuseum {
			NSLayoutConstraint.activate([
				sourceMuseum.widthAnchor.constraint(equalTo: widthAnchor),
				sourceMuseum.centerXAnchor.constraint(equalTo: centerXAnchor),
				sourceMuseum.topAnchor.constraint(equalTo: secondBackground.bottomAnchor),
				sourceMuseum.bottomAnchor.constraint(equalTo: bottomAnchor)
			])
		}
	}

	@objc private func openObjectInAR() {
		let arVC = ARSessionViewController(object: object)
		arVC.modalPresentationStyle = .fullScreen
		UIViewController.topMost?.present(arVC, animated: true, completion: nil)
	}
	
	private func share() {
		guard
			let media = object.mediaSet.firstObject as? Asset,
			let containingVC = containingViewController
		else { return }

		var shareText = ""
		if
			let institutionTitle = object.institution?.title,
			let objectTitle = object.title
		{
			shareText = "Schau, ich habe das Objekt »\(objectTitle)« in der App »Object by Object« gefunden. Es wurde durch »\(institutionTitle)« zur Verfügung gestellt."
		} else {
			shareText = "Schau, was ich mit der App »Object by Object« der Berliner Museen gefunden habe!"
		}

		let activityVC = UIActivityViewController(activityItems: [media.localURL, shareText], applicationActivities: nil)
		activityVC.modalPresentationStyle = .popover
		activityVC.popoverPresentationController?.sourceView = self
		activityVC.popoverPresentationController?.permittedArrowDirections = [.up, .down]
		containingVC.present(activityVC, animated: true)
	}
}
