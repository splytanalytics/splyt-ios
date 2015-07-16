//
//  SplytSession.m
//  Splyt
//
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytSession.h>
#import <Splyt/SplytInternal.h>

// "private" interfaces
@interface SplytSessionTransaction ()
- (id) initWithCategory:(NSString*)category andInitBlock:(void(^)(SplytTransaction*)) initBlock __attribute__((unavailable("use initWithInitBlock")));
- (id) initWithInitBlock:(void(^)(SplytSessionTransaction*)) initBlock;
@end

@implementation SplytSessionTransaction : SplytTransaction {
}
static NSString* const CATEGORY_NAME = @"session";
static const NSTimeInterval DEFAULT_TIMEOUT = 10.0 * 86400.0; // 10 days

- (id) initWithInitBlock:(void(^)(SplytSessionTransaction*)) initBlock {
    self = [super initWithCategory:CATEGORY_NAME andId:nil andInitBlock:nil];

    // override some internals before calling init block
    _timeoutMode = SplytTimeoutMode_Any;
    _timeout = DEFAULT_TIMEOUT;

    if(initBlock)
        initBlock(self);

    return self;
}
@end

/**
 * This plugin provides functions that make it easy to report users' sessions with the app.
 */
@implementation SplytSession

- (SplytSessionTransaction*) Transaction {
    SplytSessionTransaction *trx = [[SplytSessionTransaction alloc] initWithInitBlock:nil];
    trx.core = self.instrumentation.core;

    return trx;
}

- (SplytSessionTransaction*) TransactionWithInitBlock:(void (^)(SplytSessionTransaction*)) initBlock {
    SplytSessionTransaction *trx = [[SplytSessionTransaction alloc] initWithInitBlock:initBlock];
    trx.core = self.instrumentation.core;

    return trx;
}

@end
