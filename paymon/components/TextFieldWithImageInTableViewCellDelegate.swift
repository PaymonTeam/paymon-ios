//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

protocol TextFieldWithImageInTableViewCellDelegate {
    func textFieldInTableViewCell(didSelect cell:TextFieldWithImageInTableViewCell)
    func textFieldInTableViewCell(cell:TextFieldWithImageInTableViewCell, editingChangedInTextField newText:String)
}