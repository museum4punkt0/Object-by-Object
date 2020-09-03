import Contentful

class CFObjectText: EntryDecodable, FieldKeysQueryable, Resource, NarrativeContent, NarrativeAtom {

	enum FieldKeys: String, CodingKey {
		case text
	}

	static let contentTypeId: String = "objectText"

	public let sys: Sys
	public let text: String

	public required init(from decoder: Decoder) throws {
		sys = try decoder.sys()

		let fields = try decoder.contentfulFieldsContainer(keyedBy: CFObjectText.FieldKeys.self)

		text = try fields.decode(String.self, forKey: .text)
	}
}
