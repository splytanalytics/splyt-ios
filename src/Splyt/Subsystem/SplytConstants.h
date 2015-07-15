//
//  SplytConstants.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright (c) 2013 Row Sham Bow, Inc. All rights reserved.
//

@import Foundation;

/** A default result string that can be used to indicate a successful transaction completion. */
extern NSString* const SPLYT_TXN_SUCCESS;

/** A default result string that can be used to indicate an unsuccessful transaction completion. */
extern NSString* const SPLYT_TXN_ERROR;

/**
 @defgroup SplytTimeoutMode Transaction Time Out Modes
 @brief The time out modes that may be specified when beginning a transaction.
 @see SplytTransaction::beginWithTimeout:andMode:
 */
/**@{*/
typedef NS_ENUM(NSUInteger, SplytTimeoutMode) {
    SplytTimeoutMode_Transaction, /**< The transaction will be kept "open" only by direct updates to the transaction itself. */
    SplytTimeoutMode_Any,         /**< The transaction will be kept "open" by updates to *any* transaction for the current device or user <i>(Note: not yet supported)</i>. */
    
    SplytTimeoutMode_Count,
    
    SplytTimeoutMode_Default = SplytTimeoutMode_Transaction /**< The default timeout mode (same as ::SplytTimeoutMode_Transaction). */
};
/**@}*/

/**
 @defgroup SplytError SPLYT Errors
 @brief Error codes that may be returned from the SPLYT framework APIs.
 */
/**@{*/
typedef NS_ENUM(NSInteger, SplytError) {
    SplytError_Success = 0,              /**< Success (no error). */
    SplytError_Generic = -1,             /**< An unspecified error occurred. */
    SplytError_NotInitialized = -2,      /**< SPLYT has not been initialized. */
    SplytError_AlreadyInitialized = -3,  /**< SPLYT has already been initialized. */
    SplytError_InvalidArgs = -4,         /**< Invalid arguments were passed to a method. */
    SplytError_MissingId = -5,           /**< The device or user ID is missing or invalid. */
    SplytError_RequestTimedOut = -6      /**< A web request timed out. */
};
/**@}*/

typedef void (^SplytCallback)(SplytError error);
/**
@param info A dictionary that contains information related to the remote notification
@param wasLaunchedBy YES if the app was launched by the notification, NO otherwise
 */
typedef void (^SplytNotificationReceivedCallback)(NSDictionary* info, BOOL wasLaunchedBy);
