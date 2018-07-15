//
//  SerializedBuffer-Wrapper.m
//  paymon
//
//  Created by Vladislav on 15/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#import "SerializedBuffer-Wrapper.h"
#include "SerializedBuffer.h"

@implementation SerializedBuffer_Wrapper

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _cppClass = nullptr;
    }
    return self;
}

- (instancetype)initWithSize:(uint32_t) size {
    self = [super init];
    if (self != nil) {
        _cppClass = new SerializedBuffer(size);
    }
    return self;
}

- (instancetype)initWithCalculate:(bool) calculate {
    self = [super init];
    if (self != nil) {
        _cppClass = new SerializedBuffer(calculate);
    }
    return self;
}

//- (instancetype)initWithBuffer:(SerializedBuffer *)buffer {
//    self = [super init];
//    if (self != nil) {
//        _cppClass = buffer;
//    }
//    return self;
//}


- (uint32_t)position {
    return _cppClass->position();
}

- (int)length {
    return _cppClass->length();
}

- (void)position:(uint32_t)position {
    _cppClass->position(position);
}

- (uint32_t)limit {
    return _cppClass->limit();
}

- (void)limit:(uint32_t)limit {
    _cppClass->limit(limit);
}

- (uint32_t)capacity {
    return _cppClass->capacity();
}

- (uint32_t)remaining {
    return _cppClass->remaining();
}

- (bool)hasRemaining {
    return _cppClass->hasRemaining();
}

- (void)rewind {
    _cppClass->rewind();
}

- (void)compact {
    _cppClass->compact();
}

- (void)flip {
    _cppClass->flip();
}

- (void)clear {
    _cppClass->clear();
}

- (void)skip:(uint32_t)length {
    _cppClass->skip(length);
}

- (void)clearCapacity {
    _cppClass->clearCapacity();
}

- (uint8_t *)bytes {
    return _cppClass->bytes();
}

- (void)writeInt32:(int32_t)x error:(bool *)error {
    _cppClass->writeInt32(x, error);
}

- (void)writeInt64:(int64_t)x error:(bool *)error {
    _cppClass->writeInt64(x, error);
}

- (void)writeBool:(bool)value error:(bool *)error {
    _cppClass->writeBool(value, error);
}

- (void)writeBytes:(uint8_t *)b length:(uint32_t)length error:(bool *)error {
    _cppClass->writeBytes(b, length, error);
}

- (void)writeBytes:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length error:(bool *)error {
    _cppClass->writeBytes(b, offset, length, error);
}

- (void)writeByte:(uint8_t)i error:(bool *)error {
    _cppClass->writeByte(i, error);
}

- (void)writeString:(NSString *)s error:(bool *)error {
    _cppClass->writeString(s.UTF8String, error);
}

- (void)writeByteArray:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length error:(bool *)error {
    _cppClass->writeByteArray(b, offset, length, error);
}

- (void)writeByteArray:(uint8_t *)b length:(uint32_t)length error:(bool *)error {
    _cppClass->writeByteArray(b, length, error);
}

- (void)writeByteArray:(NSData *)data error2:(bool *)error2 {
    _cppClass->writeByteArray((uint8_t *) data.bytes, data.length, error2);
}

- (void)writeByteArray:(SerializedBuffer_Wrapper *)b error:(bool *)error {
    _cppClass->writeByteArray(b->_cppClass, error);
}

- (void)writeDouble:(double)d error:(bool *)error {
    _cppClass->writeDouble(d, error);
}

- (void)writeInt32:(int)x {
    _cppClass->writeInt32(x);
}

- (void)writeInt64:(int64_t)x {
    _cppClass->writeInt64(x);
}

- (void)writeBool:(bool)value {
     _cppClass->writeBool(value);
}

- (void)writeBytes:(uint8_t *)b length:(uint32_t)length {
     _cppClass->writeBytes(b, length);
}

- (void)writeBytes:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length {
     _cppClass->writeBytes(b, offset, length);
}

- (void)writeByte:(uint8_t)i {
     _cppClass->writeByte(i);
}

- (void)writeString:(NSString *)s {
     _cppClass->writeString(s.UTF8String);
}

- (void)writeByteArray:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length {
     _cppClass->writeByteArray(b, offset, length);
}

- (void)writeByteArray:(uint8_t *)b length:(uint32_t)length {
     _cppClass->writeByteArray(b, length);
}

- (void)writeDouble:(double)d {
     _cppClass->writeDouble(d);
}

- (uint32_t)readUint32:(bool *)error {
    return _cppClass->readUint32(error);
}

- (uint64_t)readUint64:(bool *)error {
    return _cppClass->readUint64(error);
}

- (int32_t)readInt32:(bool *)error {
    return _cppClass->readInt32(error);
}

- (int32_t)readBigInt32:(bool *)error {
    return _cppClass->readBigInt32(error);
}

- (int64_t)readInt64:(bool *)error {
    return _cppClass->readInt64(error);
}

- (uint8_t)readByte:(bool *)error {
    return _cppClass->readByte(error);
}

- (bool)readBool:(bool *)error {
    return _cppClass->readBool(error);
}

- (void)readBytes:(uint8_t *)b length:(uint32_t)length error:(bool *)error {
    return _cppClass->readBytes(b, length, error);
}

- (NSString *)readString:(bool *)error {
    const std::string &string = _cppClass->readString(error);
    const char* str = string.c_str();
    return [[NSString alloc] initWithBytes:str length:string.length() encoding:NSUTF8StringEncoding];
}

- (SerializedBuffer_Wrapper *)readByteBuffer:(bool)copy error:(bool *)error {
    SerializedBuffer* sb = _cppClass->readByteBuffer(copy, error);
    uint32_t size = sb->limit();
    SerializedBuffer_Wrapper *sbw = [[SerializedBuffer_Wrapper alloc] initWithSize:size];
    memcpy(sbw->_cppClass->bytes(), sb->bytes(), size);
    if (sb != nullptr) {
        delete sb;
    }
    return sbw;
}

- (double)readDouble:(bool *)error {
    return _cppClass->readDouble(error);
}

- (void)reuse {
    _cppClass->reuse();
}

- (void)dealloc {
    if (_cppClass != nullptr) {
        delete _cppClass;
    }
}

- (void)writeBytes:(SerializedBuffer_Wrapper *)b error1:(bool *)error {
    _cppClass->writeBytes(b->_cppClass, error);
}

- (void)writeByteArray:(ByteArray_Wrapper *)b2 error1:(bool *)error {
    _cppClass->writeByteArray(b2->_cppClass, error);
}

- (void)writeBytes:(id)bytes :(SerializedBuffer_Wrapper *)b {
    _cppClass->writeBytes(b->_cppClass);
}

- (void)writeByteArray:(id)bytes :(SerializedBuffer_Wrapper *)b {
    _cppClass->writeByteArray(b->_cppClass);
}

- (void)writeByteArrayData:(NSData *)data {
    _cppClass->writeByteArray((uint8_t *) data.bytes, data.length);
}

- (ByteArray_Wrapper *)readBytes:(uint32_t)length error:(bool *)error {
    // TODO: make pointer
    ByteArray *pArray = _cppClass->readBytes(length, error);
    ByteArray_Wrapper *baw = [[ByteArray_Wrapper alloc] initWithBytes:pArray->bytes size:pArray->length];
    if (pArray != nullptr) {
        delete pArray;
    }
    return baw;
}

- (void) readDataBytes:(NSData *)data length:(uint32_t)length error:(bool *)error {
    _cppClass->readBytes((uint8_t *) data.bytes, length, error);
    NSLog(@"length=%d", data.length);
}

- (NSData*) readDataBytes:(uint32_t)length error:(bool *)error {
//    NSData* data = [[NSData alloc] initWith]
    // TODO: use native array?
    NSMutableData *data = [[NSMutableData alloc] initWithLength:length];
    _cppClass->readBytes((uint8_t *) data.bytes, length, error);
    return [[NSData alloc] initWithData:data];
}

- (ByteArray_Wrapper *)readByteArray:(bool *)error {
    // TODO: make pointer
    ByteArray *pArray = _cppClass->readByteArray(error);
    ByteArray_Wrapper *baw = [[ByteArray_Wrapper alloc] initWithBytes:pArray->bytes size:pArray->length];
    if (pArray != nullptr) {
        delete pArray;
    }
    return baw;
}

- (NSData *)readByteArrayNSData:(bool *)error {
    // TODO: make pointer
    ByteArray *pArray = _cppClass->readByteArray(error);
    NSData *data = [[NSData alloc] initWithBytes:pArray->bytes length:pArray->length];
    if (pArray != nullptr) {
        delete pArray;
    }
    return data;
}

- (void)writeBytes:(ByteArray_Wrapper *)b error:(bool *)error {
    _cppClass->writeBytes(b->_cppClass, error);
}

- (void)writeDataBytes:(NSData *)data {
    _cppClass->writeBytes((uint8_t *) data.bytes, data.length, nullptr);
}

- (void)writeBytes:(ByteArray_Wrapper *)b {
    _cppClass->writeBytes(b->_cppClass);
}

- (void)writeByteArray:(ByteArray_Wrapper *)b {
    _cppClass->writeByteArray(b->_cppClass);
}


@end


