//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

protocol ChatsTableViewCellDelegate {
    func textFieldInTableViewCell(didSelect cell:ChatsTableViewCell)
    func textFieldInTableViewCell(cell:ChatsTableViewCell, editingChangedInTextField newText:String)
}