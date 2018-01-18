//
// Created by Vladislav on 31/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

class Photo {
    var id:Int64
    var ownerID:Int32
    var image: UIImage?

    init(id: Int64, ownerID: Int32) {
        self.id = id
        self.ownerID = ownerID
    }

    init(id: Int64, ownerID: Int32, image: UIImage) {
        self.id = id
        self.ownerID = ownerID
        self.image = image
    }
}