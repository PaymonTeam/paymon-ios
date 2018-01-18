//
//  Queue.h
//  paymon
//
//  Created by Vladislav on 12/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#ifndef __QUEUE__
#define __QUEUE__

#import <Foundation/Foundation.h>

@interface Queue : NSObject

- (instancetype)initWithName:(const char *)name;
- (dispatch_queue_t)nativeQueue;
- (void)run:(dispatch_block_t)block;
- (void)run:(dispatch_block_t)block sync:(bool)sync;

@end

#endif