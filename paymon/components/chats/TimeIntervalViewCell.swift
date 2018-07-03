//
//  TimeIntervalViewCell.swift
//  paymon
//
//  Created by Maxim Skorynin on 29.06.2018.
//  Copyright © 2018 Semen Gleym. All rights reserved.
//

import Foundation

class TimeIntervalViewCell : UITableViewCell {
    @IBOutlet weak var time: UITextView!
    
    override func awakeFromNib() {
        let gray = UIColor(red: 32/255, green: 32/255, blue: 32/255, alpha: 1)
        
        time.alignCenterVertical()
        time.layer.cornerRadius = 10
        time.backgroundColor = gray
        time.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4 )
    }
}


