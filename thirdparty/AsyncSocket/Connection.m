//
//  Connection.m
//  paymon
//
//  Created by Vladislav on 13/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#import "PMTimer.h"
#import "Queue.h"
#import "Connection.h"
#import "GCDAsyncSocket.h"
#import "UIKit/UIKit.h"

static const NSTimeInterval timeout = 12.0;

@interface Connection () <GCDAsyncSocketDelegate> {
    GCDAsyncSocket *_socket;
    bool _closed;
    PMTimer *_responseTimeoutTimer;
}

@end

@implementation Connection

+ (Queue *)connectionQueue {
    static Queue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[Queue alloc] initWithName:"ru.paymon.connectionQueue"];
    });
    return queue;
}

- (instancetype)initWithAddress:(NSString *)ip port:(uint16_t)port {
    self = [super init];
    if (self != nil) {
//        _ip = ip;
        _port = port;
        _interface = nil;
//        _hostSwapped = false;
    }
    return self;
}

- (void)start {
    [[Connection connectionQueue] run:^{
        if (_socket == nil) {
            _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:[[Connection connectionQueue] nativeQueue]];
            [_socket setIPv4Enabled:true];
            [_socket setIPv6Enabled:true];
//            [_socket setPreferIPv4OverIPv6:true];

            NSLog(@"Connecting to %@:%d", Connection.ip, (int) _port);

            __autoreleasing NSError *error = nil;
            if (![_socket connectToHost:Connection.ip onPort:_port withTimeout:12 error:&error] || error != nil) {
                if (error != nil) {
                    if ([_delegate respondsToSelector:@selector(onConnectionError:error:)])
                        [_delegate onConnectionError:self error:error];
                }
                NSLog(@"Can't open connection");
                [self close];
            } else {
                NSLog(@"Connection has opened");
                [_socket readDataWithTimeout:-1 tag:0];
            }
        }
    }];
}

- (void)stop {
    [[Connection connectionQueue] run:^{
        if (!_closed) {
            [self close];
        }
    }];
}

- (void)close {
    [[Connection connectionQueue] run:^{
        if (!_closed) {
            _closed = true;

            [_socket disconnect];
            _socket.delegate = nil;
            _socket = nil;

            id <ConnectionDelegate> delegate = _delegate;
            if ([delegate respondsToSelector:@selector(onConnectionClosed:)])
                [delegate onConnectionClosed:self];
        }
    }];
}

- (void)sendData:(NSMutableData *)data {
    [[Connection connectionQueue] run:^{
        if (!_closed) {
            if (_socket != nil) {
                [_socket writeData:data withTimeout:-1 tag:0];
            } else {
                NSLog(@"Error: can't send data (socket is not opened)");
            }
        } else {
            NSLog(@"Error: can't send data (socket is closed)");
        }
    }];
}

- (void)socket:(GCDAsyncSocket *)__unused socket didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)__unused tag {
    if (_closed) {
        return;
    }
    [_responseTimeoutTimer resetWithTimeout:timeout];
}

- (void)socket:(GCDAsyncSocket *)__unused socket didReadData:(NSData *)data withTag:(long)tag {
    if (_closed)
        return;

    id <ConnectionDelegate> delegate = _delegate;
    if ([delegate respondsToSelector:@selector(onConnectionReceivedData:data:)])
        [delegate onConnectionReceivedData:self data:data];

    [_socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)__unused socket didConnectToHost:(NSString *)__unused host port:(uint16_t)__unused port {
    id <ConnectionDelegate> delegate = _delegate;
    if ([delegate respondsToSelector:@selector(onConnectionConnected:)])
        [_delegate onConnectionConnected:self];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)__unused socket withError:(NSError *)error {
    if (error != nil) {
        if (error.code == 51 || error.code == 65) {
            Connection.hostSwapped = !Connection.hostSwapped;
            Connection.ip = Connection.hostSwapped ? @"2a01:5560:1001:2d78:0000:0000:0000:0001" : @"91.226.80.26";
        } else {
            if ([_delegate respondsToSelector:@selector(onConnectionError:error:)])
                [_delegate onConnectionError:self error:error];
        }
        NSLog(@"Socket did disconnected with error: %@", error);
    } else {
        NSLog(@"Socket did disconnected");
    }

    [self close];
}

- (void)dealloc {
    GCDAsyncSocket *socket = _socket;
    socket.delegate = nil;
    _socket = nil;

    PMTimer *timeoutTimer = _responseTimeoutTimer;

    [[Connection connectionQueue] run:^{
        [timeoutTimer stop];
        [socket disconnect];
    }];
}

static bool hostSwapped;
+ (bool) hostSwapped { @synchronized(self) { return hostSwapped; } }
+ (void) setHostSwapped:(bool)val { @synchronized(self) { hostSwapped = val; } }

static NSString* ip;
+ (NSString*) ip { @synchronized(self) {
        if (!ip) {
            ip = @"paymon.org";
        }
        return ip;
    }
}
+ (void)setIp:(NSString*)val { @synchronized(self) { ip = val; } }

@end
