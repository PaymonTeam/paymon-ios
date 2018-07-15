//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

class TextFieldInTableViewCell : UITableViewCell {

    @IBOutlet var textField: UITextField!
    @IBOutlet var descriptionLabel: UILabel!

    var delegate: TextFieldInTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(TextFieldInTableViewCell.didSelectCell))
        addGestureRecognizer(gesture)
    }

}

// MARK: - Actions

extension TextFieldInTableViewCell {

    @objc func didSelectCell() {
        textField.becomeFirstResponder()
        delegate?.textFieldInTableViewCell(didSelect: self)
    }

    @IBAction func textFieldValueChanged(_ sender: UITextField) {
        if let text = sender.text {
            delegate?.textFieldInTableViewCell(cell: self, editingChangedInTextField: text)
        }
    }
}
