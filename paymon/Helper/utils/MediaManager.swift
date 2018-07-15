//
// Created by Vladislav on 31/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
import UIKit

class MediaManager : NotificationManagerListener {
    public static let PHOTOS_DIR = "/Documents/photos/"
    public static let STICKERS_DIR = "/Documents/stickers/"
    public var waitingPhotosList:[Int64:RPC.PM_photo] = [:]
    public var stickerPacks:[Int64:StickerPack] = [:]
    public var userProfilePhotoIDs:[Int32:Int64] = [:]
    public var groupPhotoIDs:[Int32:Int64] = [:]
    public var waitingStickerPacks:[Int32] = []
    public var lastPhotoID = Utils.Atomic<Int64>()

    public static let instance = MediaManager()

    private init() {
        NotificationManager.instance.addObserver(self, id: NotificationManager.userAuthorized)
    }

    public func prepare() {
//        if let dir = Bundle.main.resourcePath {
//            print(dir)
//            do {
//                try FileManager.default.createDirectory(atPath: "\(dir)Documents", withIntermediateDirectories: false)
//                try FileManager.default.createDirectory(atPath: "\(dir)\(MediaManager.PHOTOS_DIR)", withIntermediateDirectories: false)
//                try FileManager.default.createDirectory(atPath: "\(dir)Documents/video", withIntermediateDirectories: false)
//                try FileManager.default.createDirectory(atPath: "\(dir)\(MediaManager.STICKERS_DIR)", withIntermediateDirectories: false)
//            } catch {
//                print("Create folders error")
//            }
//        }
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        do {
            try FileManager.default.createDirectory(at: documentsPath.appendingPathComponent("photos")!, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: documentsPath.appendingPathComponent("stickers")!, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: documentsPath.appendingPathComponent("video")!, withIntermediateDirectories: true)
        } catch let error as NSError {
            print("Unable to create directory \(error.debugDescription)")
        }
    }

    public func savePhoto(image:UIImage, user:RPC.UserObject) -> RPC.PM_photo? {
        return savePhoto(image:image, user:user, chatID:0)
    }

    public func savePhoto(image:UIImage, user:RPC.UserObject, chatID:Int32) -> RPC.PM_photo? {
//        if let path = Bundle.main.resourcePath {
            let photoID = generatePhotoID()
//            let photosPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//                    .appendingPathComponent("photos", isDirectory: true)!
//            let file = "\(photosPath)\(user.id!)_\(photoID).jpg"
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(user.id!)_\(photoID).jpg")
//            print("photos path=\(file.path)")
            do {
//                var b:ObjCBool = true
//                if !FileManager.default.fileExists(atPath: "\(path)\(MediaManager.PHOTOS_DIR)", isDirectory: &b) {
//                    try FileManager.default.createDirectory(atPath: "\(path)\(MediaManager.PHOTOS_DIR)", withIntermediateDirectories: true)
//                }
                if let jpeg = UIImageJPEGRepresentation(image, 0.9) {
                    try jpeg.write(to: URL(fileURLWithPath: file.path, isDirectory: false), options: .atomicWrite)
                } else {
                    print("ERROR 1")
                    return nil
                }
            } catch {
                print("Save photo failed")
                return nil
            }
            let photo = RPC.PM_photo()
            photo.id = photoID
            photo.user_id = user.id
            return photo
//        } else {
//            return nil
//        }
    }

    public func getFile(ownerID:Int32, fileID:Int64) -> String? {
//        if let path = Bundle.main.resourcePath {
//            let photosPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//                    .appendingPathComponent("photos", isDirectory: true)!
        let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(ownerID)_\(fileID).jpg")
//            print("getFile=\(file.path)")
            return file.path
//            return "\(path)\(MediaManager.PHOTOS_DIR)\(ownerID)_\(fileID).jpg"
//        } else {
//            return nil
//        }
    }

    public func savePhoto(downloadedFile:PMFileManager.DownloadingFile) -> RPC.PM_photo? {
        let photo = waitingPhotosList[downloadedFile.id]
        if (photo == nil) {
            return nil
        }

//        if let path = Bundle.main.resourcePath {
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(photo!.user_id!)_\(photo!.id!).jpg")
//            let file = "\(photosPath.path)/\(photo!.user_id!)_\(photo!.id!).jpg"
//            print("SAVE \(file)")
//            print("SAVE \(file.path)")
//            var file = "\(path)\(MediaManager.PHOTOS_DIR)"
//            var b:ObjCBool = true
//            do {
//                if !FileManager.default.fileExists(atPath: file, isDirectory: &b) {
//                    try FileManager.default.createDirectory(atPath: file, withIntermediateDirectories: true)
//                }
//            } catch {
//                //Toast.makeText(context, "Save photo failed", Toast.LENGTH_SHORT).show()
//                print("Err: \(error)")
//                return nil
//            }
//            file = "\(path)\(MediaManager.PHOTOS_DIR)\(photo!.user_id!)_\(photo!.id!).jpg"

//            b = false
            var b:ObjCBool = false
            do {
                if !FileManager.default.fileExists(atPath: file.path, isDirectory: &b) {
                    try FileManager.default.removeItem(atPath: file.path)
                }
            } catch {
            }
            let data = Data(bytesNoCopy: downloadedFile.buffer!.bytes(), count: Int(downloadedFile.buffer!.limit()), deallocator: .none)
            if FileManager.default.createFile(atPath: file.path, contents: data, attributes: nil) {
                return photo
            } else {
                print("ERROR 2")
                return nil
            }
//        } else {
//            return nil
//        }
    }

    public func getStickerPackIDByStickerID(_ stickerID:Int64) -> Int32 {
        for sp:StickerPack in stickerPacks.values {
            if (sp.stickers.keys.contains(where: { $0 == stickerID })) {
                return sp.id
            }
        }
        return 0
    }

    public func saveSticker(downloadedFile:PMFileManager.DownloadingFile) -> StickerPack.Sticker? {
        let stickerID = downloadedFile.id
        let stickerPackID = getStickerPackIDByStickerID(stickerID!)
        if stickerPackID == 0 {
            return nil
        }
        let sp = stickerPacks[Int64(stickerPackID)]
        if sp == nil {
            return nil
        }
        let sticker = sp!.stickers[Int64(stickerID!)]
        if (sticker == nil) {
            return nil
        }

        if let path = Bundle.main.resourcePath {
//            let stickersPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//                    .appendingPathComponent("stickers", isDirectory: true)!
//            let file = "\(stickersPath)\(stickerPackID)_\(stickerID!).jpg"
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("stickers", isDirectory: true)!.appendingPathComponent("\(stickerPackID)_\(stickerID!).jpg")

//            var file = "\(path)\(MediaManager.STICKERS_DIR)\(stickerPackID)/"
            var b:ObjCBool = true
//            if !FileManager.default.fileExists(atPath: file, isDirectory: &b) {
//                do {
//                    try FileManager.default.createDirectory(atPath: file, withIntermediateDirectories: true)
//                } catch {
//                    //Toast.makeText(context, "Save photo failed", Toast.LENGTH_SHORT).show()
//                    return nil
//                }
//            }
//            file = "\(path)\(MediaManager.STICKERS_DIR)\(stickerPackID)/\(stickerID!).jpg"

            b = false
            if !FileManager.default.fileExists(atPath: file.path, isDirectory: &b) {
                do {
                    try FileManager.default.removeItem(atPath: file.path)
                } catch {
                    //Toast.makeText(context, "Save photo failed", Toast.LENGTH_SHORT).show()
                }
            }
            let data = Data(bytesNoCopy: downloadedFile.buffer!.bytes(), count: Int(downloadedFile.buffer!.limit()), deallocator: .none)
            FileManager.default.createFile(atPath: file.path, contents: data, attributes: nil)
            return sticker
        } else {
            return nil
        }
    }

    public func updatePhotoID(oldID:Int64, newID:Int64) {
//        String path = Environment.getExternalStorageDirectory().toString()
//        File fileSrc = File(path + PHOTOS_DIR, User.currentUser.id + "_" + oldID + ".jpg")
//        if (!fileSrc.exists()) {
//            return
//        }
//        File fileDst = File(path + PHOTOS_DIR, User.currentUser.id + "_" + newID + ".jpg")
//
//        fileSrc.renameTo(fileDst)
//        if let path = Bundle.main.resourcePath {
//            let file = "\(path)\(MediaManager.PHOTOS_DIR)\(User.currentUser!.id)/\(oldID).jpg"

            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(User.currentUser!.id!)_\(oldID).jpg")
            do {
                var b:ObjCBool = false
                if FileManager.default.fileExists(atPath: file.path, isDirectory: &b) {
//                    let newFile = "\(path)\(MediaManager.PHOTOS_DIR)\(User.currentUser!.id)/\(newID).jpg"
                    let newFile = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                            .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(User.currentUser!.id!)_\(newID).jpg")
                    try FileManager.default.replaceItem(at: URL(fileURLWithPath: newFile.path, isDirectory: false), withItemAt: URL(fileURLWithPath: file.path, isDirectory: false), backupItemName: nil, options: .usingNewMetadataOnly, resultingItemURL: nil)
                }
            } catch {
                print("\(error)")
                return
            }
            return
//        }
    }

    public func generatePhotoID() -> Int64 {
        return lastPhotoID.decrementAndGet()
    }

    public func checkPhotoExists(forUserID userID:Int32, photoID:Int64) -> Bool {
//        if let path = Bundle.main.resourcePath {
//            let photosPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//                    .appendingPathComponent("photos", isDirectory: true)!
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(userID)_\(photoID).jpg")
//            let file = "\(photosPath)\(userID)_\(photoID).jpg"
//            print("check=\(file.path)")
//            let file = "\(path)\(MediaManager.PHOTOS_DIR)\(userID)_\(photoID).jpg"
            var b:ObjCBool = false
            return FileManager.default.fileExists(atPath: file.path, isDirectory: &b)
//        } else {
//            return false
//        }
    }

    public func checkStickerPackExists(id:Int32) -> Bool {
//        if let path = Bundle.main.resourcePath {
//            let file = "\(path)\(MediaManager.STICKERS_DIR)\(id)"
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("stickers", isDirectory: true)!.appendingPathComponent("\(id)", isDirectory: true)
            var b:ObjCBool = true
            return FileManager.default.fileExists(atPath: file.path, isDirectory: &b)
//        } else {
//            return false
//        }
    }

    public func requestPhoto(forUserID userID:Int32, photoID:Int64) -> Bool {
        if waitingPhotosList[photoID] != nil {
            return false
        }

        let photo = RPC.PM_photo()
        photo.id = photoID
        photo.user_id = userID
        waitingPhotosList[photoID] = photo

        if User.isAuthenticated {
            let request = RPC.PM_requestPhoto()
            request.id = photoID
            request.userID = userID

            NetworkManager.instance.sendPacket(request) { response, error in
                if (response != nil) {
                    if (response is RPC.PM_boolFalse) {
                        self.waitingPhotosList.removeValue(forKey: photoID)
                    }
                }
            }
        }
        return true
    }

    public func requestStickerPack(stickerPackID:Int32) -> Bool {
        if (waitingStickerPacks.contains(where: { $0 == stickerPackID }) || checkStickerPackExists(id: stickerPackID)) {
            return false
        }

        let request = RPC.PM_getStickerPack()
        request.id = stickerPackID
        NetworkManager.instance.sendPacket(request) { response, error in
            if response != nil {
                if let stickerPackResponse = response as? RPC.PM_stickerPack {
                    let stickerPack = StickerPack(id: stickerPackResponse.id, stickersCount: stickerPackResponse.size, title: stickerPackResponse.title, author: stickerPackResponse.author)
                    for s:RPC.PM_sticker in stickerPackResponse.stickers {
                        let sticker = StickerPack.Sticker()
                        sticker.id = s.id
                        stickerPack.stickers[s.id] = sticker
                    }
                    self.stickerPacks[Int64(stickerPackResponse.id)] = stickerPack

                    DispatchQueue.main.async {
                        NotificationManager.instance.postNotificationName(id: NotificationManager.didLoadedStickerPack, args: stickerPackID)
                    }
                }
            }
        }
        waitingStickerPacks.append(stickerPackID)
        return true
    }

    public func loadStickerPack(spid:Int32) -> StickerPack? {
        if checkStickerPackExists(id: spid) {
            var sp = stickerPacks[Int64(spid)]
            if (sp != nil) {
                return sp
            }

            sp = StickerPack(id: spid, stickersCount: 14, title: "Playman", author: "Sergey Pomelov")
            var id:Int64 = 1
            while let image = loadStickerBitmap(stickerPackID: spid, stickerID: id) {
                let sticker = StickerPack.Sticker()
                sticker.image = image
                sticker.id = id
                sp!.stickers[id] = sticker
                id += 1
            }
            stickerPacks[Int64(spid)] = sp

            return sp
        } else {
            requestStickerPack(stickerPackID: spid)
            return nil
        }
    }

    public func saveAndUpdatePhoto(downloadingFile:PMFileManager.DownloadingFile) {
        let photo = savePhoto(downloadedFile: downloadingFile)
        if let photo = photo {
            let image = loadPhotoBitmap(userID: photo.user_id, photoID: photo.id)
            if (image != nil) {
                let newPhoto = Photo(id: photo.id, ownerID: photo.user_id, image: image!)
                DispatchQueue.main.async {
                    ObservableMediaManager.instance.postPhotoNotification(photo: newPhoto)
                }
            }
        }
    }

    public func saveAndUpdateSticker(downloadingFile:PMFileManager.DownloadingFile) {
        let sticker = saveSticker(downloadedFile: downloadingFile)
        if sticker != nil {
            let image = loadStickerBitmap(stickerPackID: getStickerPackIDByStickerID(sticker!.id), stickerID: sticker!.id)
            if image != nil {
                sticker!.image = image
                DispatchQueue.main.async {
                    ObservableMediaManager.instance.postStickerNotification(sticker: sticker!)
                }
            } else {
                print("nil 2")
            }
        } else {
            print("nil 1")
        }
    }

    public func loadPhotoBitmap(userID:Int32, photoID:Int64) -> UIImage? {
        //"/Users/negi/Library/Developer/CoreSimulator/Devices/EEA21C46-54EE-4396-8ABD-32672CC1CC47/data/Containers/Bundle/Application/1430B4B9-3FA5-4D11-93C1-04EF530B5D4A/paymon.app/Documents/photos/4_53.jpg"
//        if let path = Bundle.main.resourcePath {
//            let photosPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//                    .appendingPathComponent("photos", isDirectory: true)!
//            let file = "\(photosPath)\(userID)_\(photoID).jpg"
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("photos", isDirectory: true)!.appendingPathComponent("\(userID)_\(photoID).jpg")

//            print("load=\(file.path)")
//            let file = "\(path)\(MediaManager.PHOTOS_DIR)\(userID)_\(photoID).jpg"
            var b:ObjCBool = false
            if !FileManager.default.fileExists(atPath: file.path, isDirectory: &b) {
                print("doesn't exist")
                return nil
            }
            let image = UIImage(contentsOfFile: file.path)
            return image
//        } else {
//            return nil
//        }
    }

    public func loadStickerBitmap(stickerPackID:Int32, stickerID:Int64) -> UIImage? {
//        if let path = Bundle.main.resourcePath {
//            let file = "\(path)\(MediaManager.STICKERS_DIR)\(stickerPackID)/\(stickerID).jpg"
            let file = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
                    .appendingPathComponent("stickers", isDirectory: true)!.appendingPathComponent("\(stickerPackID)_\(stickerID).jpg")
            var b:ObjCBool = false
            if !FileManager.default.fileExists(atPath: file.path, isDirectory: &b) {
                return nil
            }
            return UIImage(contentsOfFile: file.path)
//        } else {
//            return nil
//        }
    }

    public func processPhotoRequest() {
        if (waitingPhotosList.count == 0) {
            return
        }
        let key = Int64(waitingPhotosList.count - 1)
        if let photo = waitingPhotosList[key] {
            let request = RPC.PM_requestPhoto()
            let photoID = photo.id
            request.id = photoID
            request.userID = photo.user_id

            NetworkManager.instance.sendPacket(request) { response, error in
                if (response != nil) {
                    if (response is RPC.PM_boolFalse) {
                        self.waitingPhotosList.removeValue(forKey: photoID!)
                    }
                    self.processPhotoRequest()
                }
            }

            waitingPhotosList.removeValue(forKey: key)
        }
    }

//    deinit() {
//        NotificationManager.instance.removeObserver(self, id: NotificationManager.userAuthorized)
//    }

    func didReceivedNotification(_ id: Int, _ args: [Any]) {
        if (id == NotificationManager.userAuthorized) {
            processPhotoRequest()
        }
    }
}
