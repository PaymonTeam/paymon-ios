//
// Created by Vladislav on 31/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

protocol IPhotoListener {
    func didLoaded(photo:Photo)
    func didUpdatedPhotoID(newPhotoID:Int64, ownerID:Int32)
    func loadProgress(progress:Int32)
}

protocol IStickerListener {
    func didLoadedSticker(sticker:StickerPack.Sticker)
}

class ObservableMediaManager {
    public static let instance = ObservableMediaManager()

    private var photoObservers = SharedDictionary<Int64, SharedArray<AnyObject>>()
    private var removePhotoAfterBroadcast = SharedDictionary<Int64, SharedArray<AnyObject>>()
    private var addPhotoAfterBroadcast = SharedDictionary<Int64, SharedArray<AnyObject>>()
    private var updatedPhotoIDs = SharedDictionary<Int64, Int64>()
    private var delayedPhotoPosts = SharedArray<DelayedPhotoPost>()
    private var delayedUpdatePhotoIDPosts = SharedArray<DelayedPhotoUpdateIDPost>()
    private var photoIDsBitmaps = SharedDictionary<Int64, UIImage>()

    private var stickerObservers = SharedDictionary<Int64, SharedArray<AnyObject>>()
    private var removeStickerAfterBroadcast = SharedDictionary<Int64, SharedArray<AnyObject>>()
    private var addStickerAfterBroadcast = SharedDictionary<Int64, SharedArray<AnyObject>>()
    private var delayedStickerPosts = SharedArray<DelayedStickerPost>()
    private var stickerIDsBitmaps = SharedDictionary<Int64, UIImage>()

    private var broadcasting = 0
    private var animationInProgress = false

    public func loadPhotoBitmap(ownerID:Int32, photoID:Int64) -> UIImage? {
        let image = photoIDsBitmaps[photoID]
        if (image == nil) {
            let image = MediaManager.instance.loadPhotoBitmap(userID: ownerID, photoID: photoID)
            if (image != nil) {
                photoIDsBitmaps[photoID] = image
                return image
            } else {
                return nil
            }
        }
        return image
    }

    public func loadStickerBitmap(stickerID:Int64) -> UIImage? {
        let image = stickerIDsBitmaps[stickerID]
        if (image == nil) {
            let spid = MediaManager.instance.getStickerPackIDByStickerID(stickerID)
            if spid != 0 {
                let image = MediaManager.instance.loadStickerBitmap(stickerPackID: spid, stickerID: stickerID)
    
                if (image != nil) {
                    stickerIDsBitmaps[stickerID] = image
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        return image
    }

    private class DelayedPhotoPost {
        private var photo:Photo
    
        init(_ photo:Photo) {
            self.photo = photo
        }
    }

    private class DelayedStickerPost {
        private var sticker:StickerPack.Sticker
    
        init(_ sticker:StickerPack.Sticker) {
            self.sticker = sticker
        }
    }

    private class DelayedPhotoUpdateIDPost {
        private var oldPhotoID: Int64
        private var newPhotoID: Int64

        init(oldPhotoID: Int64, newPhotoID: Int64) {
            self.oldPhotoID = oldPhotoID
            self.newPhotoID = newPhotoID
        }
    }

//    public func setAllowedNotificationsDutingAnimation(int notifications[]) {
//        allowedNotifications = notifications
//    }

    /** !!! Изменить, если нужно сделать уведомление с задержкой */
//    public func setAnimationInProgress(boolean flag) {
//        animationInProgress = flag
//        if (!animationInProgress && !delayedPhotoPosts.isEmpty) {
//            for (DelayedPhotoPost delayedPhotoPost : delayedPhotoPosts) {
//                postPhotoNotificationInternal(true, delayedPhotoPost.photo)
//            }
//            delayedPhotoPosts.removeAll()
//        }
//    }

//    public boolean isAnimationInProgress() {
//        return animationInProgress
//    }

    public func postPhotoNotification(photo:Photo) {
        let allowDuringAnimation = false
    //        if (allowedNotifications != nil) {
    //            for (int a = 0 a < allowedNotifications.length a += 1) {
    //                if (allowedNotifications[a] == photo.getID()) {
    //                    allowDuringAnimation = true
    //                    break
    //                }
    //            }
    //        }
        postPhotoNotificationInternal(allowDuringAnimation, photo)
    }

    public func postPhotoUpdateIDNotification(oldPhotoID:Int64, newPhotoID:Int64) {
        let allowDuringAnimation = false
    //        if (allowedNotifications != nil) {
    //            for (int a = 0 a < allowedNotifications.length a += 1) {
    //                if (allowedNotifications[a] == oldPhotoID) {
    //                    allowDuringAnimation = true
    //                    break
    //                }
    //            }
    //        }
        postPhotoUpdateIDNotificationInternal(allowDuringAnimation, oldPhotoID, newPhotoID)
    }

    public func postPhotoUpdateIDNotificationInternal(_ allowDuringAnimation: Bool, _ oldPhotoID:Int64, _ newPhotoID:Int64) {
        if (User.currentUser?.photoID == oldPhotoID) {
            User.currentUser?.photoID = newPhotoID
            NotificationManager.instance.postNotificationName(id: NotificationManager.profileUpdated)
        } else {
            let groups = MessageManager.instance.groups
            for group in groups.values {
                if (group.photo.id == oldPhotoID) {
                    group.photo.id = newPhotoID
                    break
                }
            }
        }

        if (!allowDuringAnimation && animationInProgress) {
            let delayedPhotoPost = DelayedPhotoUpdateIDPost(oldPhotoID: oldPhotoID, newPhotoID: newPhotoID)
            delayedUpdatePhotoIDPosts.append(delayedPhotoPost)
            return
        }
        broadcasting += 1
        let objects = photoObservers[oldPhotoID]
        if (objects != nil && !objects!.isEmpty) {
            for obj in objects!.array {
                (obj as! IPhotoListener).didUpdatedPhotoID(newPhotoID: newPhotoID, ownerID: 0) // TODO: do it need ownerID?
            }
        }
        updatedPhotoIDs[newPhotoID] = oldPhotoID
        broadcasting -= 1
        if (broadcasting == 0) {
            updatePhotoBroadcasting()
        }
    }

    public func postPhotoNotificationInternal(_ allowDuringAnimation:Bool, _ photo:Photo) {
        if (!allowDuringAnimation && animationInProgress) {
            let delayedPhotoPost = DelayedPhotoPost(photo)
            delayedPhotoPosts.append(delayedPhotoPost)
            return
        }
        broadcasting += 1
        var photoID = photo.id
        let oldID = updatedPhotoIDs[photoID]
        if oldID != nil {
            photoID = oldID!
        }
        let objects = photoObservers[photoID]
        if objects != nil && !objects!.isEmpty {
            for obj in objects!.array {
                (obj as! IPhotoListener).didLoaded(photo: photo)
            }
        }
        broadcasting -= 1
        if (broadcasting == 0) {
            updatePhotoBroadcasting()
        }
    }

    private func updatePhotoBroadcasting() {
        if (updatedPhotoIDs.count != 0) {
            for newID in updatedPhotoIDs.keys {
                if let oldID = updatedPhotoIDs[newID] {
                    var arrayList = photoObservers[oldID]
                    if (arrayList != nil) {
                        let newArrayList = SharedArray<AnyObject>()
                        newArrayList.array = arrayList!.array
                        photoObservers.removeValue(forKey: oldID)
                        photoObservers[newID] = newArrayList
                    }
                    arrayList = removePhotoAfterBroadcast[oldID]
                    if (arrayList != nil) {
                        let newArrayList = SharedArray<AnyObject>()
                        newArrayList.array = arrayList!.array
                        removePhotoAfterBroadcast.removeValue(forKey: oldID)
                        removePhotoAfterBroadcast[newID] = newArrayList
                    }
                    arrayList = addPhotoAfterBroadcast[oldID]
                    if (arrayList != nil) {
                        let newArrayList = SharedArray<AnyObject>()
                        newArrayList.array = arrayList!.array
                        addPhotoAfterBroadcast.removeValue(forKey: oldID)
                        addPhotoAfterBroadcast[newID] = newArrayList
                    }
                }
            }
            updatedPhotoIDs.removeAll()
        }
        if (removePhotoAfterBroadcast.count != 0) {
            for key in removePhotoAfterBroadcast.keys {
                if let arrayList = removePhotoAfterBroadcast[key] {
                    for b in arrayList.array {
                        removePhotoObserver(observer: b, photoID: key)
                    }
                }
            }
            removePhotoAfterBroadcast.removeAll()
        }
        if (addPhotoAfterBroadcast.count != 0) {
            for key in addPhotoAfterBroadcast.keys {
                let arrayList = addPhotoAfterBroadcast[key]
                for b in arrayList!.array {
                    addPhotoObserver(observer: b, photoID: key)
                }
            }
            addPhotoAfterBroadcast.removeAll()
        }
    }

    public func addPhotoObserver(observer:AnyObject, photoID:Int64) {
        if (broadcasting != 0) {
            var arrayList = addPhotoAfterBroadcast[photoID]
            if (arrayList == nil) {
                arrayList = SharedArray<AnyObject>()
                addPhotoAfterBroadcast[photoID] = arrayList
            }
            arrayList!.append(observer)
            return
        }
        var objects:SharedArray<AnyObject>? = photoObservers[photoID]
        if (objects == nil) {
            objects = SharedArray<AnyObject>()
            photoObservers[photoID] = objects
        }
        if objects!.array.contains(where: { $0 === observer }) {
            return
        }
        objects!.append(observer)
    }
    
    public func removePhotoObserver(observer: AnyObject, photoID:Int64) {
        if (broadcasting != 0) {
            var arrayList = removePhotoAfterBroadcast[photoID]
            if (arrayList == nil) {
                arrayList = SharedArray<AnyObject>()
                removePhotoAfterBroadcast[photoID] = arrayList
            }
            arrayList!.append(observer)
            return
        }
        if let objects = photoObservers[photoID] {
            for (index, item) in objects.array.enumerated() {
                if item === observer {
                    objects.remove(at: index)
                    break
                }
            }
        }
    }
    
    public func postStickerNotification(sticker:StickerPack.Sticker) {
        let allowDuringAnimation = false
    //        if (allowedNotifications != nil) {
    //            for (int a = 0 a < allowedNotifications.length a += 1) {
    //                if (allowedNotifications[a] == photo.getID()) {
    //                    allowDuringAnimation = true
    //                    break
    //                }
    //            }
    //        }
        postStickerNotificationInternal(allowDuringAnimation, sticker)
    }
    
    public func postStickerNotificationInternal(_ allowDuringAnimation:Bool, _ sticker:StickerPack.Sticker) {
        if (!allowDuringAnimation && animationInProgress) {
            let delayedStickerPost = DelayedStickerPost(sticker)
            delayedStickerPosts.append(delayedStickerPost)
            return
        }
        broadcasting += 1
        if let stickerID = sticker.id {
            let objects = stickerObservers[stickerID]
            if (objects != nil && !objects!.isEmpty) {
                for obj in objects!.array {
                    (obj as! IStickerListener).didLoadedSticker(sticker: sticker)
                }
            }
        }

        broadcasting -= 1
        if (broadcasting == 0) {
            updateStickerBroadcasting()
        }
    }
    
    private func updateStickerBroadcasting() {
        if (removeStickerAfterBroadcast.count != 0) {
            for key in removeStickerAfterBroadcast.keys {
                if let arrayList = removeStickerAfterBroadcast[key] {
                    for b in arrayList.array {
                        removeStickerObserver(observer: b, stickerID: key)
                    }
                }
            }
            removeStickerAfterBroadcast.removeAll()
        }
        if (addStickerAfterBroadcast.count != 0) {
            for key in addStickerAfterBroadcast.keys {
                if let arrayList = addStickerAfterBroadcast[key] {
                    for b in arrayList.array {
                        addStickerObserver(observer: b, stickerID: key)
                    }
                }
            }
            addStickerAfterBroadcast.removeAll()
        }
    }
    
    public func addStickerObserver(observer:AnyObject, stickerID:Int64) {
        if (broadcasting != 0) {
            var arrayList = addStickerAfterBroadcast[stickerID]
            if (arrayList == nil) {
                arrayList = SharedArray<AnyObject>()
                addStickerAfterBroadcast[stickerID] = arrayList
            }
            arrayList!.append(observer)
            return
        }
        var objects = stickerObservers[stickerID]
        if (objects == nil) {
            objects = SharedArray<AnyObject>()
            stickerObservers[stickerID] = objects
        }
        if (objects!.array.contains(where: { $0 === observer })) {
            return
        }
        objects!.append(observer)
    }
    
    public func removeStickerObserver(observer:AnyObject, stickerID:Int64) {
        if (broadcasting != 0) {
            var arrayList = removeStickerAfterBroadcast[stickerID]
            if (arrayList == nil) {
                arrayList = SharedArray<AnyObject>()
                removeStickerAfterBroadcast[stickerID] = arrayList
            }
            arrayList!.append(observer)
            return
        }
        let objects = stickerObservers[stickerID]
        if (objects != nil) {
            for (index, item) in objects!.array.enumerated() {
                if item === observer {
                    objects!.remove(at: index)
                    break
                }
            }
        }
    }
}
