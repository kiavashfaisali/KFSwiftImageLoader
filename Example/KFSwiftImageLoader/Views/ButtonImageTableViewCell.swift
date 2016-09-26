//
//  Created by Kiavash Faisali on 2015-04-16.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit

final class ButtonImageTableViewCell: UITableViewCell {
    // MARK: - Properties
    @IBOutlet weak var featuredButtonView: UIButton!
    
    // MARK: - View Recycling
    override func prepareForReuse() {
        self.featuredButtonView.setImage(nil, for: UIControlState())
        self.featuredButtonView.setBackgroundImage(nil, for: UIControlState())
        
        super.prepareForReuse()
    }
}
