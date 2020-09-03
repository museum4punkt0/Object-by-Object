import Foundation

enum AnchorAlignment: String, CaseIterable {
    case horizontal
    case vertical
    case horizontalVertical
    case horizontalVerticalIfAvailable

    static func forString(_ string: String?) -> AnchorAlignment? {
        guard let string = string else { return nil }

        for type in AnchorAlignment.allCases {
            if string == type.rawValue {
                return type
            }
        }
        return nil
    }
}
