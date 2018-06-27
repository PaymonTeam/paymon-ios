//
// Created by Vladislav on 01/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation

class ChatMessageViewCell : UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func draw(_ rect: CGRect) {
        let blue = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1)
        let red = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        let bubbleSpace = CGRectMake(self.messageLabel.frame.minX - 7, self.messageLabel.frame.minY - 5,
                self.messageLabel.frame.width + 15, self.messageLabel.frame.height + 13)
        let bubblePath = UIBezierPath(roundedRect: bubbleSpace, cornerRadius: 10.0)

//        red.setStroke()
        blue.setFill()
        bubblePath.fill()
//        bubblePath.stroke()
    }

    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    override func prepareForReuse() {
        self.setNeedsDisplay()
        super.prepareForReuse()
    }
}
