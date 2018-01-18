//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

protocol TextFieldInTableViewCellDelegate {
    func textFieldInTableViewCell(didSelect cell:TextFieldInTableViewCell)
    func textFieldInTableViewCell(cell:TextFieldInTableViewCell, editingChangedInTextField newText:String)
}