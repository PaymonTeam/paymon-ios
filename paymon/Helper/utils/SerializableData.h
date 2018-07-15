//
// Created by Vladislav on 28/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import <Foundation/Foundation.h>

//@class ByteArray_Wrapper;
@class SerializedBuffer_Wrapper;
@class SerializableData;

@interface SerializableData : NSObject
- (void) writeInt32:(int32_t)x error:(bool *)error;
- (void) writeInt64:(int64_t)x error:(bool *)error;
- (void) writeBool:(bool)value error:(bool *)error;
- (void) writeBytes:(uint8_t *)b length:(uint32_t)length error:(bool *)error;
- (void) writeBytes:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length error:(bool *)error;
- (void) writeBytes:(SerializedBuffer_Wrapper *)b error1:(bool *)error;
- (void) writeByte:(uint8_t)i error:(bool *)error;
- (void) writeString:(NSString *)s error:(bool *)error;
- (void) writeByteArray:(NSData *)data error2:(bool *)error2;
- (void) writeByteArray:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length error:(bool *)error;
- (void) writeByteArray:(uint8_t *)b length:(uint32_t)length error:(bool *)error;
- (void) writeByteArray:(SerializedBuffer_Wrapper *)b3 error:(bool *)error;
- (void) writeDouble:(double)d error:(bool *) error;
- (void) writeInt32:(int)x;
- (void) writeInt64:(int64_t)x;
- (void) writeBool:(bool) value;
- (void) writeBytes:(uint8_t *)b length:(uint32_t)length;
- (void) writeBytes:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length;
- (void) writeBytes: bytes :(SerializedBuffer_Wrapper *)b;
- (void) writeByte:(uint8_t)i;
- (void) writeString:(NSString*)s;
- (void) writeByteArray:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length;
- (void) writeByteArray:(uint8_t *)b length:(uint32_t)length;
- (void) writeByteArray: bytes :(SerializedBuffer_Wrapper *)b;
- (void) writeByteArrayData:(NSData *)b;
- (void) writeDouble:(double) d;
- (uint32_t) readUint32:(bool *)error;
- (uint64_t) readUint64:(bool *)error;
- (int32_t) readInt32:(bool *)error;
- (int32_t) readBigInt32:(bool *)error;
- (int64_t) readInt64:(bool *)error;
- (uint8_t) readByte:(bool *)error;
- (bool) readBool:(bool *)error;
- (void) readBytes:(uint8_t *)b length:(uint32_t)length error:(bool *)error;
- (NSString*) readString:(bool *)error;
- (NSData *) readByteArrayNSData:(bool *)error;
- (SerializedBuffer_Wrapper *)readByteBuffer:(bool)copy error:(bool *)error;
- (double) readDouble:(bool *)error;
- (uint32_t) position;
- (int) length;
- (void) skip:(uint32_t) length;
@end