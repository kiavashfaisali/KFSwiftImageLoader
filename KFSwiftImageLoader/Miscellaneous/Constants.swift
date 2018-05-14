//
//  Created by Kiavash Faisali on 10/2/16.
//

import Foundation

// MARK: - Holder Structs
internal struct CompletionHolder {
    var completion: ((_ finished: Bool, _ error: NSError?) -> Void)?
}

internal struct ControlStateHolder {
    var controlState: UIControlState
}
