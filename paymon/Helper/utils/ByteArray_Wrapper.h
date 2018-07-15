//
// Created by Vladislav on 15/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import <Foundation/Foundation.h>

struct ByteArray;
@class ByteArray_Wrapper;

@interface ByteArray_Wrapper : NSObject {
@public
    struct ByteArray *_cppClass;
}
@property (nonatomic) uint32_t length;
@property (nonatomic) uint8_t *bytes;

- (instancetype) initWithSize:(uint32_t)size;
- (instancetype) initWithBytes:(uint8_t*) bytes size:(uint32_t)size;

@end