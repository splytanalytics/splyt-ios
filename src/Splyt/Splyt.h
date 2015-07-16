//
//  Splyt.h
//  Splyt
//
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

// header guard included here, in the event that consumers of this code try to #include, instead of #import
#ifndef Splyt_Splyt_h
#define Splyt_Splyt_h

#import <Splyt/SplytConstants.h>
#import <Splyt/SplytCore.h>
#import <Splyt/SplytInstrumentation.h>
#import <Splyt/SplytTuning.h>

NS_ROOT_CLASS
/**
 @brief Provides access to singleton instances of classes used to report app activity to SPLYT.
 */
@interface Splyt
/**
 The singleton instance of SplytCore; used to initialize SPLYT and register/set the active user.
 */
+ (SplytCore*) Core;
/**
 The singleton instance of SplytInstrumentation; used to create <a href='SplytTransaction'>transactions</a>
 that describe activity that is unique to your application.  Also used to report updated state information
 about the active user and the device that the app is running on.
 */
+ (SplytInstrumentation*) Instrumentation;
/**
 The singleton instance of SplytTuning; provides access to tuning variables.  Tuning variables are defined
 in SPLYT and can have customized values on a per-user basis, depending on whether the active user of the
 app is participating in an A/B test, or belongs to a segment of users that has been assigned customized
 values for one or more tuning variables.
 */
+ (SplytTuning*) Tuning;
@end

#import <Splyt/SplytSession.h>
#import <Splyt/SplytPurchase.h>

NS_ROOT_CLASS
/**
 @brief Provides access to singleton instances of plugins that are designed to make it easy to report
        common categories of app activity to SPLYT.
 */
@interface SplytPlugins
/** The singleton instance of SplytSession; used to report sessions of activity to SPLYT. */
+ (SplytSession*) Session;
/** The singleton instance of SplytPurchase; used to describe the common characteristics of in-app purchases to SPLYT. */
+ (SplytPurchase*) Purchase;
@end

#endif