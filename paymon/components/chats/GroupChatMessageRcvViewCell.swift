//
//  GroupChatMessageRcvViewCell.swift
//  paymon
//
//  Created by Maxim Skorynin on 29.06.2018.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

class GroupChatMessageRcvViewCell : ChatMessageRcvViewCell {
    
    @IBOutlet weak var photo: ObservableImageView!
    @IBOutlet weak var lblName: UILabel!
    
    @IBOutlet weak var messageView: UITextView!
    
    
    override func awakeFromNib() {
        let gray = UIColor(red: 231/255, green: 231/255, blue: 231/255, alpha: 1)
        
        messageView.alignCenterVertical()
        messageView.layer.cornerRadius = 10
        messageView.backgroundColor = gray
        messageView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4 )
    }
}
