//
// Created by Vladislav on 16/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation
typealias PacketResponseFunc = (Packet?, RPC.PM_error?)->()

protocol OnResponseListener {
    func onResponse(response:Packet?, error:RPC.PM_error?)
}

class Packet {
    var disableFree = false;

    public func cachedThreadLocalObjectWithKey(_ key: String) -> SerializedBuffer_Wrapper {
        let threadDictionary = Thread.current.threadDictionary
        let cachedObject = threadDictionary[key]
        if cachedObject != nil {
            return (cachedObject as! SerializedBuffer_Wrapper)
        } else {
            let newObject = SerializedBuffer_Wrapper(calculate: true)
            threadDictionary[key] = newObject
            return newObject!
        }
    }

//    optional init() {
//
//    }

    public func readParams(stream: SerializableData, exception: UnsafeMutablePointer<Bool>?) {

    }

    public func serializeToStream(stream: SerializableData) {

    }

    public func deserializeResponse(stream: SerializableData, constructor: Int32, exception: Bool) -> Packet? {
        return nil;
    }

    public func freeResources() {

    }

    public func getSize() -> UInt32 {
        let byteBuffer = cachedThreadLocalObjectWithKey("pm_packet");
        byteBuffer.rewind();
        serializeToStream(stream: cachedThreadLocalObjectWithKey("pm_packet"));
        return UInt32(byteBuffer.length());
    }
}
