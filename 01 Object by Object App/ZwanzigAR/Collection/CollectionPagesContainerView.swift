import UIKit

class CollectionPagesContainerView: UIView, UIScrollViewDelegate {
	static let containerHeight: CGFloat = UIScreen.main.bounds.height

	private let story: Story
	private let portal: Portal?
	private let startPage: Int
	private let topHubView: HubView

	private let pageViews: [CollectionPageView]
	private let scrollView = UIScrollView()

	init(story: Story,
		 openAt portal: Portal? = nil,
		 hubView: HubView) {
		self.story = story
		self.portal = portal
		if let startPortalNumber = portal?.numberInStory {
			startPage = startPortalNumber
		} else {
			startPage = 0
		}
		self.topHubView = hubView

		var pageViews = [CollectionPageView]()
		pageViews.append(CollectionPageView(.storyStart(story)))
		for portal in story.visiblePortals {
			pageViews.append(CollectionPageView(.portal(portal)))
		}
		pageViews.append(CollectionPageView(story.state == .completed ? .storyEnd(story) : .portalPlaceHolder(story)))
		self.pageViews = pageViews

		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		backgroundColor = .dark90Branded

		scrollView.delegate = self
		scrollView.isPagingEnabled = true
		scrollView.showsHorizontalScrollIndicator = true
		scrollView.showsVerticalScrollIndicator = false
		add(scrollView)

		let scrollContentView = UIView()
		scrollView.add(scrollContentView)
		NSLayoutConstraint.activate([scrollContentView.heightAnchor.constraint(equalTo: heightAnchor)])

		for (i, pageView) in pageViews.enumerated() {
			scrollContentView.add(pageView, activate: [
				pageView.leftAnchor.constraint(equalTo: pageViews[safe: i-1]?.rightAnchor ?? scrollContentView.leftAnchor),
				pageView.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
				pageView.widthAnchor.constraint(equalTo: widthAnchor),
				pageView.heightAnchor.constraint(equalTo: heightAnchor)
			])
		}
		if let lastSubview = scrollContentView.subviews.last {
			NSLayoutConstraint.activate([lastSubview.rightAnchor.constraint(equalTo: scrollContentView.rightAnchor)])
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		scrollView.contentOffset.x = UIScreen.main.bounds.width * CGFloat(startPage)
	}

	// MARK: UIScrollViewDelegate
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		let contentOffset = scrollView.contentOffset.x
		let pageNumber = Int(contentOffset / UIScreen.main.bounds.width + 1)
		topHubView.updateContent(elementType: .pageIndicator(pageNumber, story.visiblePortals.count+1))
	}
}
