//
//  SplytCommon.h
//  SplytSDK
//
//  Created by Eric Turner on 8/25/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    SplytEntityTypeUser,
    SplytEntityTypeDevice
} SplytEntityType;

typedef enum {
    SplytTimeoutModeTXN,
    SplytTimeoutModeANY
} SplytTimeoutMode;



/*!
 A more thorough emptyness test
 @params thing : a general object (strings, arrays, dictionaries)
 */
BOOL IsEmpty(id thing);

NSString * SPLTimestamp();

NSString * SPLTimeoutModeStringFromTimeoutMode(SplytTimeoutMode mode);


NSString * SPLEntityTypeStringFromEntityType(SplytEntityType type);

// returns the type string if the type matches the provided type
NSString * SPLEntityIdIfType(NSString *entityId, SplytEntityType type, SplytEntityType expectedType);

NSString * SPLTimeUTC(NSDate *date);

NSString * SPLTimeLocal(NSDate *date);

NSString * SPLTimezone();

NSNumber * SPLTimezoneOffset(NSDate *date);

NSNumber * SPLTimeIsDaylightSavings();


/** Case insensitive String Compare ***/
BOOL SPLStringEqualsString(NSString *stringA, NSString *stringB);

/** Determine error or successful **/
BOOL SPLIsResponseSuccessful(NSDictionary *responseDict);

/*!
 Device Model (iPhone, iPad, etc)
 */
NSString * SPLDeviceModel();

/*!
 Build number
 */
NSString* SPLBuildNumber();

/*!
 iOS Version
 */
NSString * SPLiOSVersion();

/*!
 App Version
 */
NSString * SPLAppVersion();

