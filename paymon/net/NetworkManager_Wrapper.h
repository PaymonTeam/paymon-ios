//
//  NetworkManager_Wrapper.h
//  paymon
//
//  Created by Vladislav on 11/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//
#ifndef __NETWORK_MANAGER_WRAPPER__
#define __NETWORK_MANAGER_WRAPPER__
#import <Foundation/Foundation.h>
#include <openssl/aes.h>
#import "Connection.h"

@class SerializedBuffer_Wrapper;
@class NetworkManager_Wrapper;
@class Queue;
@class NetworkReachability;

struct SerializedBuffer;

@protocol NetworkManagerDelegate <NSObject>
@optional
- (void)onConnectionDataReceived:(NetworkManager_Wrapper *)connection buffer:(SerializedBuffer_Wrapper *)buffer length:(uint32_t)length;
- (void)onConnectionStateChanged:(NetworkManager_Wrapper *)connection isConnected:(bool)isConnected;
- (void)onConnectionError:(NetworkManager_Wrapper *)connection error:(NSError *)error;
@end

@protocol NetworkReachabilityDelegate <NSObject>
- (void)onNetworkReachabilityChanged:(bool)isReachable;
@end

@interface NetworkManager_Wrapper : NSObject <ConnectionDelegate, NetworkReachabilityDelegate>
+ (Queue *)netQueue;
- (instancetype)initWithDelegate:(id <NetworkManagerDelegate>)delegate;
- (void)writeBytes:(NSData *)data;//(SerializedBuffer_Wrapper *)buffer;
- (void)sendData:(SerializedBuffer_Wrapper *)buffer;
- (void)reconnect;
- (void)reset;
- (void)start;
- (void)stop;
- (void)setReadyForRequest;
- (void)requestConnection;
- (void)connectionClosed;

@property NSMutableArray *transArray;
@property NSMutableArray *transToDeleteArray;
@property(nonatomic, weak) id <NetworkManagerDelegate> delegate;
@property(nonatomic) bool needsReconnection;

@end

#endif