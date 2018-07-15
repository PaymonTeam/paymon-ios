//
// Created by Vladislav on 31/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

class StickerPack {
    var id:Int32
    var title:String!
    var author:String!
    var stickers:[Int64:Sticker] = [:]

    public class Sticker {
        var image:UIImage!
        var id:Int64!
    }

    public init(id:Int32) {
        self.id = id
        self.title = ""
        self.author = ""
    }

    public init(id:Int32, stickersCount:Int32, title:String, author:String) {
        self.id = id
        self.title = title
        self.author = author
    }
}