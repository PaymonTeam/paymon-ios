//
//  Queue.h
//  paymon
//
//  Created by Vladislav on 12/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#import "Queue.h"

@interface Queue () {
    bool _isMainQueue;
    dispatch_queue_t _queue;
    const char *_name;
}

@end

@implementation Queue

- (instancetype)initWithName:(const char *)name {
    self = [super init];
    if (self != nil) {
        _name = name;

        _queue = dispatch_queue_create(_name, nil);
        dispatch_queue_set_specific(_queue, _name, (void *) _name, NULL);
    }
    return self;
}

- (dispatch_queue_t)nativeQueue {
    return _queue;
}

- (void)run:(dispatch_block_t)block {
    [self run:block sync:false];
}

- (void)run:(dispatch_block_t)block sync:(bool)sync {
    if (block == nil) {
        return;
    }

    if (_queue != nil) {
        if (_isMainQueue) {
            if ([NSThread isMainThread]) {
                block();
            } else if (sync) {
                dispatch_sync(_queue, block);
            } else {
                dispatch_async(_queue, block);
            }
        } else {
            if (dispatch_get_specific(_name) == _name) {
                block();
            }
            else if (sync) {
                dispatch_sync(_queue, block);
            }
            else {
                dispatch_async(_queue, block);
            }
        }
    }
}

- (void)dealloc {
    _queue = nil;
}

@end
