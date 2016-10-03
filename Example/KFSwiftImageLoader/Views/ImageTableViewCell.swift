//
//  Created by Kiavash Faisali on 2015-03-24.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit

final class ImageTableViewCell: UITableViewCell {
    // MARK: - Properties
    @IBOutlet weak var featuredImageView: UIImageView!

    // MARK: - View Recycling
    override func prepareForReuse() {
        self.featuredImageView.image = nil
        
        super.prepareForReuse()
    }
}
