//
// Created by Vladislav on 15/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import "ByteArray_Wrapper.h"
#include "ByteArray.h"

@implementation ByteArray_Wrapper {

}
- (instancetype)initWithSize:(uint32_t)size {
    self = [super init];
    if (self != nil) {
        _cppClass = new ByteArray(size);
        self.length = size;
        self.bytes = _cppClass->bytes;
    }
    return self;
}

- (instancetype)initWithBytes:(uint8_t *)bytes size:(uint32_t)size {
    self = [super init];
    if (self != nil) {
        _cppClass = new ByteArray(bytes, size);
        self.length = size;
        self.bytes = _cppClass->bytes;
    }
    return self;
}

- (void)dealloc {
    if (_cppClass != nullptr) {
        delete _cppClass;
    }
}

@end