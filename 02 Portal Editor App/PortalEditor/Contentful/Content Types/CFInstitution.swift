import Contentful

final class CFInstitution: EntryDecodable, FieldKeysQueryable, Equatable, Resource {

	static func == (lhs: CFInstitution, rhs: CFInstitution) -> Bool {
		lhs.id == rhs.id
	}
	
	enum FieldKeys: String, CodingKey {
		case title
		case url
		case address = "adress"
		case logo
	}

	static let contentTypeId: String = "cpInstitution"

	public let sys: Sys
	public let title: String?
	public var url: String?
	public var logo: Asset?
	
	public required init(from decoder: Decoder) throws {
		sys = try decoder.sys()

		let fields = try decoder.contentfulFieldsContainer(keyedBy: CFInstitution.FieldKeys.self)

		title = try fields.decodeIfPresent(String.self, forKey: .title)

		url = try fields.decodeIfPresent(String.self, forKey: .url)

		try fields.resolveLink(forKey: .logo, decoder: decoder) { [weak self] logo in
			self?.logo = logo as? Asset
		}
	}
}
