import Contentful

final class CFStory: EntryDecodable, FieldKeysQueryable, Equatable, Resource {

	static func == (lhs: CFStory, rhs: CFStory) -> Bool {
		lhs.sys.id == rhs.sys.id
	}
	
	enum FieldKeys: String, CodingKey {
		case title
		case introduction
		case conclusion
		case portals = "cpPortals"
		case storyColor
	}

	static let contentTypeId: String = "cpStory"

	public let sys: Sys
	public let title: String?
	public var introduction: NarrativeContent?
	public var conclusion: NarrativeContent?
	public var portals: [CFPortal]?
	public let colorString: String?

	public required init(from decoder: Decoder) throws {
		sys = try decoder.sys()

		let fields = try decoder.contentfulFieldsContainer(keyedBy: CFStory.FieldKeys.self)

		title = try fields.decodeIfPresent(String.self, forKey: .title)
		colorString = try fields.decodeIfPresent(String.self, forKey: .storyColor)

		try fields.resolveLink(forKey: .introduction, decoder: decoder) { [weak self] introduction in
			self?.introduction = introduction as? NarrativeContent
		}
		try fields.resolveLink(forKey: .conclusion, decoder: decoder) { [weak self] conclusion in
			self?.conclusion = conclusion as? NarrativeContent
		}
		try fields.resolveLinksArray(forKey: .portals, decoder: decoder) { [weak self] portals in
			self?.portals = portals as? [CFPortal]
		}
	}
}

extension CFStory {
	enum StoryColor: String {
		case yellow, pink, red, brown, ochre, cyan
		case champagne
	}

	var color: UIColor {
		return UIColor.storyColor[StoryColor(rawValue: colorString ?? "champagne") ?? .champagne] ?? UIColor.champagneBranded
	}
}
