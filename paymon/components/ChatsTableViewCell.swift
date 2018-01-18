//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

class ChatsTableViewCell : UITableViewCell {
//    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var lastMessageText: UILabel!
    @IBOutlet weak var lastMessageTime: UILabel!
    @IBOutlet weak var photo: ObservableImageView!
//    var delegate: ChatsTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(ChatsTableViewCell.didSelectCell))
//        addGestureRecognizer(gesture)
    }

}

// MARK: - Actions

//extension ChatsTableViewCell {
//    func didSelectCell() {
//        delegate?.textFieldInTableViewCell(didSelect: self)
//    }
//
//    @IBAction func textFieldValueChanged(_ sender: UITextField) {
//        if let text = sender.text {
//            delegate?.textFieldInTableViewCell(cell: self, editingChangedInTextField: text)
//        }
//    }
//}
