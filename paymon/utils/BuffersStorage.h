/*
 * This is the source code of tgnet library v. 1.0
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Nikolai Kudashov, 2015.
 */

#ifndef BUFFERSSTORAGE_H
#define BUFFERSSTORAGE_H

#include <vector>
#include <pthread.h>
#include <stdint.h>

class SerializedBuffer;

class BuffersStorage {

public:
    BuffersStorage(bool threadSafe);
    SerializedBuffer *getFreeBuffer(uint32_t size);
    void reuseFreeBuffer(SerializedBuffer *buffer);
    static BuffersStorage &getInstance();

private:
    std::vector<SerializedBuffer *> freeBuffers8;
    std::vector<SerializedBuffer *> freeBuffers128;
    std::vector<SerializedBuffer *> freeBuffers1024;
    std::vector<SerializedBuffer *> freeBuffers4096;
    std::vector<SerializedBuffer *> freeBuffers16384;
    std::vector<SerializedBuffer *> freeBuffers32768;
    std::vector<SerializedBuffer *> freeBuffersBig;
    bool isThreadSafe = true;
    pthread_mutex_t mutex;
};

#endif
