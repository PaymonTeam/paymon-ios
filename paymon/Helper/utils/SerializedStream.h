//
// Created by Vladislav on 28/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerializableData.h"

@class SerializableData;
@class SerializedStream;

@interface SerializedStream : SerializableData
@property (nonatomic) NSMutableData *out;
@property (nonatomic) NSInputStream *in;
//@property (nonatomic) NSMutableData *in;
@property (nonatomic) bool isOut;
@property (nonatomic) bool justCalc;
@property (nonatomic) int len;
- (instancetype) init;
- (instancetype) initWithData:(NSData *)data;
- (void)close;
@end
