//
//  Timer.h
//  paymon
//
//  Created by Vladislav on 14/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#ifndef __PMTIMER__
#define __PMTIMER__

#import <Foundation/Foundation.h>

@interface PMTimer : NSObject

- (instancetype)initWithTimeout:(NSTimeInterval)timeout repeat:(bool)repeat completionFunction:(dispatch_block_t)completionFunction queue:(dispatch_queue_t)queue;
- (void)start;
- (void)stop;
- (void)resetWithTimeout:(NSTimeInterval)timeout;

@end

#endif
