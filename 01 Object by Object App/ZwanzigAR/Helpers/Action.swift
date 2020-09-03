import Foundation

final class Action: NSObject {

    private let _action: () -> ()

    init(_ action: @escaping () -> ()) {
        _action = action
        super.init()
    }

    @objc func objc() {
        _action()
    }
}
