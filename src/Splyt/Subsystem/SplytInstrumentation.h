//
//  SplytInstrumentation.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright (c) 2013 Row Sham Bow, Inc. All rights reserved.
//

#import <Splyt/SplytConstants.h>

/**
 @brief Reports activity that is taking place in your app to SPLYT.
 @details You can think of a SplytTransaction as a way of reporting some activity in your app that spans time.
 Here is the common pattern for SplytTransactions:
 
 - When the activity begins, call SplytTransaction::begin: or one of its variants.
 - As the activity proceeds:
   1. Call SplytTransaction::setProperty:withValue: or SplytTransaction::setProperties: to update
      properties of the transaction that reflect the activity's changing state.
   2. Call SplytTransaction::updateAtProgress: to describe how "far along" the activity is.
 - When the activity ends, call SplytTransaction::end:
 */
@interface SplytTransaction : NSObject {
    SplytTimeoutMode _timeoutMode;
    NSTimeInterval _timeout;
    NSString* _category;
    NSString* _transactionId;
    NSMutableDictionary* _state;
}

- (id) init __attribute__((unavailable("Call factory method -Transaction to use a Transaction")));

/** @name Configuration */
/**@{*/
/** 
 Report a single piece of known state about the transaction.
 
 Adding properties to transactions allows you to better understand patterns of activity.
 
 For example, suppose you have an app that lets users read news stories.  If you created a transaction
 with a category named `ViewStory` when a user starts reading a story, you might set a 
 property on that transaction with a key of `NewsCategory`, and with a value describing 
 what type of story it is, for example, `World News`, `Science & Technology`, 
 `Health`, `Entertainment`, etc.  With this property in place, you could
 create a chart that lets you compare news categories and see which types of stories users read
 most.
 
 Finally, note that properties can change as the transaction progresses.  For example, you might have
 a transaction with a category named `Tutorial` that keeps track of a user's progress
 through your app tutorial.  You could add a `LastStepCompleted` property that you update with a new
 value as the user completes each step in your tutorial.
 
 @param key The property name.
 @param value The property value.
 @see SplytTransaction::setProperties:
 */
- (void) setProperty:(NSString*)key withValue:(NSObject *)value;

/** 
 Report any known state about the transaction as a set of key-value pairs.
 
 See SplytTransaction::setProperty:withValue: for a brief discussion of why it is important to add meaningful
 properties to transactions.
 
 @param properties A dictionary of properties that describes the transaction.
 */
- (void) setProperties:(NSDictionary*) properties;
/**@}*/

/** @name Actions */
/**@{*/
/**
 Send telemetry to report the beginning of a transaction.
 
 When beginning a transaction, any properties which have been set (see SplytTransaction::setProperty:withValue: 
 and SplytTransaction::setProperties:) are also included with the data sent to SPLYT.
 
 When calling this method, the transaction will use a default timeout of one hour.  That is, if SPLYT does 
 not receive any updates to this transaction for a period longer than one hour, the transaction is considered
 to have timed out.
 */
- (void) begin;

/**
 Send telemetry to report the beginning of a transaction.
 
 When beginning a transaction, any properties which have been set (see SplytTransaction::setProperty:withValue:
 and SplytTransaction::setProperties:) are also included with the data sent to SPLYT.
 
 @param timeout If SPLYT does not receive any updates to this transaction for a period longer than the 
        timeout interval specified, the transaction is considered to have timed out.
 */
- (void) beginWithTimeout:(NSTimeInterval)timeout;

/**
 Send telemetry to report the beginning of a transaction.
 
 When beginning a transaction, any properties which have been set (see SplytTransaction::setProperty:withValue:
 and SplytTransaction::setProperties:) are also included with the data sent to SPLYT.
 
 @param timeout If SPLYT does not receive any updates to this transaction for a period longer than the
        timeout interval specified, the transaction is considered to have timed out.
 @param mode The type of activity which will keep the transaction open.  
   > *Note: For this release, `SplytTimeoutMode_Default` and `SplytTimeoutMode_Transaction` are the only supported values.*
 */
- (void) beginWithTimeout:(NSTimeInterval)timeout andMode:(SplytTimeoutMode)mode;

/**
 Send telemetry to report the progress of a transaction.
 
 When updating the progress of a transaction, any properties which have been added or changed (see 
 SplytTransaction::setProperty:withValue: and SplytTransaction::setProperties:) are also included
 with the data sent to SPLYT.
 
 @param progress A value between 1 and 99 that describes the percentage progress of this transaction.  You
        should treat progress as a strictly increasing value.  That is, you not should use the same value for
        `progress` multiple calls to SplytTransaction::updateAtProgress:, nor should you use a lower
         value for `progress` than you used in a previous call for the same transaction.
 */
- (void) updateAtProgress:(NSInteger)progress;

/**
 Send telemetry to report the ending of a transaction.  The transaction's result will be reported as ::SPLYT_TXN_SUCCESS .
 
 End a transaction when the activity it describes is complete.
 */
- (void) end;

/**
 Send telemetry to report the ending of a transaction.
 
 @param result A string describing the outcome of the activity described by the transaction.  
 
 Common results include ::SPLYT_TXN_SUCCESS and ::SPLYT_TXN_ERROR, but you may use a custom
 string to describe the transaction's outcome.  For example, if the user cancelled the activity,
 you might report <code>@"cancelled"</code>.
 */
- (void) endWithResult:(NSString*)result;

/**
 Send telemetry to report an instantaneous transaction.
 
 Any properties which have been set (see SplytTransaction::setProperty:withValue: 
 and SplytTransaction::setProperties:) are also included with the data sent to SPLYT.

 "Instantaneous transactions" are analogous to "custom events" in some other analytics systems -- that is, 
 they report an activity as occurring at an instant in time.
 
 > Note: Only use SplytTransaction::beginAndEnd: when modeling some activity that really does occur at a single instant; e.g., "the user clicked a button". In other cases, you should describe the activity as beginning at one moment in time, and ending at some later point in time.  Doing so presents a couple of advantages:
 >
 > 1. SPLYT will calculate the duration of the activity automatically, which is a common measure of user engagement.
 > 2. By describing activities as spanning time, SPLYT can contextualize information about the transaction together with other data you report to SPLYT during the same time period.
 */
- (void) beginAndEnd;

/**
 Send telemetry to report an instantaneous transaction.
 
 @param result A string describing the outcome of the activity described by the transaction.
 
 Common results include ::SPLYT_TXN_SUCCESS and ::SPLYT_TXN_ERROR, but you may use a custom
 string to describe the transaction's outcome.  For example, if the user cancelled the activity,
 you might report <code>@"cancelled"</code>.
 
 See SplytTransaction::beginAndEnd: for a discussion of when you do and don't want to use "instantaneous
 transactions."
 */
- (void) beginAndEndWithResult:(NSString*)result;
/**@}*/
@end

/**
 @brief Provides factory methods for creating <a href="SplytTransaction">custom transactions</a>,
        reporting updated state information about the device that the app is running on,
        and reporting updated state information about the active user.
 */
@interface SplytInstrumentation : NSObject
/**
 Factory method used to create an instance of SplytTransaction.
 
 @param category The category of the created transaction.  Should be a descriptive name for the app
        activity that is modeled by the transaction.
 @return The created SplytTransaction.
 */
- (SplytTransaction*) Transaction:(NSString*)category;

/**
 Factory method used to create an instance of SplytTransaction.
 
 @param category The category of the created transaction.  Should be a descriptive name for the app
        activity that is modeled by the transaction.
 @param transactionId A unique identifier for the created transaction.  This is only required in situations 
        where multiple transactions in the same category may exist for the same user at the same time.
 @return The created SplytTransaction.
 */
- (SplytTransaction*) Transaction:(NSString*)category withId:(NSString*)transactionId;

/**
 Factory method used to create an instance of SplytTransaction.
 
 @param category The category of the created transaction.  Should be a descriptive name for the app
        activity that is modeled by the transaction.
 @param initBlock A callback function that can be used to set the initial properties for the transaction.
         To do this, call SplytTransaction::setProperty:withValue: or 
         SplytTransaction::setProperties: on the instance of SplytTransaction passed to the `initBlock` callback.
 @return The created SplytTransaction.
 */
- (SplytTransaction*) Transaction:(NSString*)category withInitBlock:(void (^)(SplytTransaction*)) initBlock;

/**
 Factory method used to create an instance of SplytTransaction.
 
 @param category The category of the created transaction.  Should be a descriptive name for the app
        activity that is modeled by the transaction.
 @param transactionId A unique identifier for the created transaction.  This is only required in situations
        where multiple transactions in the same category may exist for the same user at the same time.
 @param initBlock A callback function that can be used to set the initial properties for the transaction.
        To do this, call SplytTransaction::setProperty:withValue: or
        SplytTransaction::setProperties: on the instance of SplytTransaction passed to the `initBlock` callback.
 @return The created SplytTransaction.
 */
- (SplytTransaction*) Transaction:(NSString*)category withId:(NSString*)transactionId andInitBlock:(void (^)(SplytTransaction*)) initBlock;

/**
 Updates state information about the device that the app is running on.
 
 @param state A dictionary of properties that describe the current state of the device.
 
 @see SplytCore::deviceId
 */
- (void) updateDeviceState:(NSDictionary *)state;

/**
 Updates state information about the active user.
 
 @param state A dictionary of properties that describe the current state of the active user.
 
 @see SplytCore::userId
 */
- (void) updateUserState:(NSDictionary *)state;

/**
 Updates a collection balance for the active user.
 
 @param name The application-supplied name for the collection.
 @param balance The current balance.
 @param balanceModification The amount that the balance is changing by (if known).
 @param isCurrency `YES` if the collection represents an in-app virtual currency; `NO` otherwise.
 */
- (void) updateCollection:(NSString*)name toBalance:(NSNumber*)balance byAdding:(NSNumber*)balanceModification andTreatAsCurrency:(BOOL)isCurrency;
@end
