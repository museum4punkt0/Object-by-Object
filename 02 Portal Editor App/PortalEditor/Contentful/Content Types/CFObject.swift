import Contentful
import ARKit

final class CFObject: EntryDecodable, FieldKeysQueryable, Equatable, Resource {

	static func == (lhs: CFObject, rhs: CFObject) -> Bool {
		lhs.id == rhs.id
	}
	
	enum FieldKeys: String, CodingKey {
		case title
		case media
		case objectStory
		case institution
		case containerType
		case anchorAlignment
		case longDimension
		case fragmentation
	}

	static let contentTypeId: String = "cpObject"

	public let sys: Sys
	public let title: String?
	public var media: [Asset]?
	public var objectStory: NarrativeContent?
	public var institution: CFInstitution?
	private let containerTypeRaw: String?
	private var anchorAlignmentRaw: String?
	public let longDimension: Double?
	public let fragmentation: Int?
	
	public required init(from decoder: Decoder) throws {
		sys = try decoder.sys()

		let fields = try decoder.contentfulFieldsContainer(keyedBy: CFObject.FieldKeys.self)

		title = try fields.decodeIfPresent(String.self, forKey: .title)
		containerTypeRaw = try fields.decodeIfPresent(String.self, forKey: .containerType)
		anchorAlignmentRaw = try fields.decodeIfPresent(String.self, forKey: .anchorAlignment)
		longDimension = try fields.decodeIfPresent(Double.self, forKey: .longDimension)
		fragmentation = try fields.decodeIfPresent(Int.self, forKey: .fragmentation)
		
		try fields.resolveLinksArray(forKey: .media, decoder: decoder) { [weak self] media in
			self?.media = media as? [Asset]
		}
		try fields.resolveLink(forKey: .objectStory, decoder: decoder) { [weak self] objectStory in
			self?.objectStory = objectStory as? NarrativeContent
		}
		try fields.resolveLink(forKey: .institution, decoder: decoder) { [weak self] institution in
			self?.institution = institution as? CFInstitution
		}
	}
}

extension CFObject {
	var containerType: ContainerObjectType {
		if let containerTypeRaw = containerTypeRaw {
			return ContainerObjectType.forString(containerTypeRaw) ?? .selfContained
		}
		return .selfContained
    }

    var containerNode: SCNNode? {
        return containerType.node
    }

    var desiredAlignment: AnchorAlignment {
        return AnchorAlignment.forString(anchorAlignmentRaw) ?? .horizontal
    }

	var textContent: [CFObjectText] {
		if let objectStory = objectStory as? CFObjectText {
			return [objectStory]
		}
		return []
    }
}


enum ContainerObjectType: String, CaseIterable  {
	case selfContained
	case paper
	case pictureFrame
	case cameraOnTripod
	case gramophone
	case film
	case slideProjector
	case slideProjectorWithScreen
	
	static func forString(_ string: String) -> ContainerObjectType? {
		for type in ContainerObjectType.allCases {
			if string == type.rawValue {
				return type
			}
		}
		return nil
	}
	
	var modelName: String {
		return "container_\(self.rawValue)"
	}
	
	// is this used?
	var node: SCNReferenceNode? {
		// FIXME: Watch out to work with copies when possible; same scn-file should not be loaded twice
		guard
			let url = Bundle.main.url(forResource: modelName, withExtension: "scn", subdirectory: "art.scnassets"),
			let node = SCNReferenceNode(url: url)
			else {
				print("Error: ContainerObject node not found")
				return nil
		}
		
		return node
	}
}


enum StandardObjectType: String, CaseIterable {
	case portal
	
	var id: String {
		return self.rawValue
	}
	
	var modelName: String {
		return "object3D_\(self.rawValue)"
	}
	
	var desiredAlignment: AnchorAlignment {
		switch self {
		case .portal:
			return .horizontal
		}
	}
	
	var node: SCNReferenceNode? {
		guard
			let url = Bundle.main.url(forResource: modelName, withExtension: "scn", subdirectory: "art.scnassets"),
			let node = SCNReferenceNode(url: url)
			else {
				print("Error: ContainerObject node not found")
				return nil
		}
		
		return node
	}
}

