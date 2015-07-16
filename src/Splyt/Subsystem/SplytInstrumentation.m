//
//  SplytInstrumentation.m
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytInstrumentation.h>
#import <Splyt/SplytInternal.h>

@implementation SplytTransaction

- (NSString*) stringForTimeoutMode:(SplytTimeoutMode)timeoutMode {
    NSString* const strings[SplytTimeoutMode_Count] = {
        [SplytTimeoutMode_Transaction] = @"TXN",
        [SplytTimeoutMode_Any] = @"ANY"
    };
    return strings[timeoutMode];
}

- (id) initWithCategory:(NSString*)category andId:(NSString*)transactionId andInitBlock:(void(^)(SplytTransaction*)) initBlock {
    if(nil == category) {
        [SplytUtil logDebug:@"category may not be nil for a transaction"];
        return nil;
    }

    self = [super init];

    // We make our own copy in case the user is using a mutable string
    _category = [category copy];
    _transactionId = [transactionId copy];
    _timeoutMode = SplytTimeoutMode_Default;
    _timeout = 0;
    _state = [[NSMutableDictionary alloc] init];

    if(initBlock)
        initBlock(self);

    return self;
}

#pragma mark - configuration
- (void) setProperty:(NSString*)key withValue:(NSObject*)value {
    if(nil == key) {
        [SplytUtil logDebug:@"Cannot pass nil key to -setProperty. Ignoring"];
        return;
    }

    // Create a dictionary from the key/value
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] initWithDictionary:@{key:SPLYT_SAFE(value)}];

    // Now append these properties
    [self setProperties:temp];
}
- (void) setProperties:(NSDictionary*)values {
    if(!values) {
        [SplytUtil logDebug:@"Ignoring nil values passed to setProperties"];
        return;
    }

    // Make our own deep copy of what's passed in so that the data doesn't mutate before it's actually sent
    NSDictionary* copy = (NSDictionary*)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)values, kCFPropertyListImmutable));

    if (nil != copy) {
        // Add to the current set of properties
        [_state addEntriesFromDictionary:copy];
    }
    else {
        [SplytUtil logError:@"Invalid property list.  The property list must be a dictionary which can only contain simple NS* types and other dictionaries."];
    }
}

#pragma mark - actions
- (void) begin {
    [self beginWithTimeout:_timeout andMode:_timeoutMode];
}
- (void) beginWithTimeout:(NSTimeInterval)timeout {
    [self beginWithTimeout:timeout andMode:_timeoutMode];
}
- (void) beginWithTimeout:(NSTimeInterval)timeout andMode:(SplytTimeoutMode)mode {
    NSArray* args = @[
        SPLYT_SAFE(_category),
        SPLYT_SAFE([self stringForTimeoutMode:mode]),
        SPLYT_SAFE(@(timeout)),
        SPLYT_SAFE(_transactionId),
        SPLYT_SAFE(_state)
    ];

    [self.core sendDataPoint:@"datacollector_beginTransaction" withArgs:args];

    // Clear the properties so we don't waste bandwidth by sending them again on update/end
    // Note that we create a new dictionary as opposed to removing the objects as those are still being referenced by the event that has yet to be sent
    _state = [[NSMutableDictionary alloc] init];
}
- (void) updateAtProgress:(NSInteger)progress {
    NSArray* args = @[
        SPLYT_SAFE(_category),
        SPLYT_SAFE(@(progress)),
        SPLYT_SAFE(_transactionId),
        SPLYT_SAFE(_state)
    ];

    [self.core sendDataPoint:@"datacollector_updateTransaction" withArgs:args];

    // Clear the properties so we don't waste bandwidth by sending them again on end
    // Note that we create a new dictionary as opposed to removing the objects as those are still being referenced by the event that has yet to be sent
    _state = [[NSMutableDictionary alloc] init];
}
- (void) end {
    [self endWithResult:SPLYT_TXN_SUCCESS];
}
- (void) endWithResult:(NSString*)result {
    NSArray* args = @[
        SPLYT_SAFE(_category),
        SPLYT_SAFE([result copy]),
        SPLYT_SAFE(_transactionId),
        SPLYT_SAFE(_state)
    ];

    [self.core sendDataPoint:@"datacollector_endTransaction" withArgs:args];

    // Clear the properties in case this transaction happens to be reused.  If so, we expect new properties to be set
    // Note that we create a new dictionary as opposed to removing the objects as those are still being referenced by the event that has yet to be sent
    _state = [[NSMutableDictionary alloc] init];
}
- (void) beginAndEnd {
    [self end];
}
- (void) beginAndEndWithResult:(NSString *)result {
    [self endWithResult:result];
}
@end

@implementation SplytInstrumentation

#pragma mark - internal

- (void) initInstrumentation {
    [SplytUtil cacheCurrencyInfo];
}

#pragma mark - public

- (SplytTransaction*) Transaction:(NSString*)category {
    return [self Transaction:category withId:nil andInitBlock:nil];
}
- (SplytTransaction*) Transaction:(NSString*)category withId:(NSString*)transactionId {
    return [self Transaction:category withId:transactionId andInitBlock:nil];
}
- (SplytTransaction*) Transaction:(NSString*)category withInitBlock:(void (^)(SplytTransaction*)) initBlock {
    return [self Transaction:category withId:nil andInitBlock:initBlock];
}
- (SplytTransaction*) Transaction:(NSString*)category withId:(NSString*)transactionId andInitBlock:(void (^)(SplytTransaction*)) initBlock {
    SplytTransaction* transaction = [[SplytTransaction alloc] initWithCategory:category andId:transactionId andInitBlock:initBlock];
    transaction.core = self.core;
    return transaction;
}

- (void) updateDeviceState:(NSDictionary *)state {
    // Make our own deep copy of what's passed in so that the data doesn't mutate before it's actually sent
    NSDictionary* copy = (NSDictionary*)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)state, kCFPropertyListImmutable));

    if (nil != copy) {
        [self.core sendDataPoint:@"datacollector_updateDeviceState" withArgs:@[SPLYT_SAFE(copy)]];
    }
    else {
        [SplytUtil logError:@"Invalid property list.  The property list must be a dictionary which can only contain simple NS* types and other dictionaries."];
    }
}
- (void) updateUserState:(NSDictionary *)state {
    // Make our own deep copy of what's passed in so that the data doesn't mutate before it's actually sent
    NSDictionary* copy = (NSDictionary*)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)state, kCFPropertyListImmutable));

    if (nil != copy) {
        [self.core sendDataPoint:@"datacollector_updateUserState" withArgs:@[SPLYT_SAFE(copy)]];
    }
    else {
        [SplytUtil logError:@"Invalid property list.  The property list must be a dictionary which can only contain simple NS* types and other dictionaries."];
    }
}
- (void) updateCollection:(NSString*)name toBalance:(NSNumber*)balance byAdding:(NSNumber*)balanceModification andTreatAsCurrency:(BOOL)isCurrency {
    NSArray* args = @[
        SPLYT_SAFE([name copy]),
        SPLYT_SAFE([balance copy]),
        SPLYT_SAFE([balanceModification copy]),
        SPLYT_SAFE(@(isCurrency))
    ];

    [self.core sendDataPoint:@"datacollector_updateCollection" withArgs:args];
}
@end
