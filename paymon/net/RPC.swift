//
// Created by Vladislav on 16/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class RPC {
    public static let SVUID_ARRAY:Int32 = 1550732454;
    public static let SVUID_TRUE:Int32 = 1606318489;
    public static let SVUID_FALSE:Int32 = 1541450798;

    public static let ERROR_INTERNAL:Int32 = 0x1;
    public static let ERROR_KEY:Int32 = 0x2;
    public static let ERROR_REGISTER:Int32 = 0x3;
    public static let ERROR_AUTH:Int32 = 0x4;
    public static let ERROR_AUTH_TOKEN:Int32 = 0x5;
    public static let ERROR_ADD_FRIEND:Int32 = 0x6;
    public static let ERROR_LOAD_USERS:Int32 = 0x7;
    public static let ERROR_LOAD_CHATS_AND_MESSAGES:Int32 = 0x8;
    public static let ERROR_LOAD_CHAT_MESSAGES:Int32 = 0x9;
    public static let ERROR_UPLOAD_PHOTO:Int32 = 0xA;
    public static let ERROR_GET_WALLET_KEY:Int32 = 0xB;
    public static let ERROR_SET_WALLET_KEY:Int32 = 0xC;
    public static let ERROR_REGISTER_LOGIN_OR_PASS_OR_EMAIL_EMPTY:Int32 = 0xD;
    public static let ERROR_REGISTER_INVALID_LOGIN:Int32 = 0xE;
    public static let ERROR_REGISTER_INVALID_EMAIL:Int32 = 0xF;
    public static let ERROR_REGISTER_USER_EXISTS:Int32 = 0x10;
    public static let ERROR_GROUP_CREATE:Int32 = 0x11;
    public static let ERROR_GROUP:Int32 = 0x12;
    public static let ERROR_SPAMMING:Int32 = 0x13;
    public static let ERROR_ETH_TO_FIAT:Int32 = 0x14;
    public static let ERROR_ETH_GET_BALANCE:Int32 = 0x15;
    public static let ERROR_ETH_GET_PUBLIC_KEY:Int32 = 0x16;
    public static let ERROR_ETH_GET_TX_INFO:Int32 = 0x17;
    public static let ERROR_ETH_SEND:Int32 = 0x18;
    public static let ERROR_ETH_CREATE_WALLET:Int32 = 0x19;

    enum RPCError : Error {
        case DeserializeError
    }

    class PM_requestDHParams : Packet {
        static let svuid:Int32 = 1452151203;

        public override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_requestDHParams.svuid)
        }

        override init() {
            super.init()
        }
    }

    class PM_getStickerPack : Packet {
        static let svuid:Int32 = 1913111419;

        var id:Int32 = 0

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception);
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_getStickerPack.svuid)
            stream.write(id)
        }

        override init() {
            id = 0
        }

    }

    class PM_error : Packet {
        static let svuid:Int32 = 384728714;

        var code:Int32!
        var message:String!

        public override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            code = stream.readInt32(exception);
            message = stream.readString(exception);
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_error.svuid)
            stream.write(code)
            stream.write(message)
        }
    }

    class PM_auth : Packet {
        static let svuid:Int32 = 333030643

        var id:Int32!
        var login:String!
        var password:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            login = stream.readString(exception)
            password = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_auth.svuid)
            stream.write(id)
            stream.write(login)
            stream.write(password)
        }
    }

    class PM_exit : Packet {
        static let svuid:Int32 = 518169174

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_exit.svuid)
        }
    }

    class PM_authToken : Packet {
        static let svuid:Int32 = 359382942

        var token:Data!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            token = stream.readByteArrayNSData(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_authToken.svuid)
            stream.writeByteArrayData(token)
        }
    }

    class PM_keepAlive : Packet {
        static let svuid:Int32 = 1264656564

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_keepAlive.svuid)
        }
    }

    class PM_DHParams : Packet {
        static let svuid:Int32 = 790923294
        var p:Data!
        var g:Data!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            p = stream.readByteArrayNSData(exception)
            g = stream.readByteArrayNSData(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_DHParams.svuid)
            stream.writeByteArrayData(p)
            stream.writeByteArrayData(g)
        }
    }

    class PM_clientDHdata : Packet {
        static let svuid:Int32 = 1636198261

        var key:Data!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            key = stream.readByteArrayNSData(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_clientDHdata.svuid)
            stream.writeByteArrayData(key)
        }
    }

    class PM_serverDHdata : Packet {
        static let svuid:Int32 = 1874402433

        var key:Data!
        var keyID:Int64!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            key = stream.readByteArrayNSData(exception)
            keyID = stream.readInt64(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_serverDHdata.svuid)
            stream.writeByteArrayData(key)
            stream.write(keyID)
        }
    }

    class PM_DHresult : Packet {
        static let svuid:Int32 = 472276209

        var ok:Bool!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            ok = stream.read(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_DHresult.svuid)
            stream.write(ok)
        }
    }

    class PM_postConnectionData : Packet {
        static let svuid:Int32 = 1577010971

//        var keyID:Int64!
        var salt:Int64!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            salt = stream.readInt64(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_DHresult.svuid)
//            stream.write(keyID)
            stream.write(salt)
        }
    }

    static func writeArray(_ stream:SerializableData, sharedArray:SharedArray<Packet>) {
        stream.write(SVUID_ARRAY)
        stream.write(Int32(sharedArray.array.count))
        for p in sharedArray.array {
            p.serializeToStream(stream: stream)
        }
    }

    static func writeArray(_ stream:SerializableData, _ array:[Packet]) {
        stream.write(SVUID_ARRAY)
        stream.write(Int32(array.count))
        for p in array {
            p.serializeToStream(stream: stream)
        }
    }

    class UserObject : Packet {
        var id:Int32!
        var token:Data!
        var login:String!
        var first_name:String!
        var last_name:String!
        var patronymic:String!
        var email:String!
        var country:String!
        var city:String!
        var birthdate:String!
        var phoneNumber:Int64!
        var gender:Int32!
        var walletKey:String!
        var photoID:Int64!
        var confirmed:Bool!
        var inviteCode:String!

        static func deserialize(stream:SerializableData, constructor:Int32) throws -> UserObject {
            var result:UserObject
            switch(constructor) {
                case RPC.PM_user.svuid:
                    result = RPC.PM_user()
                case RPC.PM_userFull.svuid:
                    result = RPC.PM_userFull()
                default: throw RPCError.DeserializeError
            }
            result.readParams(stream: stream, exception: nil)
            return result
        }
    }

    class PM_user : UserObject {
        static let svuid:Int32 = 143710769

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            login = stream.readString(exception)
            first_name = stream.readString(exception)
            last_name = stream.readString(exception)
            token = stream.readByteArrayNSData(exception)
            photoID = stream.readInt64(exception)
            walletKey = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_user.svuid)
            stream.write(id)
            stream.write(login)
            stream.write(first_name)
            stream.write(last_name)
            stream.writeByteArrayData(token)
            stream.write(photoID)
            stream.write(walletKey)
        }
    }

    class PM_userFull : UserObject {
        static let svuid:Int32 = 1692387515

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            login = stream.readString(exception)
            first_name = stream.readString(exception)
            last_name = stream.readString(exception)
            patronymic = stream.readString(exception)
            email = stream.readString(exception)
            country = stream.readString(exception)
            city = stream.readString(exception)
            birthdate = stream.readString(exception)
            phoneNumber = stream.readInt64(exception)
            gender = stream.readInt32(exception)
            token = stream.readByteArrayNSData(exception)
            photoID = stream.readInt64(exception)
            walletKey = stream.readString(exception)
            confirmed = stream.read(exception)
            inviteCode = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_userFull.svuid)
            stream.write(id)
            stream.write(login)
            stream.write(first_name)
            stream.write(last_name)
            stream.write(patronymic)
            stream.write(email)
            stream.write(country)
            stream.write(city)
            stream.write(birthdate)
            stream.write(phoneNumber)
            stream.write(gender)
            stream.writeByteArrayData(token)
            stream.write(photoID)
            stream.write(walletKey)
            stream.write(confirmed)
            stream.write(inviteCode)
        }
    }

    class PM_requestPhoto : Packet {
        static let svuid:Int32 = 1129923073

        var userID:Int32!
        var id:Int64!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            userID = stream.readInt32(exception)
            id = stream.readInt64(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_requestPhoto.svuid)
            stream.write(userID)
            stream.write(id)
        }
    }

    class Peer : Packet, Equatable {
        var channel_id:Int32!
        var user_id:Int32!
        var group_id:Int32!

        static func deserialize(stream:SerializableData, constructor:Int32) throws -> Peer {
            var result:Peer
            switch(constructor) {
                case PM_peerChannel.svuid:
                    result = PM_peerChannel()
                case PM_peerUser.svuid:
                    result = PM_peerUser()
                case PM_peerGroup.svuid:
                    result = PM_peerGroup()
                default: throw RPCError.DeserializeError
            }
            result.readParams(stream: stream, exception: nil)
            return result
        }

        public static func ==(lhs: Peer, rhs: Peer) -> Bool {
            return lhs.channel_id == rhs.channel_id && lhs.user_id == rhs.user_id && lhs.group_id == rhs.group_id
        }
    }

    class PM_peerChannel : Peer {
        static let svuid:Int32 = 1202091136

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            channel_id = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_peerChannel.svuid)
            stream.write(channel_id)
        }
    }

    class PM_peerUser : Peer {
        static let svuid:Int32 = 1226888699

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            user_id = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_peerUser.svuid)
            stream.write(user_id)
        }
    }

    class PM_peerGroup : Peer {
        static let svuid:Int32 = 1778284232

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            group_id = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_peerGroup.svuid)
            stream.write(group_id)
        }
    }

    class PM_resendEmail : Packet {
        static let svuid:Int32 = 682727075

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_resendEmail.svuid)
        }
    }

    class PM_BTC_getWalletKey: Packet {
        static let svuid:Int32 = 1553345733

        var uid:Int32!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            uid = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_BTC_getWalletKey.svuid)
            stream.write(uid)
        }
    }

    /** Using for setting local wallet key or for wallet key container */
    class PM_BTC_setWalletKey: Packet {
        static let svuid:Int32 = 353327501

        var walletKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            walletKey = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_BTC_setWalletKey.svuid)
            stream.write(walletKey)
        }
    }

    class PM_ETC_getWalletKey: Packet {
        static let svuid:Int32 = 617421965

        var uid:Int32!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            uid = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETC_getWalletKey.svuid)
            stream.write(uid)
        }
    }

    class PM_ETC_setWalletKey: Packet {
        static let svuid:Int32 = 120591201

        var walletKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            walletKey = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETC_setWalletKey.svuid)
            stream.write(walletKey)
        }
    }

    class Message : Packet {
        static var MESSAGE_FLAG_UNREAD:Int32 = 0b1
        static var MESSAGE_FLAG_FROM_ID:Int32 = 0b10
        static var MESSAGE_FLAG_REPLY:Int32 = 0b100
        static var MESSAGE_FLAG_VIEWS:Int32 = 0b1000
        static var MESSAGE_FLAG_EDITED:Int32 = 0b10000

        var id:Int64!
        var from_id:Int32!
        var to_id:Peer!
        var date:Int32! = 0
        var reply_to_msg_id:Int32! = 0
        var text:String!
        var flags:Int32! = 0
        var unread:Bool! = true
        //        var entities:[MessageEntity]!
        var views:Int32! = 0
        var edit_date:Int32! = 0
        var itemType:PMFileManager.FileType!
        var itemID:Int64!

        static func deserialize(stream:SerializableData, constructor:Int32) throws -> Message {
            var result:Message
            switch(constructor) {
                case PM_message.svuid:
                    result = PM_message()
                case PM_messageItem.svuid:
                    result = PM_messageItem()
                default: throw RPCError.DeserializeError
            }
            result.readParams(stream: stream, exception: nil)
            return result
        }
    }

    class Update : Packet {
        static func deserialize(stream:SerializableData, constructor:Int32) throws -> Update {
            var result:Update
            switch(constructor) {
                case PM_updateMessageID.svuid:
                    result = PM_updateMessageID()
                default: throw RPCError.DeserializeError
            }
            result.readParams(stream: stream, exception: nil)
            return result
        }
    }

    class PM_updateMessageID : Update {
        static let svuid:Int32 = 1311594707

        var oldID:Int64!
        var newID:Int64!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            oldID = stream.readInt64(exception)
            newID = stream.readInt64(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_updateMessageID.svuid)
            stream.write(oldID)
            stream.write(newID)
        }
    }

    class PM_updatePhotoID : Update {
        static let svuid:Int32 = 1917996696

        var oldID:Int64!
        var newID:Int64!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            oldID = stream.readInt64(exception)
            newID = stream.readInt64(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_updatePhotoID.svuid)
            stream.write(oldID)
            stream.write(newID)
        }
    }

    class Group : Packet {
        static let svuid:Int32 = 1150008731

        var flags:Int32!
        var id:Int32!
        var creatorID:Int32!
        var title:String!
//        var date:Int32!
//        var users:[UserObject]!
        var users:SharedArray<RPC.UserObject>!
        var photo:PM_photo!

        static func deserialize(stream:SerializableData, constructor:Int32) throws -> Group {
            guard (Group.svuid == constructor) else {
                throw RPCError.DeserializeError
            }
            let result = Group()
            result.readParams(stream: stream, exception: nil)
            return result
        }

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            flags = stream.readInt32(exception)
            id = stream.readInt32(exception)
            creatorID = stream.readInt32(exception)
            title = stream.readString(exception)

            var magic:Int32 = stream.readInt32(exception)
            if (magic != RPC.SVUID_ARRAY) {
//                if (exception) {

                    //throw RPCError.DeserializeError
//                }
                return
            }
            let count:Int32 = stream.readInt32(exception)
//            for _ in 0..<count {
            users = SharedArray<UserObject>()
            for _ in 0..<count {
                if let object = try? UserObject.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    users.append(object)
                }
            }

            magic = stream.readInt32(exception)
            if (magic != PM_photo.svuid) {
//                if (exception) {
                    print("Error desz")
//                    throw RPCError.DeserializeError
//                }
                return
            }
            photo = try? MessageMedia.deserialize(stream: stream, constructor: magic) as! PM_photo
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(Group.svuid)
            stream.write(flags)
            stream.write(id)
            stream.write(creatorID)
            stream.write(title)
            RPC.writeArray(stream, users.array)
            photo.serializeToStream(stream: stream)
        }
    }

    class PM_group_removeParticipant : Packet {
        static let svuid:Int32 = 370161898

        var id:Int32!
        var userID:Int32!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            userID = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_group_removeParticipant.svuid)
            stream.write(id)
            stream.write(userID)
        }
    }

    class PM_group_addParticipants : Packet {
        static let svuid:Int32 = 1066060061

        var id:Int32!
        var userIDs:[Int32]!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            let magic:Int32 = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    print("Error desz")
                    //throw RPCError.DeserializeError
//                }
                return
            }
            let count:Int32 = stream.readInt32(exception)
            for _ in 0..<count {
                let uid:Int32 = stream.readInt32(exception)
//                if (exception) {
//                    return
//                }
                userIDs.append(uid)
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_group_addParticipants.svuid)
            stream.write(id)
            stream.write(SVUID_ARRAY)
            let count = Int32(userIDs.count)
            stream.write(count)
            for id in userIDs {
                stream.write(id)
            }
        }
    }

    class PM_group_setSettings : Packet {
        static let svuid:Int32 = 903771455

        var id:Int32!
        var title:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            title = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_group_setSettings.svuid)
            stream.write(id)
            stream.write(title)
        }
    }

    class PM_group_setPhoto : Packet {
        static let svuid:Int32 = 446580011

        var id:Int32!
        var photo:PM_photo!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            let magic:Int32 = stream.readInt32(exception)
            if (magic != PM_photo.svuid) {
//                if (exception) {
                    //throw Error(String.format("wrong var magic:PM_photo, got %x", magic))
                    print("Error desz")
//                }
                return
            }
            photo = try? MessageMedia.deserialize(stream: stream, constructor: magic) as! PM_photo
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_group_setPhoto.svuid)
            stream.write(id)
            photo.serializeToStream(stream: stream)
        }
    }

    class PM_chatsAndMessages : Packet {
        static let svuid:Int32 = 720223855

        var messages:[Message]! = []
        var groups:[Group]! = []
        var users:[UserObject]! = []
        var count:Int32! = 0

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            var magic:Int32 = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            count = stream.readInt32(exception)
            messages = []
            for _ in 0..<count {
                if let object = try? Message.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    messages.append(object)
                } else {
                    print("Error desz")
                    return
                }
            }
            magic = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            count = stream.readInt32(exception)
            groups = []
            for _ in 0..<count {
                if let object = try? Group.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    groups.append(object)
                } else {
                    print("Error desz")
                    return
                }
            }
            magic = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            count = stream.readInt32(exception)
            users = []
            for _ in 0..<count {
                if let object = try? UserObject.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    users.append(object)
                } else {
                    return
                }
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_chatsAndMessages.svuid)
            RPC.writeArray(stream, messages)
            RPC.writeArray(stream, groups)
            RPC.writeArray(stream, users)
        }
    }

    class PM_chatMessages: Packet {
        static let svuid:Int32 = 929127698

        var chatID:Peer!
        var messages:[Message]!
//        LinkedList<Message> messages = LinkedList<>()

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            chatID = try? Peer.deserialize(stream: stream, constructor: stream.readInt32(exception))

            let magic:Int32 = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            let count:Int32 = stream.readInt32(exception)
            messages = []
            for _ in 0..<count {
                if let object = try? Message.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    messages.append(object)
                } else {
                    return
                }
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_chatMessages.svuid)
            chatID.serializeToStream(stream: stream)
            RPC.writeArray(stream, messages)
        }
    }

    class PM_getChatMessages : Packet {
        static let svuid:Int32 = 966582132

        var chatID:Peer!
        var count:Int32!
        var offset:Int32!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            chatID = try? Peer.deserialize(stream: stream, constructor: stream.readInt32(exception))
            count = stream.readInt32(exception)
            offset = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_getChatMessages.svuid)
            chatID.serializeToStream(stream: stream)
            stream.write(count)
            stream.write(offset)
        }
    }

    class PM_setProfilePhoto : Packet {
        static let svuid:Int32 = 477263581

        var photo:PM_photo!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            let magic:Int32 = stream.readInt32(exception)
            if (magic != PM_photo.svuid) {
//                if (exception) {
                    print("Error desz")
                    //throw Error(String.format("wrong var magic:PM_photo, got %x", magic))
//                }
                return
            }
            photo = try? MessageMedia.deserialize(stream: stream, constructor: magic) as! PM_photo
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_setProfilePhoto.svuid)
            photo.serializeToStream(stream: stream)
        }
    }

    class PM_message : Message {
        static let svuid:Int32 = 1683670506

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            flags = stream.readInt32(exception)
            unread = (flags & Message.MESSAGE_FLAG_UNREAD) != 0
            id = stream.readInt64(exception)
            if ((flags & Message.MESSAGE_FLAG_FROM_ID) != 0) {
                from_id = stream.readInt32(exception)
            }
            to_id = try? Peer.deserialize(stream: stream, constructor: stream.readInt32(exception))
            if (from_id == 0) {
                if (to_id.user_id != 0) {
                    from_id = to_id.user_id
                } else {
                    from_id = -to_id.channel_id
                }
            }
            if ((flags & Message.MESSAGE_FLAG_REPLY) != 0) {
                reply_to_msg_id = stream.readInt32(exception)
            }

            date = stream.readInt32(exception)
            text = stream.readString(exception)

            if ((flags & Message.MESSAGE_FLAG_VIEWS) != 0) {
                views = stream.readInt32(exception)
            }
            if ((flags & Message.MESSAGE_FLAG_EDITED) != 0) {
                edit_date = stream.readInt32(exception)
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_message.svuid)
            let b:Bool! = unread
            flags = b ? (flags | Message.MESSAGE_FLAG_UNREAD) : (flags & (~Message.MESSAGE_FLAG_UNREAD))
            flags = flags | Message.MESSAGE_FLAG_FROM_ID
            stream.write(flags)
            stream.write(id)

            if ((flags & Message.MESSAGE_FLAG_FROM_ID) != 0) {
                stream.write(from_id)
            }
            to_id.serializeToStream(stream: stream)

            if ((flags & Message.MESSAGE_FLAG_REPLY) != 0) {
                stream.write(reply_to_msg_id)
            }
            stream.write(date)
            stream.write(text)

            if ((flags & Message.MESSAGE_FLAG_VIEWS) != 0) {
                stream.write(views)
            }
            if ((flags & Message.MESSAGE_FLAG_EDITED) != 0) {
                stream.write(edit_date)
            }
        }
    }

    class PM_messageItem : Message {
        static let svuid:Int32 = 1874618975

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            flags = stream.readInt32(exception)
            unread = (flags & Message.MESSAGE_FLAG_UNREAD) != 0
            id = stream.readInt64(exception)
            if ((flags & Message.MESSAGE_FLAG_FROM_ID) != 0) {
                from_id = stream.readInt32(exception)
            }

            do {
                to_id = try Peer.deserialize(stream: stream, constructor: stream.readInt32(exception))
            } catch {
                to_id = nil
            }

            if to_id == nil {
                print("Error PM_messageItem")
                return
            }
            if (from_id == 0) {
                if (to_id.user_id != 0) {
                    from_id = to_id.user_id
                } else {
                    from_id = -to_id.channel_id
                }
            }
            if ((flags & Message.MESSAGE_FLAG_REPLY) != 0) {
                reply_to_msg_id = stream.readInt32(exception)
            }
            date = stream.readInt32(exception)
            itemType = PMFileManager.FileType(rawValue: stream.readInt32(exception))
            itemID = stream.readInt64(exception)
            text = stream.readString(exception)

            if ((flags & Message.MESSAGE_FLAG_VIEWS) != 0) {
                views = stream.readInt32(exception)
            }
            if ((flags & Message.MESSAGE_FLAG_EDITED) != 0) {
                edit_date = stream.readInt32(exception)
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_messageItem.svuid)
            let b:Bool = unread
            flags = b ? (flags | Message.MESSAGE_FLAG_UNREAD) : (flags & (~Message.MESSAGE_FLAG_UNREAD))
            stream.write(flags)
            stream.write(id)

            if ((flags & Message.MESSAGE_FLAG_FROM_ID) != 0) {
                stream.write(from_id)
            }
            to_id.serializeToStream(stream: stream)

            if ((flags & Message.MESSAGE_FLAG_REPLY) != 0) {
                stream.write(reply_to_msg_id)
            }
            stream.write(date)

            stream.write(itemType.rawValue)
            stream.write(itemID)
            stream.write(text)

            if ((flags & Message.MESSAGE_FLAG_VIEWS) != 0) {
                stream.write(views)
            }
            if ((flags & Message.MESSAGE_FLAG_EDITED) != 0) {
                stream.write(edit_date)
            }
        }
    }

    class PM_register : Packet {
        static let svuid:Int32 = 540920824

        var login:String!
        var password:String!
        var firstName:String! = ""
        var lastName:String! = ""
        var patronymic:String! = ""
        var email:String!
        var phone:Int64! = 0
        var country:String! = ""
        var city:String! = ""
        var birthdayDate:String! = ""
        var gender:Int32! = 0
        var walletKey:String! = ""
        var walletBytes:Data! = Data(bytes: [0])
        var inviteCode:String! = ""

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            login = stream.readString(exception)
            password = stream.readString(exception)
            firstName = stream.readString(exception)
            lastName = stream.readString(exception)
            patronymic = stream.readString(exception)
            email = stream.readString(exception)
            phone = stream.readInt64(exception)
            country = stream.readString(exception)
            city = stream.readString(exception)
            birthdayDate = stream.readString(exception)
            gender = stream.readInt32(exception)
            walletKey = stream.readString(exception)
            walletBytes = stream.readByteArrayNSData(exception)
            inviteCode = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_register.svuid)
            stream.write(login)
            stream.write(password)
            stream.write(firstName)
            stream.write(lastName)
            stream.write(patronymic)
            stream.write(email)
            stream.write(phone)
            stream.write(country)
            stream.write(city)
            stream.write(birthdayDate)
            stream.write(gender)
            stream.write(walletKey)
            stream.writeByteArrayData(walletBytes)
            stream.write(inviteCode)
        }
    }

    class PM_searchContact : Packet {
        static let svuid:Int32 = 1904015974
        var query:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            query = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_searchContact.svuid)
            stream.write(query)
        }
    }

    class PM_users : Packet {
        static let svuid:Int32 = 509261291
        var users:[UserObject]! = []

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            let magic:Int32 = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            let count:Int32 = stream.readInt32(exception)
            for _ in 0..<count {
                if let object = try? UserObject.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    users.append(object)
                } else {
                    return
                }
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_users.svuid)
            RPC.writeArray(stream, users)
        }
    }

    class PM_addFriend : Packet {
        static let svuid:Int32 = 1407346220
        var uid:Int32!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            uid = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_addFriend.svuid)
            stream.write(uid)
        }
    }

    class PM_file : Packet {
        static let svuid:Int32 = 673680214

        var id:Int64!
        var partsCount:Int32!
        var totalSize:Int32!
        var type:PMFileManager.FileType!
        var name:String! = ""
//        var md5_checksum:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt64(exception)
            partsCount = stream.readInt32(exception)
            totalSize = stream.readInt32(exception)
            type = PMFileManager.FileType(rawValue: stream.readInt32(exception))
            name = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_file.svuid)
            stream.write(id)
            stream.write(partsCount)
            stream.write(totalSize)
            stream.write(type.rawValue)
            stream.write(name)
        }
    }

    class PM_filePart : Packet {
        static let svuid:Int32 = 22502919

        var fileID:Int64!
        var part:Int32!
//        SerializedBuffer bytes
        var bytes:Data!

//        Packet deserializeResponse(stream:SerializableData, var svuid:Int32, var exception:Bool) {
//            return Bool.deserialize(stream, svuid, exception)
//        }

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            fileID = stream.readInt64(exception)
            part = stream.readInt32(exception)
            bytes = stream.readByteArrayNSData(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_filePart.svuid)
            stream.write(fileID)
            stream.write(part)
            stream.writeByteArrayData(bytes)
        }
    }

    class PM_messages_getChats : Packet {
        static var svuid:Int32 = 0x6b47f94d

        var offset_date:Int32!
        var offset_id:Int32!
//        Inputvar offset_peer:Peer!
        var limit:Int32!

//        Packet deserializeResponse(stream:SerializableData, constructor:Int32, exception: inout Bool) {
//            return messages_Dialogs.deserialize(stream, constructor, exception)
//        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_messages_getChats.svuid)
            stream.write(offset_date)
            stream.write(offset_id)
//            offset_peer.serializeToStream(stream)
            stream.write(limit)
        }
    }

    class PM_photo : MessageMedia {
        static let svuid:Int32 = 1935780422

        var id:Int64!
        var access_hash:Int64!
        var user_id:Int32!
        var date:Int32!
        var caption:String!
//        GeoPovar geo:Int32!
//        var sizes:[PhotoSize]!
        var flags:Int32!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
//            flags = stream.readInt32(exception)
            user_id = stream.readInt32(exception)
            id = stream.readInt64(exception)
//            bytes = stream.readByteArrayNSData(exception)
//            if (stream.readInt32(exception) == PM_file.svuid) {
//                file = PM_file()
//                file.readParams(stream, exception)
//            } else {
//                Log.e("paymon-dbg", "error while reading PM_file")
//            }
//            access_hash = stream.readInt64(exception)
//            date = stream.readInt32(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_photo.svuid)
//            stream.write(flags)
            stream.write(user_id)
            stream.write(id)
//            file.serializeToStream(stream)
//            stream.writeByteArrayData(bytes)
//            stream.write(access_hash)
//            stream.write(date)
        }
    }

    class PM_stickerPack : Packet {
        static let svuid:Int32 = 66975105

        var id:Int32!
        var title:String!
        var size:Int32!
        var author:String!
        var stickers:[PM_sticker]!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt32(exception)
            size = stream.readInt32(exception)
            title = stream.readString(exception)
            author = stream.readString(exception)

            let magic:Int32 = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            let count:Int32 = stream.readInt32(exception)
            stickers = []
            for _ in 0..<count {
                if let object = try? MessageMedia.deserialize(stream: stream, constructor: stream.readInt32(exception)) {
                    stickers.append(object as! PM_sticker)
                } else {
                    print("Error desz")
                    return
                }
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_stickerPack.svuid)
            stream.write(id)
            stream.write(size)
            stream.write(title)
            stream.write(author)
            RPC.writeArray(stream, stickers)
        }
    }

    class PM_sticker : MessageMedia {
        static let svuid:Int32 = 603143999

        var id:Int64!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            id = stream.readInt64(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_sticker.svuid)
            stream.write(id)
        }
    }

    class PM_postReferal : Packet {
        static let svuid:Int32 = 581538205

        var code:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            code = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_postReferal.svuid)
            stream.write(code)
        }
    }

    class MessageMedia : Packet {
//        var bytes:Data!
        var file:PM_file!
//        Audio audio_unused
//        var photo:PM_photo!
//        var title:String!
//        var caption:String!
        static func deserialize(stream:SerializableData, constructor:Int32) throws -> MessageMedia {
            var result:MessageMedia
            switch(constructor) {
                case PM_photo.svuid:
                    result = PM_photo()
                case PM_sticker.svuid:
                    result = PM_sticker()
                default: throw RPCError.DeserializeError
            }
            result.readParams(stream: stream, exception: nil)
            return result
        }
    }

    class PM_Bool : Packet {
        static func deserialize(stream:SerializableData, constructor:Int32) throws -> PM_Bool {
            var result:PM_Bool
            switch(constructor) {
                case SVUID_TRUE:
                    result = PM_boolTrue()
                case SVUID_FALSE:
                    result = PM_boolFalse()
                default: throw RPCError.DeserializeError
            }
            result.readParams(stream: stream, exception: nil)
            return result
        }
    }

    class PM_boolTrue : PM_Bool {
        static let svuid:Int32 = RPC.SVUID_TRUE

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_boolTrue.svuid)
        }
    }

    class PM_boolFalse : PM_Bool {
        static let svuid:Int32 = RPC.SVUID_FALSE

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_boolFalse.svuid)
        }
    }

    class PM_createGroup : Packet {
        static let svuid:Int32 = 179109192

        var title:String!
        var userIDs:[Int32]!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            title = stream.readString(exception)

            let magic:Int32 = stream.readInt32(exception)
            if (magic != SVUID_ARRAY) {
//                if (exception) {
                    //throw RPCError.DeserializeError
                    print("Error desz")
//                }
                return
            }
            let count:Int32 = stream.readInt32(exception)
            for _ in 0..<count {
                let uid:Int32 = stream.readInt32(exception)
//                if (exception) {
//                    return
//                }
                userIDs.append(uid)
            }
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_createGroup.svuid)
            stream.write(title)
            stream.write(SVUID_ARRAY)
            let count:Int32 = Int32(userIDs.count)
            stream.write(count)
            for id in userIDs {
                stream.write(id)
            }
        }
    }

    class PM_ETH_getTxInfo : Packet {
        static let svuid:Int32 = 2121624423

        var hash:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            hash = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_getTxInfo.svuid)
            stream.write(hash)
        }
    }

    class PM_ETH_txInfo : Packet {
        static let svuid:Int32 = 514255593

        var hash:String!
        var from:String!
        var to:String!
        var time:Int64!
        var amount:String!
        var fee:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            hash = stream.readString(exception)
            from = stream.readString(exception)
            to = stream.readString(exception)
            time = stream.readInt64(exception)
            amount = stream.readString(exception)
            fee = stream.readString(exception)
        }

        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_txInfo.svuid)
            stream.write(hash)
            stream.write(from)
            stream.write(to)
            stream.write(time)
            stream.write(amount)
            stream.write(fee)
        }
    }

    class PM_ETH_toFiat : Packet {
        static let svuid:Int32 = 285620428

        var prefix_:String!
        var privateKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            prefix_ = stream.readString(exception)
            privateKey = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_toFiat.svuid)
            stream.write(prefix_)
            stream.write(privateKey)
        }
    }

    class PM_ETH_fiatInfo : Packet {
        static let svuid:Int32 = 1437700991

        var amount:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            amount = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_fiatInfo.svuid)
            stream.write(amount)
        }
    }

    class PM_ETH_send : Packet {
        static let svuid:Int32 = 1278997128

        var amount:String!
        var senderPrivateKey:String!
        var receiverPrivateKey:String!
        var message:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            amount = stream.readString(exception)
            senderPrivateKey = stream.readString(exception)
            receiverPrivateKey = stream.readString(exception)
            message = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_send.svuid)
            stream.write(amount)
            stream.write(senderPrivateKey)
            stream.write(receiverPrivateKey)
            stream.write(message)
        }
    }

    class PM_ETH_sendInfo : Packet {
        static let svuid:Int32 = 108044474

        var hash:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            hash = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_sendInfo.svuid)
            stream.write(hash)
        }
    }

    class PM_ETH_getBalance : Packet {
        static let svuid:Int32 = 399562569

        var privateKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            privateKey = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_getBalance.svuid)
            stream.write(privateKey)
        }
    }

    class PM_ETH_balanceInfo : Packet {
        static let svuid:Int32 = 1261840240

        var amount:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            amount = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_balanceInfo.svuid)
            stream.write(amount)
        }
    }

    class PM_ETH_createWallet : Packet {
        static let svuid:Int32 = 2113639233

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_createWallet.svuid)
        }
    }

    class PM_ETH_walletInfo : Packet {
        static let svuid:Int32 = 522641238

        var walletKey:String!
        var privateKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            walletKey = stream.readString(exception)
            privateKey = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_walletInfo.svuid)
            stream.write(walletKey)
            stream.write(privateKey)
        }
    }

    class PM_ETH_getPublicFromPrivate : Packet {
        static let svuid:Int32 = 1267745470

        var privateKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            privateKey = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_getPublicFromPrivate.svuid)
            stream.write(privateKey)
        }
    }

    class PM_ETH_publicFromPrivateInfo : Packet {
        static let svuid:Int32 = 276868702

        var publicKey:String!

        override func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {
            publicKey = stream.readString(exception)
        }
        override func serializeToStream(stream: SerializableData) {
            stream.write(PM_ETH_publicFromPrivateInfo.svuid)
            stream.write(publicKey)
        }
    }
}
