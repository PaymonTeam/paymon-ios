/*
 * This is the source code of tgnet library v. 1.0
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Nikolai Kudashov, 2015.
 */

#ifndef NATIVEBYTEBUFFER_H
#define NATIVEBYTEBUFFER_H

#include <stdint.h>
#include <memory.h>
#include <string>
#include <stdlib.h>
#include "ByteArray.h"
#include "BuffersStorage.h"

class ByteArray;

struct SerializedBuffer {

public:
    SerializedBuffer(uint32_t size);
    SerializedBuffer(bool calculate);
    SerializedBuffer(uint8_t *buff, uint32_t length);
    ~SerializedBuffer();

    uint32_t position();
    void position(uint32_t position);
    uint32_t limit();
    void limit(uint32_t limit);
    uint32_t capacity();
    uint32_t remaining();
    bool hasRemaining();
    void rewind();
    void compact();
    void flip();
    void clear();
    void skip(uint32_t length);
    void clearCapacity();
    uint8_t *bytes();

    void writeInt32(int32_t x, bool *error);
    void writeInt64(int64_t x, bool *error);
    void writeBool(bool value, bool *error);
    void writeBytes(uint8_t *b, uint32_t length, bool *error);
    void writeBytes(uint8_t *b, uint32_t offset, uint32_t length, bool *error);
    void writeBytes(ByteArray *b, bool *error);
    void writeBytes(SerializedBuffer *b, bool *error);
    void writeByte(uint8_t i, bool *error);
    void writeString(std::string s, bool *error);
    void writeByteArray(uint8_t *b, uint32_t offset, uint32_t length, bool *error);
    void writeByteArray(uint8_t *b, uint32_t length, bool *error);
    void writeByteArray(SerializedBuffer *b, bool *error);
    void writeByteArray(ByteArray *b, bool *error);
    void writeDouble(double d, bool *error);
    void writeInt32(int32_t x);
    void writeInt64(int64_t x);
    void writeBool(bool value);
    void writeBytes(uint8_t *b, uint32_t length);
    void writeBytes(uint8_t *b, uint32_t offset, uint32_t length);
    void writeBytes(ByteArray *b);
    void writeBytes(SerializedBuffer *b);
    void writeByte(uint8_t i);
    void writeString(std::string s);
    void writeByteArray(uint8_t *b, uint32_t offset, uint32_t length);
    void writeByteArray(uint8_t *b, uint32_t length);
    void writeByteArray(SerializedBuffer *b);
    void writeByteArray(ByteArray *b);
    void writeDouble(double d);
    int length();

    uint32_t readUint32(bool *error);
    uint64_t readUint64(bool *error);
    int32_t readInt32(bool *error);
    int32_t readBigInt32(bool *error);
    int64_t readInt64(bool *error);
    uint8_t readByte(bool *error);
    bool readBool(bool *error);
    void readBytes(uint8_t *b, uint32_t length, bool *error);
    ByteArray *readBytes(uint32_t length, bool *error);
    std::string readString(bool *error);
    ByteArray *readByteArray(bool *error);
    SerializedBuffer *readByteBuffer(bool copy, bool *error);
    double readDouble(bool *error);
    uint32_t _capacity = 0;
    void reuse();
private:
    void writeBytesInternal(uint8_t *b, uint32_t offset, uint32_t length);

    uint8_t *buffer = nullptr;
    bool calculateSizeOnly = false;
    bool sliced = false;
    uint32_t _position = 0;
    uint32_t _limit = 0;
    bool bufferOwner = true;
};

#endif
