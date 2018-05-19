//
// Created by Vladislav on 20/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

public protocol NotificationManagerListener {
    func didReceivedNotification(_ id:Int, _ args:[Any])
}
class NotificationManager {
    public static let instance = NotificationManager()
    private static var totalEvents = 1

    public static var userAuthorized:Int!
    public static var didReceivedNewMessages:Int!
    public static var updateInterfaces:Int!
    public static var dialogsNeedReload:Int!
    public static var chatAddMessages:Int!
    public static var messagesDeleted:Int!
    public static var messagesIDdidupdated:Int!
    public static var messagesRead:Int!
    public static var messagesDidLoaded:Int!
    public static var draftMessagesDidLoaded:Int!
    public static var messageReceivedByServer:Int!
    public static var messageSendError:Int!
    public static var chatDidCreated:Int!
    public static var chatDidFailCreate:Int!
    public static var chatInfoDidLoaded:Int!
    public static var chatInfoCantLoad:Int!
    public static var removeAllMessagesFromDialog:Int!
    public static var didReceivedContactsSearchResult:Int!
    public static var userDidLoggedIn:Int!
    public static var mediaLoaded:Int!
    public static var profileUpdated:Int!
    public static var photoUpdated:Int!
    public static var prostocashApiKeyUpdated:Int!
    public static var screenStateChanged:Int!
    public static var newSessionReceived:Int!
    public static var userInfoDidLoaded:Int!
    public static var didUpdatedMessagesViews:Int!
    public static var didConnectedToServer:Int!
    public static var didEstablishedSecuredConnection:Int!
    public static var didDisconnectedFromServer:Int!
    public static var doLoadChatMessages:Int!
    public static var didLoadedStickerPack:Int!
    public static var authByTokenFailed:Int!

    private init() {
        NotificationManager.userAuthorized = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didReceivedNewMessages = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.updateInterfaces = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.dialogsNeedReload = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.chatAddMessages = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.messagesDeleted = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.messagesIDdidupdated = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.messagesRead = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.messagesDidLoaded = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.draftMessagesDidLoaded = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.messageReceivedByServer = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.messageSendError = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.chatDidCreated = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.chatDidFailCreate = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.chatInfoDidLoaded = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.chatInfoCantLoad = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.removeAllMessagesFromDialog = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didReceivedContactsSearchResult = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.userDidLoggedIn = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.mediaLoaded = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.profileUpdated = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.photoUpdated = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.prostocashApiKeyUpdated = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.screenStateChanged = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.newSessionReceived = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.userInfoDidLoaded = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didUpdatedMessagesViews = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didConnectedToServer = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didEstablishedSecuredConnection = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didDisconnectedFromServer = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.doLoadChatMessages = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.didLoadedStickerPack = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
        NotificationManager.authByTokenFailed = NotificationManager.totalEvents; NotificationManager.totalEvents += 1
    }

//    private SparseArray<ArrayList<Object>> observers = new SparseArray<>()
//    private SparseArray<ArrayList<Object>> removeAfterBroadcast = new SparseArray<>()
//    private SparseArray<ArrayList<Object>> addAfterBroadcast = new SparseArray<>()
//    private ArrayList<DelayedPost> delayedPosts = new ArrayList<>(10)
    private var observers:[Int:[AnyObject?]] = [:]
    private var removeAfterBroadcast:[Int:[AnyObject?]] = [:]
    private var addAfterBroadcast:[Int:[AnyObject?]] = [:]
    private var delayedPosts:[DelayedPost?] = []

    private var broadcasting = 0
    private var animationInProgress = false

    private var allowedNotifications:[Int] = []

    private class DelayedPost {
        init(_ id:Int, _ args:[Any]) {
            self.id = id
            self.args = args
        }

        var id:Int
        var args:[Any]
    }

    public func setAllowedNotificationsDutingAnimation(_ notifications:[Int]) {
        allowedNotifications = notifications
    }

    public func setAnimationInProgress(_ flag:Bool) {
        animationInProgress = flag

        if (!animationInProgress && !delayedPosts.isEmpty) {
            for delayedPost in delayedPosts {
                if delayedPost != nil {
//                    postNotificationNameInternal(delayedPost!.id, true, delayedPost!.args)
                }
            }
            delayedPosts.removeAll()
        }
    }

    public func isAnimationInProgress() -> Bool {
        return animationInProgress
    }

    public func postNotificationName(id:Int, args:Any...) {
        var allowDuringAnimation = false
        if !allowedNotifications.isEmpty {
            for allowedNotification in allowedNotifications {
                if allowedNotification == id {
                    allowDuringAnimation = true
                    break
                }
            }
        }
        postNotificationNameInternal(id, allowDuringAnimation, args)
    }

    public func postNotificationNameInternal(_ id:Int, _ allowDuringAnimation:Bool, _ args:[Any]) {
        if (!allowDuringAnimation && animationInProgress) {
            let delayedPost = DelayedPost(id, args)
            delayedPosts.append(delayedPost)
            return
        }
        broadcasting += 1
        let objects = observers[id]
        if (objects != nil && !objects!.isEmpty) {
            for obj in objects! {
                (obj as! NotificationManagerListener).didReceivedNotification(id, args)
            }
        }
        broadcasting -= 1
        if broadcasting == 0 {
            if (!removeAfterBroadcast.isEmpty) {
//                for let (k, toRemove) as (Int:[AnyObject?]) in removeAfterBroadcast.enumerated() {
//                    for o in toRemove {
//                        removeObserver(Object: o, id: k)
//                    }
//                }
//                for (k,v) in removeAfterBroadcast.enumerated() {
//                    let el = v as [AnyObject?]
//
//                }
                for k in removeAfterBroadcast.keys {
                    if let arr = removeAfterBroadcast[k] {
                        for o in arr {
                            removeObserver(o, id: k)
                        }
                    }
                }
//                for (int a = 0 a < removeAfterBroadcast.count a += 1) {
//                    int key = removeAfterBroadcast.keyAt(a)
//                    ArrayList<Object> arrayList = removeAfterBroadcast.get(key)
//                    for (int b = 0 b < arrayList.count b += 1) {
//                        removeObserver(arrayList[b], key)
//                    }
//                }
                removeAfterBroadcast.removeAll()
            }
            if (addAfterBroadcast.count != 0) {
//                for (int a = 0 a < addAfterBroadcast.count a += 1) {
//                    int key = addAfterBroadcast.keyAt(a)
//                    ArrayList<Object> arrayList = addAfterBroadcast.get(key)
//                    for (int b = 0 b < arrayList.count b += 1) {
//                        addObserver(arrayList.get(b), key)
//                    }
//                }
//                for let (k, toAdd):(Int:[AnyObject?]) in addAfterBroadcast.enumerated() {
////                    for i in 0..<toAdd.count {
////                        addObserver(Object: toAdd[i], id: k)
////                    }
//                    for o in toAdd {
//                        addObserver(Object: o, id: k)
//                    }
//                }
                for k in addAfterBroadcast.keys {
                    if let arr = addAfterBroadcast[k] {
                        for o in arr {
                            addObserver(o, id: k)
                        }
                    }
                }
                addAfterBroadcast.removeAll()
            }
        }
    }

    public func addObserver(_ observer:AnyObject?, id:Int) {
        if broadcasting != 0 {
            var arr = addAfterBroadcast[id]
            if arr == nil {
                arr = []
                addAfterBroadcast[id] = arr
            }
            addAfterBroadcast[id]!.append(observer)

//            ArrayList<Object> arrayList = addAfterBroadcast.get(id)
//            if arrayList == nil {
//                arrayList = new ArrayList<>()
//                addAfterBroadcast.put(id, arrayList)
//            }
//            arrayList.add(observer)
            return
        }
        var objects = observers[id]
        if objects == nil {
            objects = []
            observers[id] = []
        }

        if objects!.contains(where: { return $0 === observer }) {
            return
        }
        observers[id]!.append(observer)
    }

    public func removeObserver(_ observer:AnyObject?, id:Int) {
        if broadcasting != 0 {
            var arrayList = removeAfterBroadcast[id]
            if arrayList == nil {
                arrayList = []
                removeAfterBroadcast[id] = []
            }
            removeAfterBroadcast[id]!.append(observer)
            return
        }

        var objects = observers[id]
        if objects != nil && objects?.count != 0 {
            for i in 0..<objects!.count {
                if objects![i] != nil && objects![i]! === observer {
                    observers[id]!.remove(at: i)
                    return
                }
            }
        }
    }
}
