//
//  Request.h
//  paymon
//
//  Created by Vladislav on 13/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#ifndef __REQUEST__
#define __REQUEST__

#import <Foundation/Foundation.h>

@interface Request : NSObject

@property(nonatomic, copy, readonly) void (^completion)(bool success, id requestId);
@property(nonatomic, strong, readonly) NSData *packetData;

- (instancetype)initWithData:(NSData *)data completion:(void (^)(bool success, id requestId))completion;

@end

#endif