//
//  SplytPurchase.m
//  Splyt
//
//  Created by Chris Staymates on 4/25/13.
//  Copyright (c) 2013 Row Sham Bow, Inc. All rights reserved.
//

#import <Splyt/SplytPurchase.h>
#import <Splyt/SplytInternal.h>

// "private" interfaces
@interface SplytPurchaseTransaction ()
- (id) initWithCategory:(NSString*)category andInitBlock:(void(^)(SplytTransaction*)) initBlock __attribute__((unavailable("use initWithId:andInitBlock")));
- (id) initWithId:(NSString*)transactionId andInitBlock:(void(^)(SplytPurchaseTransaction*)) initBlock;
@end

@implementation SplytPurchaseTransaction : SplytTransaction
static NSString* const CATEGORY_NAME = @"purchase";
static const NSTimeInterval DEFAULT_TIMEOUT = 10.0 * 60.0; // 10 minutes

- (id) initWithId:(NSString*)transactionId andInitBlock:(void(^)(SplytPurchaseTransaction*)) initBlock {
    self = [super initWithCategory:CATEGORY_NAME andId:transactionId andInitBlock:nil];
    
    // override some internals before calling init block
    _timeout = DEFAULT_TIMEOUT;
    
    if(initBlock)
        initBlock(self);
    
    return self;
}

- (void) setPrice:(NSNumber*) amount inCurrency:(NSString*)currency {
    if(nil != currency) {
        [_state setObject:@{[SplytUtil getValidCurrencyString:currency]:SPLYT_SAFE(amount)} forKey:@"price"];
        /* ONCE WE ADD LIST SUPPORT TO THE DATA COLLECTOR, SWITCH OUT THIS BLOCK
         NSMutableArray* prices = [_state objectForKey:@"price"];
         if(nil != prices) {
         [prices addObject:@{@"currency":SPLYT_SAFE(currency), @"amount":SPLYT_SAFE(amount)}];
         }
         else {
         [_state setObject:@[@{@"currency":SPLYT_SAFE(currency), @"amount":SPLYT_SAFE(amount)}] forKey:@"price"];
         }
         */
    }
    else {
        [SplytUtil logDebug:@"Currency cannot be nil, ignoring -setPrice"];
    }
}

- (void) setOfferId:(NSString*)offerId {
    [_state setObject:SPLYT_SAFE(offerId) forKey:@"offerId"];
}

- (void) setItemName:(NSString*)itemName {
    [_state setObject:SPLYT_SAFE(itemName) forKey:@"itemName"];
}

- (void) setPointOfSale:(NSString*)pointOfSale {
    [_state setObject:SPLYT_SAFE(pointOfSale) forKey:@"pointOfSale"];

}

@end

@implementation SplytPurchase

- (SplytPurchaseTransaction*) Transaction {
    return [self TransactionWithId:nil andInitBlock:nil];
}
- (SplytPurchaseTransaction*) TransactionWithId:(NSString*)transactionId {
    return [self TransactionWithId:transactionId andInitBlock:nil];
}
- (SplytPurchaseTransaction*) TransactionWithInitBlock:(void(^)(SplytPurchaseTransaction*)) initBlock {
    return [self TransactionWithId:nil andInitBlock:initBlock];
}
- (SplytPurchaseTransaction*) TransactionWithId:(NSString*)transactionId andInitBlock:(void(^)(SplytPurchaseTransaction*)) initBlock {
    SplytPurchaseTransaction *trx = [[SplytPurchaseTransaction alloc] initWithId:transactionId andInitBlock:initBlock];
    trx.core = self.instrumentation.core;
    
    return trx;
}

@end
