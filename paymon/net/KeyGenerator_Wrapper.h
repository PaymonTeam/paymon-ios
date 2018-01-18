//
// Created by Vladislav on 17/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerializedBuffer-Wrapper.h"
#import "Defines.h"

struct KeyGenerator;
@class KeyGenerator_Wrapper;

@interface KeyGenerator_Wrapper : NSObject {
@protected
    struct KeyGenerator *_cppClass;
@public
    KeyGenerator_Wrapper* instance;
}

- (instancetype)init;

+ (instancetype) getInstance;
- (SerializedBuffer_Wrapper *) wrapData:(int64_t)messageID authKey:(NSData *)authKey authKeyID:(int64_t)authKeyID buffer:(SerializedBuffer_Wrapper *)buffer;
- (bool) decryptMessageWithAuthKeyId:(int64_t)authKeyID buffer:(SerializedBuffer_Wrapper *)buffer length:(uint32_t)length mark:(uint32_t)mark;
- (bool) generateKeyPair:(NSData*) p q:(NSData*)q;
- (bool) generateShared:(NSData*) key;
- (NSData*) getPublicKey;
- (NSData*) getSharedKey;
- (int64_t) getAuthKeyID;
- (void) reset;

@end