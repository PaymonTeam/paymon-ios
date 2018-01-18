//
//  Connection.h
//  paymon
//
//  Created by Vladislav on 13/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//
#ifndef __CONNECTION__
#define __CONNECTION__

@class Queue;
@class Connection;

@protocol ConnectionDelegate <NSObject>
@optional
- (void)onConnectionConnected:(Connection *)connection;
- (void)onConnectionClosed:(Connection *)connection;
- (void)onConnectionError:(Connection *)connection error:(NSError* )error;
- (void)onConnectionReceivedData:(Connection *)connection data:(NSData *)data;
@end

@interface Connection : NSObject

@property(nonatomic, weak) id <ConnectionDelegate> delegate;
@property(nonatomic, strong, readonly) NSString *host;
//@property(nonatomic, strong, readonly) NSString *ip;
@property(nonatomic, readonly) uint16_t port;
@property(nonatomic, strong, readonly) NSString *interface;
//@property(nonatomic) bool *hostSwapped;

+ (bool)hostSwapped;
+ (NSString*)ip;
+ (Queue *)connectionQueue;
- (instancetype)initWithAddress:(NSString *)ip port:(uint16_t)port;
- (void)start;
- (void)stop;
- (void)sendData:(NSMutableData *)data;
- (void)setDelegate:(id <ConnectionDelegate>)delegate;
@end

#endif