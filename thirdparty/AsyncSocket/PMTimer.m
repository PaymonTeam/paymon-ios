//
//  PMTimer.h
//  paymon
//
//  Created by Vladislav on 14/08/2017.
//  Copyright © 2017 Paymon. All rights reserved.
//

#import "PMTimer.h"

@interface PMTimer ()

@property(nonatomic, strong) dispatch_source_t timer;
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic) bool isRepeatable;
@property(nonatomic, copy) dispatch_block_t func;
@property(nonatomic, strong) dispatch_queue_t queue;

@end

@implementation PMTimer

- (instancetype)initWithTimeout:(NSTimeInterval)timeout repeat:(bool)repeat completionFunction:(dispatch_block_t)completionFunction queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self != nil) {
        _timeout = timeout;
        _isRepeatable = repeat;
        self.func = completionFunction;
        _queue = queue;
    }
    return self;
}

- (void)dealloc {
    if (_timer != nil) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }

    if (_queue != nil) {
        _queue = nil;
    }
}

- (void)start {
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (_timeout * NSEC_PER_SEC)), _isRepeatable ? (uint64_t) (_timeout * NSEC_PER_SEC) : DISPATCH_TIME_FOREVER, 0);

    dispatch_source_set_event_handler(_timer, ^{
        if (self.func)
            self.func();
        if (!_isRepeatable) {
            [self stop];
        }
    });
    dispatch_resume(_timer);
}

- (void)stop {
    if (_timer != nil) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)resetWithTimeout:(NSTimeInterval)timeout {
    [self stop];

    _timeout = timeout;
    [self start];
}
@end
