//
//  Request.h
//  paymon
//
//  Created by Vladislav on 13/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#import "Request.h"

@implementation Request

- (instancetype)initWithData:(NSData *)data completion:(void (^)(bool success, id requestId))completion {
    self = [super init];
    if (self != nil) {
        _packetData = data;
        _completion = completion;
    }
    return self;
}

@end
