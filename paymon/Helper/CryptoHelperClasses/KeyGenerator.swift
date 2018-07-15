//
// Created by Vladislav on 16/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class KeyGenerator {
    static let instance = KeyGenerator()
    private init() {
    }

    var sharedKey:Data? = nil
    var publicKeyBytes:Data? = nil
    var authKeyID:Int64 = 0
    var salt:Int64 = 0

    public func decryptMessageWithKeyId(_ keyID:Int64, buffer:SerializedBuffer_Wrapper!, length:UInt32, mark:UInt32) -> Bool {
        if sharedKey != nil {
            return KeyGenerator_Wrapper.getInstance().decryptMessage(withAuthKeyId: keyID, buffer: buffer, length: length, mark: mark);
        } else {
            return false;
        }
    }

    public func generatePair(_ p:Data!, _ q:Data!) -> Bool {
        return KeyGenerator_Wrapper.getInstance().generateKeyPair(p, q: q);
    }

    public func generateShared(key:Data!) -> Bool {
        let b = KeyGenerator_Wrapper.getInstance().generateShared(key)
        if (b) {
            sharedKey = KeyGenerator_Wrapper.getInstance().getSharedKey();
        }
        return b;
    }

    public func setPostConnectionData(_ pcd: RPC.PM_postConnectionData) {
        salt = pcd.salt;
    }

    public func wrapData(_ messageID:Int64, buffer: SerializedBuffer_Wrapper) -> SerializedBuffer_Wrapper? {
        return KeyGenerator_Wrapper.getInstance().wrapData(messageID, authKey: sharedKey, authKeyID: authKeyID, buffer: buffer)
    }

    public func reset() {
//        dh = null;
//        keyPairA = null;
//        keyFactory = null;
        sharedKey = nil;
        publicKeyBytes = nil;
        authKeyID = 0;
        salt = 0;
        KeyGenerator_Wrapper.getInstance().reset();
    }
}
