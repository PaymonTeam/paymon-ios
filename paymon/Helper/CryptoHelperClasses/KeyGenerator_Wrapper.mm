//
// Created by Vladislav on 17/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import "KeyGenerator_Wrapper.h"
#import "KeyGenerator.h"

@implementation KeyGenerator_Wrapper {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cppClass = &KeyGenerator::getInstance();
    }

    return self;
}

+ (instancetype)getInstance {
    static KeyGenerator_Wrapper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KeyGenerator_Wrapper alloc] init];
    });
    return sharedInstance;
}

- (SerializedBuffer_Wrapper *) wrapData:(int64_t)messageID authKey:(NSData *)authKey authKeyID:(int64_t)authKeyID buffer:(SerializedBuffer_Wrapper *)buffer {
    SerializedBuffer* sb = _cppClass->wrapData(messageID, (uint8_t *) authKey.bytes, authKeyID, buffer->_cppClass);
    SerializedBuffer_Wrapper *sbw;
    if (sb != nullptr) {
        uint32_t size = sb->limit();
        sbw = [[SerializedBuffer_Wrapper alloc] initWithSize:size];
        memcpy(sbw->_cppClass->bytes(), sb->bytes(), size);
        delete sb;
        return sbw;
    }
    return nullptr;
}

- (bool) decryptMessageWithAuthKeyId:(int64_t)authKeyID buffer:(SerializedBuffer_Wrapper *)buffer length:(uint32_t)length mark:(int32_t)mark {
    return _cppClass->decryptMessage(authKeyID, buffer->_cppClass, length, mark);
}

- (bool)generateKeyPair:(NSData *)p q:(NSData *)q {
    Integer cp, cq;
    cp.Decode((const byte*) p.bytes, p.length);
    cq.Decode((const byte*) q.bytes, p.length);
    return _cppClass->generateKeyPair(cp, cq);
}

- (bool)generateShared:(NSData *)key {
    SecByteBlock sbb((const byte*) key.bytes, key.length);
    return _cppClass->generateShared(sbb);
}

- (NSData *)getPublicKey {
    SecByteBlock block = _cppClass->getPublicKeyA();
    NSData* key = [[NSData alloc] initWithBytes:block.begin() length:block.size()];
    return key;
}

- (NSData *)getSharedKey {
    SecByteBlock block = _cppClass->getSharedKey();
    NSData* key = [[NSData alloc] initWithBytes:block.begin() length:block.size()];
    return key;
}

- (int64_t)getAuthKeyID {
    return 0;
}

- (void)dealloc {
    if (_cppClass != nullptr) {
        delete _cppClass;
    }
}

- (void)reset {
    _cppClass->reset();
}

@end