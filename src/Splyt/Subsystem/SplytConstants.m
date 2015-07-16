//
//  SplytConstants.m
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytConstants.h>

/**
 @defgroup Constants Transaction Results
 @brief Predefined strings that can be used to describe the end result of a transaction.
 */
/**@{*/

/** A default result string that can be used to indicate a successful transaction completion. */
NSString* const SPLYT_TXN_SUCCESS = @"success";

/** A default result string that can be used to indicate an unsuccessful transaction completion. */
NSString* const SPLYT_TXN_ERROR = @"error";

/** A string that indicates than an entity represents a user. Clients should not normally need to make direct use of this constant when using a SPLYT SDK. */
NSString* const SPLYT_ENTITY_TYPE_USER = @"USER";

/** A string that indicates than an entity represents a device. Clients should not normally need to make direct use of this constant when using a SPLYT SDK. */
NSString* const SPLYT_ENTITY_TYPE_DEVICE = @"DEVICE";

/** A string representing the notification name of the NSNotification that is posted any time the user Id is set in the core subsystem. */
NSString* const SPLYT_ACTION_CORESUBSYSTEM_SETUSERID = @"Splyt.CoreSubsystem.SetUserId";

/** A string representing the notification name of the NSNotification that is posted any time the resume method of core subsystem is called. */
NSString* const SPLYT_ACTION_CORESUBSYSTEM_RESUMED = @"Splyt.CoreSubsystem.Resumed";

/**@}*/
