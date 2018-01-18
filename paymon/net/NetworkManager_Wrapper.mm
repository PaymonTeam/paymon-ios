//
//  NetworkManager_Wrapper.m
//  paymon
//
//  Created by Vladislav on 11/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#import <iostream>
#import <iomanip>
#import "SerializedBuffer-Wrapper.h"
#import "BuffersStorage.h"
#import "SerializedBuffer.h"
#import "rand.h"
#import "PMTimer.h"
#import "Request.h"
#import "aes.h"
#import "Connection.h"
#import "NetworkManager_Wrapper.h"
#import "Queue.h"
#import "paymon-Swift.h"

static bool isFirstPacketSent = false;
static AES_KEY encryptKey;
static uint8_t encryptIv[16];
static uint32_t encryptNum;
static uint8_t encryptCount[16];

static AES_KEY decryptKey;
static uint8_t decryptIv[16];
static uint32_t decryptNum;
static uint8_t decryptCount[16];

static struct SerializedBuffer *unprocessedData;
static uint lastPacketLength;
static int failedConnectionCount;

static const NSTimeInterval sleepTimeout = 60.0;

@class NetworkManager_Wrapper;

@interface NetworkManager_Wrapper () <ConnectionDelegate, NetworkReachabilityDelegate> {
    NetworkReachability *_nr;
    Connection *_connection;
    bool _isConnectionConnected;
    bool _isStopped;
    bool _isNetworkAvailable;
    bool _needToSendRequestFlag;
    PMTimer *_sleepTimer;
    PMTimer *_retryTimer;
    NSInteger _retriesCount;
}

@end

@implementation NetworkManager_Wrapper

+ (Queue *)netQueue {
    static Queue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[Queue alloc] initWithName:"ru.paymon.netQueue"];
    });
    return queue;
}

- (instancetype)initWithDelegate:(id <NetworkManagerDelegate>)delegate {
    self = [super init];
    if (self != nil) {
        self.delegate = delegate;
        _nr = [[NetworkReachability alloc] initWithDelegate:self];
        _needsReconnection = true;
        _isNetworkAvailable = true;

        self.transArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.transToDeleteArray = [[NSMutableArray alloc] initWithCapacity:4];
        unprocessedData = nullptr;
        lastPacketLength = 0;
        [self start];
    }
    return self;
}

+ (Queue *)connectionQueue {
    static Queue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[Queue alloc] initWithName:"ru.paymon.connectionQueue"];
    });
    return queue;
}

void print(uint8_t *buffer, int size) {
    const int siz_ar = size;
    for (int i = 0; i < siz_ar; ++i)
        std::cout << std::hex << std::setfill('0') << std::setw(2) << std::uppercase << (int) buffer[i] << " ";
    std::cout << std::endl;
}

- (void)writeBytes:(NSData *)data { //(SerializedBuffer_Wrapper *)buff {
    // TODO: make pointer?
    for (id transId in self.transToDeleteArray) {
        [self.transArray removeObject:transId];
    }
    [self.transToDeleteArray removeAllObjects];

//    SerializedBuffer *buffer = buff->_cppClass;
//    NSData *data = [[NSData alloc] initWithBytes:buffer->bytes() + buffer->position() length:buffer->limit()];
    Request *trans = [[Request alloc] initWithData:data completion:^(bool success, id requestId) {
        [self.transToDeleteArray addObject:requestId];
    }];
    [self.transArray addObject:trans];
}

- (void)onConnectionStateChanged:(NetworkManager_Wrapper *)nm isConnected:(bool)isConnected {
    [[NetworkManager_Wrapper netQueue] run:^{
        NSLog(@"isConnected==%d", isConnected);
        if ([self.delegate respondsToSelector:@selector(onConnectionStateChanged:isConnected:)])
            [self.delegate onConnectionStateChanged:self isConnected:isConnected];
    }];
}

- (void)sendData:(SerializedBuffer_Wrapper *)data {
    [[NetworkManager_Wrapper netQueue] run:^{
        SerializedBuffer *buff = data->_cppClass;

        if (buff == nullptr) {
            return;
        }

        buff->rewind();

        uint32_t bufferLen = 0;
        uint32_t packetLength = buff->limit() / 4;

        if (packetLength < 0x7f) {
            bufferLen++;
        } else {
            bufferLen += 4;
        }

        if (!isFirstPacketSent) {
            bufferLen += 64;
        }

        SerializedBuffer *buffer = BuffersStorage::getInstance().getFreeBuffer(bufferLen);
        uint8_t *bufferBytes = buffer->bytes();

        if (!isFirstPacketSent) {
            buffer->position(64);
            static uint8_t tempBytes[64];
            while (true) {
                RAND_bytes(bufferBytes, 64);

                uint32_t val = (bufferBytes[3] << 24) | (bufferBytes[2] << 16) | (bufferBytes[1]
                        << 8) | (bufferBytes[0]);
                uint32_t val2 = (bufferBytes[7] << 24) | (bufferBytes[6] << 16) | (bufferBytes[5]
                        << 8) | (bufferBytes[4]);
                if (bufferBytes[0] != 0xef && val != 0x44414548 && val != 0x54534f50 && val != 0x20544547 && val != 0x4954504f && val != 0xeeeeeeee && val2 != 0x00000000) {
                    bufferBytes[56] = bufferBytes[57] = bufferBytes[58] = bufferBytes[59] = 0xef;
                    break;
                }
            }

            for (int i = 0; i < 48; i++) {
                tempBytes[i] = bufferBytes[55 - i];
            }

            encryptNum = decryptNum = 0;
            memset(encryptCount, 0, 16);
            memset(decryptCount, 0, 16);

            if (AES_set_encrypt_key(bufferBytes + 8, 256, &encryptKey) < 0) {
                NSLog(@"Failed to set encryptKey");
                exit(1);
            }

            memcpy(encryptIv, bufferBytes + 40, 16);

            if (AES_set_encrypt_key(tempBytes, 256, &decryptKey) < 0) {
                NSLog(@"Failed to set decryptKey");
                exit(1);
            }

            memcpy(decryptIv, tempBytes + 32, 16);

            for (int i = 0; i < 8; i++) {
                decryptKey.rd_key[i] = ntohl(decryptKey.rd_key[i]);
            }

            AES_ctr128_encrypt(bufferBytes, tempBytes, 64, &encryptKey, encryptIv, encryptCount, &encryptNum);
            memcpy(bufferBytes + 56, tempBytes + 56, 8);
            isFirstPacketSent = true;
        }
        if (packetLength < 0x7f) {
            buffer->writeByte((uint8_t) packetLength);
            bufferBytes += (buffer->limit() - 1);
            AES_ctr128_encrypt(bufferBytes, bufferBytes, 1, &encryptKey, encryptIv, encryptCount, &encryptNum);
        } else {
            packetLength = (packetLength << 8) + 0x7f;
            buffer->writeInt32(packetLength);
            bufferBytes += (buffer->limit() - 4);
            AES_ctr128_encrypt(bufferBytes, bufferBytes, 4, &encryptKey, encryptIv, encryptCount, &encryptNum);
        }

        size_t size = (size_t) buffer->length();
        NSData *data1 = [[NSData alloc] initWithBytes:buffer->bytes() length:(NSUInteger) size];
        [self writeBytes:data1];

        AES_ctr128_encrypt(buff->bytes(), buff->bytes(), buff->limit(), &encryptKey, encryptIv, encryptCount, &encryptNum);

        size = (size_t) buff->limit();
        NSData *data2 = [[NSData alloc] initWithBytes:buff->bytes() length:(NSUInteger) size];
        [self writeBytes:data2];

        [self setReadyForRequest];
    } sync:true];
}

- (void)setReadyForRequest {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        if (!_needToSendRequestFlag) {
            _needToSendRequestFlag = true;

            dispatch_async([NetworkManager_Wrapper connectionQueue].nativeQueue, ^{
                _needToSendRequestFlag = false;

                if (_connection == nil) {
                    [self requestConnection];
                } else if (_isConnectionConnected) {
                    [[Connection connectionQueue] run:^{
                        for (Request *request in _transArray) {
                            if (request.packetData.length != 0) {
                                if (_connection != nil) {
                                    NSMutableData *data = [[NSMutableData alloc] initWithData:request.packetData];
                                    [_connection sendData:data];
                                    request.completion(true, request);
                                }
                            }
                        }
                    }];
                }
            });
        }
    }];
}

- (void)start {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        if (_connection == nil) {
            _connection = [[Connection alloc] initWithAddress:@"2a01:5560:1001:2d78:0000:0000:0000:0001" port:7966];
            [_connection setDelegate:self];
            [_connection start];
        }
    }];
}

- (void)restartSleepTimer {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        [_sleepTimer resetWithTimeout:sleepTimeout];
    }];
}

- (void)stopSleepTimer {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        [_sleepTimer stop];
        _sleepTimer = nil;
    }];
}

- (void)onConnectionConnected:(Connection *)connection {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        if (_connection != connection)
            return;

        _isConnectionConnected = true;

        [self onConnectionStateChanged:self isConnected:true];
    }];
}

- (void)onConnectionClosed:(Connection *)connection {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        if (_connection != connection)
            return;

        _isConnectionConnected = false;
        _connection.delegate = nil;
        _connection = nil;

        [self connectionClosed];

        [self restartSleepTimer];
        [self onConnectionStateChanged:self isConnected:false];
    }];
}

- (void)onConnectionReceivedData:(Connection *)connection data:(NSData *)data {
    if (_connection != connection)
        return;

    [[NetworkManager_Wrapper netQueue] run:^{
        SerializedBuffer *buffer = new SerializedBuffer((uint8_t *) data.bytes, data.length);

        AES_ctr128_encrypt(buffer->bytes(), buffer->bytes(), buffer->limit(), &decryptKey, decryptIv, decryptCount, &decryptNum);

        failedConnectionCount = 0;
        SerializedBuffer *parseLaterBuffer = nullptr;
        if (unprocessedData != nullptr) {
            if (lastPacketLength == 0) {
                if (unprocessedData->capacity() - unprocessedData->position() >= buffer->limit()) {
                    unprocessedData->limit(unprocessedData->position() + buffer->limit());
                    unprocessedData->writeBytes(buffer);
                    buffer = unprocessedData;
                } else {
                    SerializedBuffer *newBuffer = BuffersStorage::getInstance().getFreeBuffer(unprocessedData->limit() + buffer->limit());
                    unprocessedData->rewind();
                    newBuffer->writeBytes(unprocessedData);
                    newBuffer->writeBytes(buffer);
                    buffer = newBuffer;
                    unprocessedData->reuse();
                    unprocessedData = newBuffer;
                }
            } else {
                uint32_t len;
                if (lastPacketLength - unprocessedData->position() <= buffer->limit()) {
                    len = lastPacketLength - unprocessedData->position();
                } else {
                    len = buffer->limit();
                }
                uint32_t oldLimit = buffer->limit();
                buffer->limit(len);
                unprocessedData->writeBytes(buffer);
                buffer->limit(oldLimit);
                if (unprocessedData->position() == lastPacketLength) {
                    parseLaterBuffer = buffer->hasRemaining() ? buffer : nullptr;
                    buffer = unprocessedData;
                } else {
                    return;
                }
            }
        }

        buffer->rewind();

        while (buffer->hasRemaining()) {
            uint32_t currentPacketLength = 0;
            uint32_t mark = buffer->position();
            uint8_t fByte = buffer->readByte(nullptr);

            if (fByte != 0x7f) {
                currentPacketLength = ((uint32_t) fByte) * 4;
            } else {
                buffer->position(mark);
                if (buffer->remaining() < 4) {
                    if (unprocessedData == nullptr || (unprocessedData != nullptr && unprocessedData->position() != 0)) {
                        SerializedBuffer *reuseLater = unprocessedData;
                        unprocessedData = BuffersStorage::getInstance().getFreeBuffer(16384);
                        unprocessedData->writeBytes(buffer);
                        unprocessedData->limit(unprocessedData->position());
                        lastPacketLength = 0;
                        if (reuseLater != nullptr) {
                            reuseLater->reuse();
                        }
                    } else {
                        unprocessedData->position(unprocessedData->limit());
                    }
                    break;
                }
                currentPacketLength = ((uint32_t) buffer->readInt32(nullptr) >> 8) * 4;
            }

            if (currentPacketLength % 4 != 0 || currentPacketLength > 2 * 1024 * 1024) {
                NSLog(@"connection(%@) received invalid packet length", self);
                [self reconnect];
                return;
            }

            if (currentPacketLength < buffer->remaining()) {
                NSLog(@"connection(%@) received message len %u but packet larger %u", self, currentPacketLength, buffer->remaining());
            } else if (currentPacketLength == buffer->remaining()) {
                NSLog(@"connection(%@) received message len %u equal to packet size", self, currentPacketLength);
            } else {
                NSLog(@"connection(%@) received packet size less(%u) then message size(%u)", self, buffer->remaining(), currentPacketLength);

                SerializedBuffer *reuseLater = nullptr;
                uint32_t len = currentPacketLength + (fByte != 0x7f ? 1 : 4);
                if (unprocessedData != nullptr && unprocessedData->capacity() < len) {
                    reuseLater = unprocessedData;
                    unprocessedData = nullptr;
                }
                if (unprocessedData == nullptr) {
                    buffer->position(mark);
                    unprocessedData = BuffersStorage::getInstance().getFreeBuffer(len);
                    unprocessedData->writeBytes(buffer);
                } else {
                    unprocessedData->position(unprocessedData->limit());
                    unprocessedData->limit(len);
                }
                lastPacketLength = len;
                if (reuseLater != nullptr) {
                    reuseLater->reuse();
                }
                return;
            }

            uint32_t old = buffer->limit();
            buffer->limit(buffer->position() + currentPacketLength);

            SerializedBuffer_Wrapper *sbw = [[SerializedBuffer_Wrapper alloc] initWithSize:buffer->remaining()];
            memcpy(sbw->_cppClass->bytes(), buffer->bytes() + buffer->position(), buffer->remaining());
            if ([self.delegate respondsToSelector:@selector(onConnectionDataReceived:buffer:length:)])
                [self.delegate onConnectionDataReceived:self buffer:sbw length:currentPacketLength];

            buffer->position(buffer->limit());
            buffer->limit(old);

            if (unprocessedData != nullptr) {
                if ((lastPacketLength != 0 && unprocessedData->position() == lastPacketLength) || (lastPacketLength == 0 && !unprocessedData->hasRemaining())) {
                    unprocessedData->reuse();
                    unprocessedData = nullptr;
                } else {
                    NSLog(@"compact occured");
                    unprocessedData->compact();
                    unprocessedData->limit(unprocessedData->position());
                    unprocessedData->position(0);
                }
            }

            if (parseLaterBuffer != nullptr) {
                buffer = parseLaterBuffer;
                parseLaterBuffer = nullptr;
            }
        }
    }];
}

- (void)onConnectionError:(Connection *)connection error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(onConnectionError:error:)])
        [self.delegate onConnectionError:self error:error];
}


- (void)reconnect {
    [[NetworkManager_Wrapper netQueue] run:^{
        NSLog(@"Reconnecting...");
        [[NetworkManager_Wrapper connectionQueue] run:^{
            _isConnectionConnected = false;
            [self onConnectionStateChanged:self isConnected:false];
            _needsReconnection = true;
            [_connection stop];
        }];
    }];
}

- (void)onNetworkReachabilityChanged:(bool)isReachable {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        _isNetworkAvailable = isReachable;

        if (isReachable) {
            _retriesCount = 0;
        }
        // TODO: check auth
        [_connection stop];
    }];
}

- (void)reset {
    [[NetworkManager_Wrapper netQueue] run:^{
        [self.transArray removeAllObjects];
        [self.transToDeleteArray removeAllObjects];
        if (unprocessedData != nil) {
            delete unprocessedData;
            unprocessedData = nil;
        }
        lastPacketLength = 0;
        isFirstPacketSent = false;
        bzero(encryptIv, 16);
        bzero(encryptCount, 16);
        bzero(decryptIv, 16);
        bzero(decryptCount, 16);
        encryptNum = decryptNum = 0;
    }];
}

- (void)stop {
    [[NetworkManager_Wrapper connectionQueue] run:^{
        _isStopped = true;
        _isConnectionConnected = false;

        [self onConnectionStateChanged:self isConnected:false];

        _needsReconnection = false;
        _connection.delegate = nil;
        [_connection stop];
        _connection = nil;

        [self stopSleepTimer];
    }];
}

- (void)requestConnection {
    if (_retryTimer == nil) {
        [self timerEvent];
    }
}

- (void)connectionClosed {
    if (_needsReconnection) {
        _retriesCount++;

        if (_retriesCount == 1)
            [self timerEvent];
        else {
            NSTimeInterval delay;

            if (_retriesCount <= 5)
                delay = 1.0;
            else if (_retriesCount <= 20)
                delay = 4.0;
            else
                delay = 8.0;

            [self startReconnectionTimer:delay];
        }
    }
}

- (void)stopReconnectionTimer {
    PMTimer *reconnectionTimer = _retryTimer;
    _retryTimer = nil;

    [[NetworkManager_Wrapper connectionQueue] run:^{
        [reconnectionTimer stop];
    }];
}

- (void)startReconnectionTimer:(NSTimeInterval)timeout {
    [self stopReconnectionTimer];

    [[NetworkManager_Wrapper connectionQueue] run:^{
        __weak NetworkManager_Wrapper *weakSelf = self;
        _retryTimer = [[PMTimer alloc] initWithTimeout:timeout repeat:false completionFunction:^{
            __strong NetworkManager_Wrapper *strongSelf = weakSelf;
            [strongSelf timerEvent];
        } queue:[[NetworkManager_Wrapper connectionQueue] nativeQueue]];
        [_retryTimer start];
    }];
}

- (void)timerEvent {
    [self stopReconnectionTimer];

    [[NetworkManager_Wrapper connectionQueue] run:^{
        if (!_isStopped)
            [self start];
    }];
}

- (void)dealloc {
    Connection *connection = _connection;
    _connection = nil;

    [self stopReconnectionTimer];

    PMTimer *sleepWatchdogTimer = _sleepTimer;
    _sleepTimer = nil;

    [[NetworkManager_Wrapper connectionQueue] run:^{
        connection.delegate = nil;

        _needsReconnection = false;
        _delegate = nil;

        [sleepWatchdogTimer stop];
    }];
}

@end