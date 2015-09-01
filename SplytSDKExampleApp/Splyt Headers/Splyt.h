//
//  SplytSDK.h
//  SplytSDK
//
//  Created by Eric Turner on 8/25/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SplytTransactionManager.h"
#import "SplytTuningManager.h"
#import "SplytDeviceManager.h"
#import "SplytUserManager.h"

@interface Splyt : NSObject

#pragma mark - SINGLETONS -
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
 * * * * * * * * * * * SINGLETONS * * * * * * * * * * * * * * * * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*
 * @return Splyt instance and initializes SDK.
 */
+ (void)initWithCustomerId:(NSString*)customerId;


/*
 * @return User Manager singleton.
 */
+ (SplytUserManager*)userManager;


/*
 * @return Device Manager singleton.
 */
+ (SplytDeviceManager*)deviceManager;



/*
 * @return Tuning Manager singleton.
 */
+ (SplytTuningManager*)tuningManager;


/*
 * @return Transaction Manager singleton.
 */
+ (SplytTransactionManager*)transactionManager;



#pragma mark - CONVENIENCE -

/*
 * @return unix timestamp in local time.
 */
+ (NSString*)localTimestamp;



@end
