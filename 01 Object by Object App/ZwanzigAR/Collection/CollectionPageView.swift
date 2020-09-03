import UIKit

class CollectionPageView: UIView, UIScrollViewDelegate {
	enum PageType {
		case storyStart(Story)
		case portal(Portal)
		case portalPlaceHolder(Story)
		case storyEnd(Story)
	}

	static let pageWidth: CGFloat = UIScreen.main.bounds.width

	private let pageType: PageType

	private var sections = [UIView]()

	init(_ pageType: PageType) {
		self.pageType = pageType
		super.init(frame: .zero)
		setupSections()
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupSections() {
		switch pageType {
		case .storyStart(let story):
			sections.append(StoryHeaderSection(state: .start, story: story))
//			sections.append(AudioButtonSection(.storyStart(story)))
			sections.append(TextSection(.storyStart(story)))

		case .portal(let portal):
			sections.append(PortalHeaderImageSection(portal))
			sections.append(PortalHeaderSection(portal))
			sections.append(TitleSection(.portal(portal)))
//			sections.append(AudioButtonSection(.portal(portal)))
			sections.append(TextSection(.portal(portal)))
			sections.append(PharusPinSection(portal))
			for (i, object) in (portal.objects ?? []).enumerated() {
				sections.append(PortalObjectSection(object: object, count: i+1))
			}

		case .portalPlaceHolder(let story):
			sections.append(PortalHeaderImageSectionEmpty())
			sections.append(PortalHeaderSectionEmpty(storyColor: story.color))
			sections.append(TextSection(.portalPlaceHolder(story)))

		case .storyEnd(let story):
			sections.append(StoryHeaderSection(state: .end, story: story))
//			sections.append(AudioButtonSection(.storyEnd(story)))
			sections.append(TextSection(.storyEnd(story)))
		}
		sections.append(PaddingSection(height: 120))
	}

	private func setup() {
		let scrollView = UIScrollView()
		scrollView.backgroundColor = .dark90Branded
		scrollView.delegate = self
		scrollView.isScrollEnabled = true
		scrollView.showsVerticalScrollIndicator = true
		add(scrollView)

		let scrollContentView = UIView()
		scrollView.add(scrollContentView)
		NSLayoutConstraint.activate([
			scrollContentView.widthAnchor.constraint(equalTo: widthAnchor),
		])

		for (i, section) in sections.enumerated() {
			section.translatesAutoresizingMaskIntoConstraints = false
			scrollContentView.addSubview(section)

			NSLayoutConstraint.activate([
				section.centerXAnchor.constraint(equalTo: scrollContentView.centerXAnchor),
				section.widthAnchor.constraint(equalTo: scrollContentView.widthAnchor),
				section.topAnchor.constraint(equalTo: sections[safe: i-1]?.bottomAnchor ?? scrollContentView.topAnchor)
			])

			if i==sections.count-1 {
				NSLayoutConstraint.activate([section.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor)])
			}
		}

		for section in sections {
			if let section = section as? PortalHeaderSection {
				bringSubviewToFront(section)
			}
		}
	}
}
