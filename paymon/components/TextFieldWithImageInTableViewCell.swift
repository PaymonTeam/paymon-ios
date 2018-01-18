//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

class TextFieldWithImageInTableViewCell : UITableViewCell {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var textField: UITextField!
    @IBOutlet var hintImage: UIImageView!

    var delegate: TextFieldWithImageInTableViewCellDelegate?
    var maxLength:Int = 100

    override func awakeFromNib() {
        super.awakeFromNib()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(TextFieldWithImageInTableViewCell.didSelectCell))
        addGestureRecognizer(gesture)
        textField.delegate = self
    }

}

// MARK: - Actions

extension TextFieldWithImageInTableViewCell {

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

extension TextFieldWithImageInTableViewCell : UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.characters.count ?? 0
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        let newLength = currentCharacterCount + string.characters.count - range.length
        return newLength <= maxLength
    }
}
