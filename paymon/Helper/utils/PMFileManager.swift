//
// Created by Vladislav on 21/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

protocol IDownloadingFile {
    func onFinish()
    func onProgress(percent:Int32)
    func onError(code:Int32)
}

protocol IUploadingFile {
    func onFinish()
    func onProgress(percent:Int32)
    func onError(code:Int32)
}

class PMFileManager {
    public static let instance = PMFileManager()
    private init() {
    }

    public enum FileType: Int32 {
        case NONE = 0, PHOTO, AUDIO, DOCUMENT, STICKER, ACTION
    }
    typealias OnFinished = ()->()
    typealias OnError = (Int32)->()
    typealias OnProgress = (Int32)->()

    public class DownloadingFile {
        var buffer: SerializedBuffer_Wrapper?
//        var listener: IDownloadingFile?
        var onFinished: OnFinished?
        var onError: OnError?
        var onProgress: OnProgress?
        var partsCount: Int32!
        var currentPart: Int32 = 0
        var currentDownloaded: Int32 = 0
        var id: Int64!
        var name: String!
    }

    public class UploadingFile {
        var type: FileType!
        var state: UInt8 = 0
        var buffer: SerializedBuffer_Wrapper?
        var onFinished: OnFinished?
        var onError: OnError?
        var onProgress: OnProgress?
        var partsCount: Int32!
        var currentPart: Int32 = 0
        var currentUploaded: Int32 = 0
        var id: Int64!
        var name: String!
        var fileSize: Int32 = 0
        var uploadChunkSize: Int32 = 0
    }

    var downloadingFiles: [Int64: DownloadingFile] = [:]
    var uploadingFiles: [Int64: UploadingFile] = [:]

    public func startUploading(photo: RPC.PM_photo, onFinished:OnFinished?, onError:OnError?, onProgress:OnProgress?) {
        if uploadingFiles[photo.id] != nil {
            return
        }

        guard let photoFile = MediaManager.instance.getFile(ownerID: photo.user_id, fileID: photo.id) else {
            if onError != nil {
                onError!(1)
            }
            return
        }

        print(photoFile)

        if let data = FileManager.default.contents(atPath: photoFile) {
            let uploadingFile = UploadingFile()
            print("fileSize=\(Int32(data.count))")
            uploadingFile.fileSize = Int32(data.count) //(int) photoFile.length()
            uploadingFile.uploadChunkSize = max(32, (uploadingFile.fileSize + 1024 * 3000 - 1) / (1024 * 3000))
            if (1024 % uploadingFile.uploadChunkSize != 0) {
                var chunkSize: Int32 = 64
                while (uploadingFile.uploadChunkSize > chunkSize) {
                    chunkSize *= 2
                }
                uploadingFile.uploadChunkSize = chunkSize
            }
            uploadingFile.uploadChunkSize *= 1024
            uploadingFile.partsCount = (uploadingFile.fileSize + uploadingFile.uploadChunkSize - 1) / uploadingFile.uploadChunkSize
            uploadingFile.type = FileType.PHOTO
            uploadingFile.buffer = SerializedBuffer_Wrapper(size: UInt32(uploadingFile.fileSize)) //BuffersStorage.instance.getFreeBuffer(uploadingFile.fileSize)
            uploadingFile.buffer!.limit(UInt32(uploadingFile.fileSize))
            uploadingFile.buffer!.position(0)
            uploadingFile.buffer!.writeDataBytes(data)
            uploadingFile.buffer!.position(0)
            uploadingFile.onFinished = onFinished
            uploadingFile.onProgress = onProgress
            uploadingFile.onError = onError
            uploadingFile.currentPart = 0
            uploadingFile.currentUploaded = 0
            uploadingFile.name = "photo.jpg"
            uploadingFile.id = photo.id

            let file = RPC.PM_file()
            file.id = uploadingFile.id
            file.partsCount = uploadingFile.partsCount
            file.totalSize = uploadingFile.fileSize
            file.type = FileType.PHOTO
            print("Uploading file. parts=\(file.partsCount), size=\(file.totalSize), id=\(file.id)")

            uploadingFiles[file.id] = uploadingFile

            let _ = NetworkManager.instance.sendPacket(file) { response, error in
                if (response != nil && error == nil) {
                    if (response is RPC.PM_boolTrue) {
                        self.continueFileUpload(fileID: uploadingFile.id)
                        if let listener = uploadingFile.onProgress {
                            listener(1)
                        }
                    } else {
                        if let listener = uploadingFile.onError {
                            listener(3)
                        }
                        self.cancelFileUpload(fileID: uploadingFile.id)
                    }
                }
            }
        } else {
            if onError != nil {
                onError!(2)
            }
            return
        }
    }

    public func continueFileUpload(fileID: Int64) {
        if let uploadingFile = uploadingFiles[fileID] {

            let bytesToSendCount = min(uploadingFile.uploadChunkSize, uploadingFile.fileSize - uploadingFile.currentUploaded)
            if (bytesToSendCount <= 0) {
                cancelFileUpload(fileID: uploadingFile.id)
                return
            }
//            memcpy(ba->bytes, imgBytes + currentUploaded, bytesToSendCount)
//            byte bytes[] = byte[bytesToSendCount]
            //
//            try {
            var err: Bool = false
//            var data = NSData(cap)//Data(capacity: Int(bytesToSendCount))
            if let data = uploadingFile.buffer!.readDataBytes(UInt32(bytesToSendCount), error: &err) {
                if err {
                    print("Can't read uploading file buffer")
                    if (uploadingFile.onError != nil) {
                        uploadingFile.onError!(2)
                    }
                    cancelFileUpload(fileID: uploadingFile.id)
                    return
                }
                let filePart = RPC.PM_filePart()
                filePart.fileID = uploadingFile.id
                filePart.part = uploadingFile.currentPart
                filePart.bytes = data
                uploadingFile.currentUploaded += bytesToSendCount

                let _ = NetworkManager.instance.sendPacket(filePart) { response, error in
                    if (response != nil && error == nil) {
                        if (response is RPC.PM_boolTrue) {
                            uploadingFile.currentPart += 1
                            if (uploadingFile.currentPart == uploadingFile.partsCount || uploadingFile.currentUploaded >= uploadingFile.fileSize) {
                                uploadingFile.state = 2
                                if (uploadingFile.onFinished != nil) {
                                    uploadingFile.onFinished!()
                                }
                                self.uploadingFiles.removeValue(forKey: uploadingFile.id)
                                return
                            }
                            self.continueFileUpload(fileID: uploadingFile.id)
                        } else {
                            if (uploadingFile.onError != nil) {
                                uploadingFile.onError!(1)
                            }
                            self.cancelFileUpload(fileID: uploadingFile.id)
                        }
                    }
                }
            }
        }
    }

    public func cancelFileUpload(fileID: Int64) {
        if (uploadingFiles[fileID] == nil) {
            return
        }
        print("File upload canceled")
        uploadingFiles.removeValue(forKey: fileID)
    }

    public func acceptFileDownload(file:RPC.PM_file, messageID:Int64) {
        if (downloadingFiles[file.id] != nil) {
            return
        }

        let downloadingFile = DownloadingFile()
        print("Downloading file. parts=\(file.partsCount), size=\(file.totalSize), id=\(file.id)")
        downloadingFile.buffer = SerializedBuffer_Wrapper(size: UInt32(file.totalSize))//BuffersStorage.instance.getFreeBuffer()
        downloadingFile.onFinished = {
            print("File has downloaded")
            MediaManager.instance.saveAndUpdatePhoto(downloadingFile: downloadingFile)
        }
        downloadingFile.onError = { code in
            print("file download failed (\(code))")
        }
        downloadingFile.onProgress = { p in
            print("Progress: \(p)%")
        }
        downloadingFile.currentPart = 0
        downloadingFile.currentDownloaded = 0
        downloadingFile.partsCount = file.partsCount
        downloadingFile.name = file.name
        downloadingFile.id = file.id
        downloadingFiles[file.id] = downloadingFile

        NetworkManager.instance.sendPacket(RPC.PM_boolTrue(), onComplete: nil, messageID: messageID)
    }

    public func acceptStickerDownload(file:RPC.PM_file, messageID:Int64) {
        if (downloadingFiles[file.id] != nil) {
            return
        }

        let downloadingFile = DownloadingFile()
        print("Downloading sticker. parts=\(file.partsCount), size=\(file.totalSize), id=\(file.id)")
        downloadingFile.buffer = SerializedBuffer_Wrapper(size: UInt32(file.totalSize))//BuffersStorage.instance.getFreeBuffer(file.totalSize)

        downloadingFile.onFinished = {
            print("Sticker has downloaded")
            MediaManager.instance.saveAndUpdateSticker(downloadingFile: downloadingFile)
        }
        downloadingFile.onError = { code in
            print("Sticker download failed (\(code))")
        }
        downloadingFile.onProgress = { p in
            print("Progress: \(p)%")
        }

        downloadingFile.currentPart = 0
        downloadingFile.currentDownloaded = 0
        downloadingFile.partsCount = file.partsCount
        downloadingFile.name = file.name
        downloadingFile.id = file.id
        downloadingFiles[file.id] = downloadingFile

        NetworkManager.instance.sendPacket(RPC.PM_boolTrue(), onComplete: nil, messageID: messageID)
    }

    public func continueFileDownload(part:RPC.PM_filePart, messageID:Int64) {
        if let downloadingFile = downloadingFiles[part.fileID] {
            if (part.part == downloadingFile.currentPart) {
                downloadingFile.currentDownloaded += Int32(part.bytes.count)
                print("Downloading... \(downloadingFile.currentDownloaded)/\(downloadingFile.buffer!.limit())")
                downloadingFile.buffer!.writeDataBytes(part.bytes)
                downloadingFile.currentPart += 1
                if (downloadingFile.currentPart == downloadingFile.partsCount) {
                    if (downloadingFile.onFinished != nil) {
                        downloadingFile.onFinished!()
                    }
                    downloadingFiles.removeValue(forKey: part.fileID)
                }
                NetworkManager.instance.sendPacket(RPC.PM_boolTrue(), onComplete: nil, messageID: messageID)
            } else {
                if (downloadingFile.onError != nil) {
                    downloadingFile.onError!(1)
                    NetworkManager.instance.sendPacket(RPC.PM_boolFalse(), onComplete: nil, messageID: messageID)
                }
            }
        } else {
            NetworkManager.instance.sendPacket(RPC.PM_boolFalse(), onComplete: nil, messageID: messageID)
        }
    }
}
