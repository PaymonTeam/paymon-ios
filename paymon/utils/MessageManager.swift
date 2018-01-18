//
// Created by Vladislav on 23/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class MessageManager : NotificationManagerListener {
    public static let instance = MessageManager()

    var messages = SharedDictionary<Int64,RPC.Message>()
    var lastMessages = SharedDictionary<Int32,Int64>()
    var lastGroupMessages = SharedDictionary<Int32,Int64>()
    var dialogMessages = SharedDictionary<Int32,SharedArray<RPC.Message>>()
    var groupMessages = SharedDictionary<Int32,SharedArray<RPC.Message>>()
    var users = SharedDictionary<Int32,RPC.UserObject>()
    var userContacts = SharedDictionary<Int32,RPC.UserObject>()
    var searchUsers = SharedDictionary<Int32,RPC.UserObject>()
    var groups = SharedDictionary<Int32,RPC.Group>()
    var groupsUsers = SharedDictionary<Int32,SharedArray<RPC.UserObject>>()
    var currentChatID:Int32 = 0
    static var lastMessageID = Utils.Atomic<Int64>()

    private init() {
        NotificationManager.instance.addObserver(self, id: NotificationManager.didReceivedNewMessages)
        NotificationManager.instance.addObserver(self, id: NotificationManager.doLoadChatMessages)
    }

    public static func generateMessageID() -> Int64 {
        return lastMessageID.incrementAndGet()
    }

    deinit {
        NotificationManager.instance.removeObserver(self, id: NotificationManager.didReceivedNewMessages)
        NotificationManager.instance.removeObserver(self, id: NotificationManager.doLoadChatMessages)
    }

    public func putGroup(_ group:RPC.Group) {
        if groups[group.id] != nil {
            return
        }

        let pid = group.photo.id
        if (pid == 0) {
            MediaManager.instance.groupPhotoIDs[group.id] = MediaManager.instance.generatePhotoID()
        } else {
            MediaManager.instance.groupPhotoIDs[group.id] = pid
        }

        groups[group.id] = group
        groupsUsers[group.id] = group.users
        for user in group.users.array {
            putUser(user)
        }
    }

    public func putUser(_ user:RPC.UserObject) {
        if users[user.id] != nil {
            return
        }

        users[user.id] = user
        if (user.photoID == 0) {
            MediaManager.instance.userProfilePhotoIDs[user.id] = MediaManager.instance.generatePhotoID()
        } else {
            MediaManager.instance.userProfilePhotoIDs[user.id] = user.photoID
        }
        if MessageManager.instance.dialogMessages[user.id] != nil {
            userContacts[user.id] = user
        }
    }

    public func putSearchUser(_ user: RPC.UserObject) {
        if searchUsers[user.id] != nil {
            return
        }
        searchUsers[user.id] = user
        if (user.photoID == 0) {
            MediaManager.instance.userProfilePhotoIDs[user.id] = MediaManager.instance.generatePhotoID()
        } else {
            MediaManager.instance.userProfilePhotoIDs[user.id] = user.photoID
        }
    }

    public func sortMessages(forChat: Int32) {

    }

    public func sortMessages() {
        messages.dict.sorted(by: { v0, v1 in
            return v0.value.date > v1.value.date
        })
    }

    public func putMessage(_ msg:RPC.Message, serverTime:Bool) {
        if messages[msg.id] != nil {
            return
        }

        if serverTime {
            msg.date = msg.date + Int32(TimeZone.autoupdatingCurrent.secondsFromGMT())
        }
        messages[msg.id] = msg

        let currentUser:RPC.UserObject! = User.currentUser

        var chatID:Int32

        if let to_id = msg.to_id.user_id {
            if (msg.from_id == currentUser.id) {
                chatID = to_id
            } else {
                chatID = msg.from_id
            }

            var list = dialogMessages[chatID]
            if list == nil {
                list = SharedArray<RPC.Message>()
                dialogMessages[chatID] = list
            }
            list!.append(msg)

            var ldmIndex:Int32 = 0

            if (to_id == currentUser.id && msg.from_id == currentUser.id) {
                ldmIndex = to_id
            } else {
                if (to_id == currentUser.id) {
                    ldmIndex = msg.from_id
                } else {
                    ldmIndex = to_id
                }
            }

            if lastMessages[ldmIndex] != nil {
                if !serverTime || msg.date > messages[lastMessages[ldmIndex]!]!.date {
                    lastMessages[ldmIndex] = msg.id
                }
            } else {
                lastMessages[ldmIndex] = msg.id
            }
        } else if let to_id = msg.to_id.group_id {
            chatID = to_id

            var list = groupMessages[chatID]
            if list == nil {
                list = SharedArray<RPC.Message>()
                groupMessages[chatID] = list
            }
            list!.append(msg)

            var lgmIndex:Int32 = 0

            if (to_id == currentUser.id && msg.from_id == currentUser.id) {
                lgmIndex = to_id
            } else {
                if (to_id == currentUser.id) {
                    lgmIndex = msg.from_id
                } else {
                    lgmIndex = to_id
                }
            }

            if lastGroupMessages[lgmIndex] != nil {
                if msg.date > messages[lastGroupMessages[lgmIndex]!]!.date {
                    lastGroupMessages[lgmIndex] = msg.id
                }
            } else {
                lastGroupMessages[lgmIndex] = msg.id
            }
        }
    }

    public func loadChats(_ fromCache:Bool) {
        if (fromCache) {

    //            ApplicationLoader.applicationHandler.post(Runnable() {
    //                @Override
    //                public func run() {
    //                    NotificationManager.instance.postNotificationName(NotificationManager.dialogsNeedReload)
    //                }
    //            })
        } else {
            if User.currentUser == nil {
                return
            }

            let packet = RPC.PM_chatsAndMessages()

            let _ = NetworkManager.instance.sendPacket(packet) { p, e in
                if (p == nil && e != nil) {
                    DispatchQueue.main.async {
                        NotificationManager.instance.postNotificationName(id: NotificationManager.dialogsNeedReload)
                    }
                    return
                }

                if let packet = p as? RPC.PM_chatsAndMessages {
                    for msg in packet.messages {
                        self.putMessage(msg, serverTime: true)
                    }
                    for grp in packet.groups {
                        self.putGroup(grp)
                    }
                    for usr in packet.users {
                        self.putUser(usr)
                    }

                    DispatchQueue.main.async {
                        NotificationManager.instance.postNotificationName(id: NotificationManager.dialogsNeedReload)
                    }
                }
            }
        }
    }

    public func loadMessages(chatID:Int32, count:Int32, offset:Int32, isGroup:Bool) {
        if User.currentUser == nil || chatID == 0 {
            return
        }
        let packet = RPC.PM_getChatMessages()

        if (!isGroup) {
            packet.chatID = RPC.PM_peerUser()
            packet.chatID.user_id = chatID
        } else {
            packet.chatID = RPC.PM_peerGroup()
            packet.chatID.group_id = chatID
        }
        packet.count = count
        packet.offset = offset

        NetworkManager.instance.sendPacket(packet) { p, e in
            if p == nil {
                return
            }
            if let packet = p as? RPC.PM_chatMessages {
                if (packet.messages.count == 0) {
                    return
                }

                var messagesToAdd: [Int64] = []
                for msg in packet.messages {
                    self.putMessage(msg, serverTime: true)
                    messagesToAdd.append(msg.id)
                }
                DispatchQueue.main.async {
                    NotificationManager.instance.postNotificationName(id: NotificationManager.chatAddMessages, args: messagesToAdd, true)
                }
            }
        }
    }

    func didReceivedNotification(_ id: Int, _ args: [Any]) {
        if (id == NotificationManager.didReceivedNewMessages) {
            if let messages = args[0] as? SharedArray<RPC.Message> {
                var messagesToShow:[Int64] = []



                for msg in messages.array {
                    putMessage(msg, serverTime: true)
                    var to_id = msg.to_id.user_id
                    var isGroup = false
                    if to_id == 0 {
                        isGroup = true
                        to_id = msg.to_id.group_id
                    }
                    if !isGroup {
                        if ((to_id == currentChatID && msg.from_id == User.currentUser!.id) || (to_id == User.currentUser!.id && msg.from_id == currentChatID)) {
                            messagesToShow.append(msg.id)
                        }
                    } else {
                        if (to_id == currentChatID) {
                            messagesToShow.append(msg.id)
                        }
                    }
                    //                chatAdapter.messageIDs.add(String.format(Locale.getDefault(), "%d: %s", msg.from_id, msg.text))
                }
                if (messagesToShow.count > 0) {
//                    Collections.sort(messagesToShow, Comparator<Long>() {
//                        @Override
//                        public int compare(Long o1, Long o2) {
//                            return o1.compareTo(o2)
//                        }
//                    })
                    messagesToShow.sort(by: {e1, e2 in
                        return e1 > e2
                    })
                    NotificationManager.instance.postNotificationName(id: NotificationManager.chatAddMessages, args: messagesToShow, false)
                }
            }
        } else if (id == NotificationManager.doLoadChatMessages) {
//            if (args.length > 0) {
//                int chatID = (int) args[0]

//                    loadMessages(chatID)
//            }
        }
    }

    public func updateMessageID(oldID:Int64, newID:Int64) {
        let omsg = messages[oldID]
        if let oldMessage = omsg {
            var newMessage: RPC.Message! = nil
            if (oldMessage is RPC.PM_message) {
                newMessage = RPC.PM_message()
                newMessage.text = oldMessage.text
            } else if (oldMessage is RPC.PM_messageItem) {
                newMessage = RPC.PM_messageItem()
                newMessage.itemType = oldMessage.itemType
                newMessage.itemID = oldMessage.itemID
            }
            if (newMessage != nil) {
                newMessage.id = newID
                newMessage.date = oldMessage.date
                newMessage.from_id = oldMessage.from_id
                newMessage.to_id = oldMessage.to_id
                newMessage.edit_date = oldMessage.edit_date
                newMessage.flags = oldMessage.flags
                newMessage.reply_to_msg_id = oldMessage.reply_to_msg_id
                newMessage.unread = oldMessage.unread
                newMessage.views = oldMessage.views

                putMessage(newMessage, serverTime: false)
                _ = messages.removeValue(forKey: oldID)
                if (newMessage.to_id is RPC.PM_peerUser) {
                    lastMessages[newMessage.to_id.user_id] = newMessage.id
                } else if (newMessage.to_id is RPC.PM_peerGroup) {
                    lastGroupMessages[newMessage.to_id.group_id] = newMessage.id
                }
            }
        }
        if (currentChatID != 0) {
            // TODO: race condition
            DispatchQueue.main.async {
                NotificationManager.instance.postNotificationName(id: NotificationManager.messagesIDdidupdated, args: oldID, newID)
            }
        }
    }
}
