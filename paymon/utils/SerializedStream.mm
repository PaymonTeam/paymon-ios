//
// Created by Vladislav on 28/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import <string>
#import "SerializedStream.h"
#import "Defines.h"


@implementation SerializedStream {

}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self.out = [[NSMutableData alloc] init];
        self.isOut = true;
        self.justCalc = false;
        self.len = 0;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self != nil) {
        self.isOut = false;
        self.justCalc = false;
        self.len = 0;
        int len = data.length;
        self.in = [[NSInputStream alloc] initWithData:data];
        [self.in open];
//        bool has = self.in.hasBytesAvailable;
//        self.in = [NSMutableData init];
    }
    return self;
}

- (void)writeInt32:(int32_t)x error:(bool *)error {
    if (!_justCalc) {
        for(int i = 0; i < 4; i++) {
            byte b = (byte)(x >> (i * 8));
            [_out appendBytes:&b length:1];
        }
    } else {
        _len += 4;
    }
}

- (void)writeInt64:(int64_t)x error:(bool *)error {
    if (!_justCalc) {
        for(int i = 0; i < 8; i++) {
            byte b = (byte)(x >> (i * 8));
            [_out appendBytes:&b length:1];
        }
    } else {
        _len += 8;
    }
}

- (void)writeBool:(bool)value error:(bool *)error {
    if (!_justCalc) {
        if (value) {
            [self writeInt32:0x997275b5];
        } else {
            [self writeInt32:0xbc799737];
        }
    } else {
        _len += 4;
    }
}

- (void)writeBytes:(uint8_t *)b length:(uint32_t)length error:(bool *)error {
    if (!_justCalc) {
        [_out appendBytes:b length:length];
    } else {
        _len += length;
    }
}

- (void)writeBytes:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length error:(bool *)error {
    NSLog(@"writeBytesOffset doesn't work");
}

- (void)writeBytes:(SerializedBuffer_Wrapper *)b error1:(bool *)error {
    NSLog(@"writeBytesSerializedBuffer_Wrapper doesn't work");
}

- (void)writeByte:(uint8_t)i error:(bool *)error {
    if (!_justCalc) {
        [_out appendBytes:&i length:1];
    } else {
        _len += 1;
    }}

- (void)writeString:(NSString *)s error:(bool *)error {
    const std::basic_string<char, std::char_traits<char>, std::allocator<char>> &str = std::string(s.UTF8String);
    [self writeByteArray:(uint8_t *) str.c_str() length:str.length() error:error];
}

- (void)writeByteArray:(NSData *)data error2:(bool *)error2 {
    byte l = (byte) data.length;
    if (l <= 253) {
        if (!_justCalc) {
            [_out appendBytes:&l length:1];
        } else {
            _len += 1;
        }
    } else {
        if (!_justCalc) {
            byte i = 254;
            [_out appendBytes:&i length:1];
            i = l;
            [_out appendBytes:&i length:1];
            i = (l >> 8);
            [_out appendBytes:&i length:1];
            i = (l >> 16);
            [_out appendBytes:&i length:1];
        } else {
            _len += 4;
        }
    }
    if (!_justCalc) {
        [_out appendData:data];
    } else {
        _len += l;
    }
    int i = l <= 253 ? 1 : 4;
    while((l + i) % 4 != 0) {
        if (!_justCalc) {
            byte j = 0;
            [_out appendBytes:&j length:1];
        } else {
            _len += 1;
        }
        i++;
    }
}

- (void)writeByteArray:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length error:(bool *)error {
    NSLog(@"writeBytesOffset doesn't work");
}

- (void)writeByteArray:(uint8_t *)b length:(uint32_t)length error:(bool *)error {
    byte l = (byte) length;
    if (l <= 253) {
        if (!_justCalc) {
            [_out appendBytes:&l length:1];
        } else {
            _len += 1;
        }
    } else {
        if (!_justCalc) {
            byte i = 254;
            [_out appendBytes:&i length:1];
            i = l;
            [_out appendBytes:&i length:1];
            i = (l >> 8);
            [_out appendBytes:&i length:1];
            i = (l >> 16);
            [_out appendBytes:&i length:1];
        } else {
            _len += 4;
        }
    }
    if (!_justCalc) {
        [_out appendBytes:b length:length];
    } else {
        _len += l;
    }
    int i = l <= 253 ? 1 : 4;
    while((l + i) % 4 != 0) {
        if (!_justCalc) {
            byte j = 0;
            [_out appendBytes:&j length:1];
        } else {
            _len += 1;
        }
        i++;
    }
}

- (void)writeByteArray:(SerializedBuffer_Wrapper *)b3 error:(bool *)error {
    NSLog(@"writeBytesSerializedBuffer_Wrapper doesn't work");
}

- (void)writeDouble:(double)d error:(bool *)error {
    int64_t value;
    memcpy(&value, &d, sizeof(int64_t));
    [self writeInt64:value error:error];
}

- (void)writeInt32:(int)x {
    [self writeInt32:x error:nil];
}

- (void)writeInt64:(int64_t)x {
    [self writeInt64:x error:nil];
}

- (void)writeBool:(bool)value {
    [self writeBool:value error:nil];
}

- (void)writeBytes:(uint8_t *)b length:(uint32_t)length {
    [self writeBytes:b length:length error:nil];
}

- (void)writeBytes:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length {
    [self writeBytes:b offset:offset length:length error:nil];
}

- (void)writeByte:(uint8_t)i {
    [self writeByte:i error:nil];
}

- (void)writeString:(NSString *)s {
    [self writeString:s error:nil];
}

- (void)writeByteArray:(uint8_t *)b offset:(uint32_t)offset length:(uint32_t)length {
    [self writeByteArray:b offset:offset length:length error:nil];
}

- (void)writeByteArray:(uint8_t *)b length:(uint32_t)length {
    [self writeByteArray:b length:length error:nil];
}

- (void)writeByteArray:(id)bytes :(SerializedBuffer_Wrapper *)b {
    [self writeByteArray:bytes error:nil];
}

- (void)writeByteArrayData:(NSData *)b {
    [self writeByteArray:b error2:nil];
}

- (void)writeDouble:(double)d {
    [self writeDouble:d error:nil];
}

- (uint32_t)readUint32:(bool *)error {
    return (uint32_t) [self readInt32:error];
}

- (uint64_t)readUint64:(bool *)error {
    return (uint64_t) [self readInt64:error];
}

- (int32_t)readInt32:(bool *)error {
    int i = 0;
    for(int j = 0; j < 4; j++) {
        uint8_t r = 0;
        [_in read:&r maxLength:1];
        i |= (r << (j * 8));
        _len++;
    }
    return i;
}

- (int32_t)readBigInt32:(bool *)error {
    return [super readBigInt32:error];
}

- (int64_t)readInt64:(bool *)error {
    int i = 0;
    for(int j = 0; j < 8; j++) {
        byte r;
        [_in read:&r maxLength:1];
        i |= (r << (j * 8));
        _len++;
    }
    return i;
}

- (uint8_t)readByte:(bool *)error {
    return [super readByte:error];
}

- (bool)readBool:(bool *)error {
    int consructor = [self readInt32:error];
    if (consructor == 0x997275b5) {
        return true;
    } else if (consructor == 0xbc799737) {
        return false;
    }
    NSLog(@"readBool error");
    return false;
}

- (void)readBytes:(uint8_t *)b length:(uint32_t)length error:(bool *)error {
    [_in read:b maxLength:length];
}

- (NSString *)readString:(bool *)error {
    int sl = 1;
    uint8_t r;
    [_in read:&r maxLength:1];
    int l = r;
    _len++;
    if(l >= 254) {
        [_in read:&r maxLength:1];
        l = r;
        [_in read:&r maxLength:1];
        l |= (r << 8);
        [_in read:&r maxLength:1];
        l |= (r << 16);
        _len += 3;
        sl = 4;
    }
    byte* b = new byte[l];
    [_in read:b maxLength:l];
    _len++;
    int i=sl;
    while((l + i) % 4 != 0) {
        [_in read:&r maxLength:1];
        _len++;
        i++;
    }

    const std::string &string = std::string((const char *) b, l);
    const char* str = string.c_str();
    return [[NSString alloc] initWithBytes:str length:string.length() encoding:NSUTF8StringEncoding];
}

- (NSData *)readByteArrayNSData:(bool *)error {
    int sl = 1;
    byte r;
    [_in read:&r maxLength:1];
    int l = r;
    _len++;
    if(l >= 254) {
        [_in read:&r maxLength:1];
        l = r;
        [_in read:&r maxLength:1];
        l |= (r << 8);
        [_in read:&r maxLength:1];
        l |= (r << 16);
        _len += 3;
        sl = 4;
    }
    byte* b = new byte[l];
    [_in read:b maxLength:l];
    _len++;
    int i=sl;
    while((l + i) % 4 != 0) {
        [_in read:&r maxLength:1];
        _len++;
        i++;
    }
    return [[NSData alloc] initWithBytes:b length:l];
}

- (SerializedBuffer_Wrapper *)readByteBuffer:(bool)copy error:(bool *)error {
    return nil;
}

- (double)readDouble:(bool *)error {
    double value;
    int64_t value2 = [self readInt64:error];
    memcpy(&value, &value2, sizeof(double));
    return value;}

- (uint32_t)position {
    return _len;
}

- (int)length {
    if (!_justCalc) {
        return _isOut ? _out.length : _in.hasBytesAvailable ? 1 : 0;
    }
    return _len;
}

- (void)skip:(uint32_t)length {
    if (length == 0) {
        return;
    }
    if (!_justCalc) {
        if (_in != nil) {
            byte r[length];
            [_in read:r maxLength:length];
        }
    } else {
        _len += length;
    }
}

- (void)close {
    if (_in != nil) {
        [_in close];
    }
}

@end