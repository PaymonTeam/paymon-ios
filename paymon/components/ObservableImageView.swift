//
// Created by Vladislav on 01/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit
import Foundation
//import QuartzCore

class ObservableImageView: UIImageView, IPhotoListener, IStickerListener {
    private var photoID:Int64
    private var photoOwnerID:Int32

    private var itemID:Int64 = 0
    private var itemType = PMFileManager.FileType.NONE

    private var bitmap:UIImage?
    public static var profilePhotoNoneUIImage:UIImage? = UIImage(named: "none_photo_user")

    var added = false

    public init() {
        photoID = Int64.min
        photoOwnerID = Int32.max
        super.init(image: nil)
        layer.cornerRadius = 0.0
        clipsToBounds = true
    }

    public override init(image: UIImage?) {
        photoID = Int64.min
        photoOwnerID = Int32.max
        super.init(image: image)
        layer.cornerRadius = frame.width / 2
        clipsToBounds = true
    }

    public required init?(coder aDecoder: NSCoder) {
        photoID = Int64.min
        photoOwnerID = Int32.max
        super.init(coder: aDecoder)
        layer.cornerRadius = frame.width / 2
        clipsToBounds = true
    }

    public func subscribe(photoID:Int64, ownerID:Int32) {
        if photoID == 0 || self.photoID == photoID || ownerID == 0 {
            return
        }
        self.photoOwnerID = ownerID

        ObservableMediaManager.instance.removePhotoObserver(observer: self, photoID: self.photoID)
        ObservableMediaManager.instance.addPhotoObserver(observer: self, photoID: photoID)
        self.photoID = photoID
    //        tryLoadUIImage()
    }

    public func subscribeItem(itemType:PMFileManager.FileType, itemID:Int64) {
        self.itemType = itemType

        if added {
            ObservableMediaManager.instance.removeStickerObserver(observer: self, stickerID: itemID)
        }
        ObservableMediaManager.instance.addStickerObserver(observer: self, stickerID: itemID)
        added = true
        self.itemID = itemID

        tryLoadSticker()
    }

    public func setPhoto(photo:RPC.PM_photo) {
        setPhoto(ownerID: photo.user_id, photoID: photo.id)
    }

    public func setPhoto(ownerID:Int32, photoID:Int64) {
        if self.photoID == photoID && self.photoOwnerID == ownerID {
            return
        } else {
            if photoID == 0 || ownerID == 0 {
                image = ObservableImageView.profilePhotoNoneUIImage
                return
            }
            subscribeProfilePhoto(ownerID: ownerID, photoID: photoID)
        }
    }

    public func setSticker(itemType:PMFileManager.FileType, itemID:Int64) {
        if self.itemID == itemID && itemType == PMFileManager.FileType.NONE {
            return
        } else {
            if itemID == 0 || itemType == PMFileManager.FileType.NONE {
                return
            }
            subscribeItem(itemType: itemType, itemID: itemID)
        }
    }

    public func subscribeProfilePhoto(ownerID:Int32, photoID:Int64) {
        self.photoOwnerID = ownerID
        if added {
            ObservableMediaManager.instance.removePhotoObserver(observer: self, photoID: self.photoID)
        }
        ObservableMediaManager.instance.addPhotoObserver(observer: self, photoID: photoID)
        added = true
        self.photoID = photoID

        tryLoadUIImage()
    }

    public func didLoadedSticker(sticker:StickerPack.Sticker) {
        bitmap = sticker.image
        image = bitmap
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    func didLoaded(photo: Photo) {
        bitmap = photo.image!
        image = bitmap
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    func didUpdatedPhotoID(newPhotoID: Int64, ownerID: Int32) {
        self.photoID = newPhotoID
        tryLoadUIImage()
    }


    public func loadProgress(progress:Int32) {

    }

    private func tryLoadUIImage() {
        if photoID <= 0 && photoOwnerID != User.currentUser!.id {
//            setImageUIImage(profilePhotoNoneUIImage)
            image = ObservableImageView.profilePhotoNoneUIImage
            return
        }
        // TODO: userID?
    //        var isProfilePhoto = (photoID == MediaManager.instance.userProfilePhotoIDs.get(User.currentUser.id))
        print("trying to load bitmap \(photoOwnerID)_\(photoID)")

        let bitmap = ObservableMediaManager.instance.loadPhotoBitmap(ownerID: photoOwnerID, photoID: photoID)
    //        var bitmap = MediaManager.instance.loadPhotoUIImage(photoOwnerID, photoID)

        if bitmap != nil {
            self.bitmap = bitmap!
            image = bitmap

        } else {
            image = ObservableImageView.profilePhotoNoneUIImage

            NetworkManager.instance.queue?.async {
                MediaManager.instance.requestPhoto(forUserID: self.photoOwnerID, photoID: self.photoID)
            }
        }

        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    private func tryLoadSticker() {
        if itemID <= 0 {
            return
        }
        print("trying to load sticker \(String(describing: itemType))_\(itemID)")

        let bitmap = ObservableMediaManager.instance.loadStickerBitmap(stickerID: itemID)
    //        var bitmap = MediaManager.instance.loadPhotoUIImage(photoOwnerID, photoID)

        if bitmap != nil {
            self.bitmap = bitmap!
            image = bitmap
        } else {
    //            if isProfilePhoto {
    //                setImageUIImage(UIImageFactory.decodeResource(getResources(), R.drawable.ic_menu_camera))
    //            } else {
            image = ObservableImageView.profilePhotoNoneUIImage

            //            }

            NetworkManager.instance.queue?.async {
                MediaManager.instance.requestStickerPack(stickerPackID: 1)
            }
        }

        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    public func destroy() {
        ObservableMediaManager.instance.removePhotoObserver(observer: self, photoID: photoID)
        added = false
    }
}
