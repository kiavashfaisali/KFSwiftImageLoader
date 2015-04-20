//
//  Created by Kiavash Faisali on 2015-04-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import WatchKit
import KFSwiftImageLoader

final class TableImageInterfaceController: WKInterfaceController {
    // MARK: - Properties
    @IBOutlet weak var table: WKInterfaceTable!
    
    var imageURLStringsArray: [String]!
    
    // MARK: - Setup and Teardown
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let imageURLStringsArray = context as? [String] where imageURLStringsArray.count > 0 {
            self.imageURLStringsArray = imageURLStringsArray
            self.table.setNumberOfRows(self.imageURLStringsArray.count, withRowType: "ImageRowType")
            
            for i in 0..<self.imageURLStringsArray.count {
                let imageRowType = self.table.rowControllerAtIndex(i) as! ImageRowType
                let urlString = self.imageURLStringsArray[i]
                imageRowType.image.loadImageFromURLString(urlString, placeholderImageName: "KiavashFaisali", shouldUseDeviceCache: true, completion: nil)
            }
        }
    }

    // MARK: - View Lifecycle
    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}
