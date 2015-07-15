//
//  SplytSession.h
//  Splyt
//
//  Copyright (c) 2013 Row Sham Bow, Inc. All rights reserved.
//

#import <Splyt/SplytConstants.h>
#import <Splyt/SplytInstrumentation.h>

/**
 * @brief A light wrapper around SplytTransaction that makes it easy to report session activity in your app.
 */
@interface SplytSessionTransaction : SplytTransaction
- (void) beginWithTimeout:(NSTimeInterval)timeoutInSecs andMode:(SplytTimeoutMode)mode __attribute__((unavailable("Timeout mode may not be overridden for session transactions")));
@end

/**
 @brief Provides factory methods for creating a SplytSessionTransaction.
 */
@interface SplytSession : NSObject
/**
 Factory method used to create an instance of SplytSessionTransaction.
 
 @return The created SplytSessionTransaction.
 */
- (SplytSessionTransaction*) Transaction;

/**
 Factory method used to create an instance of SplytSessionTransaction.
 
 @param initBlock A callback function that can be used to set the initial properties for the session transaction.
        To do this, call SplytTransaction::setProperty:withValue: or
        SplytTransaction::setProperties: on the instance of SplytSessionTransaction passed to the `initBlock` callback.
 @return The created SplytSessionTransaction.
 */
- (SplytSessionTransaction*) TransactionWithInitBlock:(void (^)(SplytSessionTransaction*)) initBlock;

@end
