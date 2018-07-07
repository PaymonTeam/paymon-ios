//
// Created by Vladislav on 01/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore

class ChatMessageRcvViewCell : UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var message: UITextView!
    
    override func awakeFromNib() {
        let gray = UIColor(red: 231/255, green: 231/255, blue: 231/255, alpha: 1)
        
        message.alignCenterVertical()
        message.layer.cornerRadius = 10
        message.backgroundColor = gray
        message.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4 )
    }
}
