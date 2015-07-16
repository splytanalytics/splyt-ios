//
//  SplytCore.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytConstants.h>

/**
 @brief A helper class used during initialization of SPLYT.  Describes the active user or device.
 @details Use the factory methods SplytEntityInfo::createUserInfo: or SplytEntityInfo::createDeviceInfo:
          to create an instance of this class.
 */
@interface SplytEntityInfo : NSObject
/**
 Factory method for creating an instance of SplytEntityInfo for a user.
 @param userId The user ID.
 @return A populated SplytEntityInfo.
 */
+ (SplytEntityInfo*) createUserInfo:(NSString*)userId;

/**
 Factory method for creating an instance of SplytEntityInfo for a user.
 @param userId The user ID.
 @param initBlock A callback function that can be used to set initial user properties.  To do this,
        call SplytEntityInfo::setProperty:withValue: or SplytEntityInfo::setProperties: from inside the callback.
 @return A populated SplytEntityInfo.
 */
+ (SplytEntityInfo*) createUserInfo:(NSString*)userId withInitBlock:(void (^)(SplytEntityInfo*)) initBlock;

/**
 Factory method for creating an instance of SplytEntityInfo for a device.
 @return A populated SplytEntityInfo.
 */
+ (SplytEntityInfo*) createDeviceInfo;

/**
 Factory method for creating an instance of SplytEntityInfo for a device.
 @param initBlock A callback function that can be used to set initial device properties.  To do this,
        call SplytEntityInfo::setProperty:withValue: or SplytEntityInfo::setProperties: from inside the callback.
 @return A populated SplytEntityInfo.
 */
+ (SplytEntityInfo*) createDeviceInfoWithInitBlock:(void (^)(SplytEntityInfo*)) initBlock;

- (id) init __attribute__((unavailable("Use factory methods +createUserInfo or +createDeviceInfo to init a SplytEntityInfo")));

/**
 Overrides the user or device ID.
 Normally, this is only used in the case where an application wants specific control over device IDs, which SPLYT auto-generates by default.
 @param entityId The user or device ID to report to SPLYT.
 */
- (void) overrideId:(NSString*)entityId;

/**
 Report that this entity is a new user or device.
 Normally, SPLYT auto-detects new users or devices based on whether it has previously seen their IDs.  This method
 allows you to override the auto-detection and explicitly control whether the entity will be counted as a new
 user or device.
 @param isNew <code>YES</code> if the user or device is to be treated as new; otherwise, <code>NO</code>.
 */
- (void) setIsNew:(BOOL)isNew;

/**
 Set a single property of user or device state.
 @param key Key for user or device property.
 @param value Value for user or device property.
*/
- (void) setProperty:(NSString*)key withValue:(NSObject*)value;

/**
 Set multiple properties of user or device state.
 @param values A dictionary of user or device properties.
 */
- (void) setProperties:(NSDictionary*)values;
@end

/**
 @brief A helper class used during initialization of SPLYT.  Encapsulates the initialization properties associated with SPLYT's push notification service
 @details Do not instaniate this class.  Instead use one of the factory methods in SplytInitParams and access the initialization properties through the SplytInitParams instance.
 */
@interface SplytNotificationInitParams : NSObject
/**
 A URL that specifies the protocol and hostname to be used when interacting with SPLYT's push notification service (default: https://notification.splyt.com).
 This value does not normally need to be changed.
 */
@property (strong) NSString* host;

/**
 A block (callback) invoked when Splyt detects that a notification is received
 */
@property (copy) SplytNotificationReceivedCallback receivedCallback;

/**
 Set whether or not we always want to disable the feature that automatically clears this app's notifications from the notification center
 when the app is brought into the foreground (default: NO).
 */
@property BOOL disableAutoClear;
@end

/**
 @brief A helper class that provides information used to initialize SPLYT.
 @details Use the factory methods SplytInitParams::createWithCustomerId: or
          SplytInitParams::createWithCustomerId:andInitBlock: to create an instance of this class.

 @see SplytCore::init:andThen:
 */
@interface SplytInitParams : NSObject
/**
 Creates an instance of SplytInitParams with the specified customer ID.
 @param customerId The customer ID.
        This is a unique string that associates the data you send with a specific product's dashboards in SPLYT.
        Note that the customer ID must be set up in SPLYT's web application beforehand, or else the data will not
        be saved.  If you do not know your customer ID, contact SPLYT support: support@splyt.com.
 @return The new instance of SplytInitParams.
 */
+ (SplytInitParams*) createWithCustomerId:(NSString*)customerId;

/**
 Creates an instance of SplytInitParams with the specified customer ID.
 @param customerId The customer ID.
        This is a unique string that associates the data you send with a specific product's dashboards in SPLYT.
        Note that the customer ID must be set up in SPLYT's web application beforehand, or else the data will not
        be saved.  If you do not know your customer ID, contact SPLYT support: support@splyt.com.
 @param initBlock A callback function that can be used to set initial SPLYT parameters.
        To do this, modify properties of the SplytInitParams passed to the initBlock callback.
 @return The new instance of SplytInitParams.
 */
+ (SplytInitParams*) createWithCustomerId:(NSString*)customerId andInitBlock:(void (^)(SplytInitParams*)) initBlock;

- (id) init __attribute__((unavailable("Use factory method +createWithCustomerId to init a SplytInitParams")));

/**
 Describes the device that the current app instance is running on.
 If left <code>nil</code>, SPLYT will use a randomly generated identifier for the device and
 automatically determine whether this is a new device that is running the app for the first time.
 */
@property (strong) SplytEntityInfo* deviceInfo;

/**
 Describes the user of the current app instance.
 */
@property (strong) SplytEntityInfo* userInfo;

/**
 The timeout interval, in milliseconds (default: 1500 milliseconds).
 If during a connection attempt the request remains idle for longer than the timeout interval,
 the request is considered to have timed out.
 */
@property NSInteger requestTimeout;

/**
 A URL that specifies the protocol and hostname to be used when sending data to SPLYT (default: https://data.splyt.com).
 This value does not normally need to be changed.
 */
@property (strong) NSString* host;

/**
 Specifies whether or not SPLYT should log informational and error messages using NSLog (default: NO).
 */
@property BOOL logEnabled;

/**
 Initialization parameters specific to SPLYT's push notification service
 */
@property (nonatomic, readonly) SplytNotificationInitParams* notification;
@end

/**
 @brief The most central pieces of the SPLYT framework.
 */
@interface SplytCore : NSObject
/**
 Initializes the SPLYT framework for use, including instrumentation, tuning, and (optionally) notification.
 @param params Initialization parameters
 @param callback Application-defined callback which will occur on completion
 */
- (void) init:(SplytInitParams*)params andThen:(SplytCallback)callback;

/**
 Register a user with SPLYT and make them the currently active user.
 This can be done at any point when a new user is interacted with by the application. Note
 that if the active user is known at startup, it is generally ideal to provide their info
 directly to SplytCore::init:andThen: instead.
 @param userInfo A SplytEntityInfo created with SplytEntityInfo::createUserInfo: or SplytEntityInfo::createUserInfo:withInitBlock:
 @param callback Application-defined callback which will occur on completion
 */
- (void) registerUser:(SplytEntityInfo*)userInfo andThen:(SplytCallback)callback;

/**
 Explicitly sets the active user ID. Generally only required when multiple concurrent users are
 required/supported, since SplytCore::init:andThen: and SplytCore::registerUser:andThen:
 both activate the provided user by default.
 @param userId The user ID, which had been previously registered with SplytCore::registerUser:andThen:
 @return A SplytError enum that describes whether an error occurred.
 */
- (SplytError) setActiveUser:(NSString*)userId;

/**
 Clears the active user ID.
 Useful when the logged in user logs out of the application.  Clearing the active user allows SPLYT to
 provide non user-specific tuning values and report telemetry which is not linked to a user.
 @return A SplytError enum that describes whether an error occurred.
 */
- (SplytError) clearActiveUser;

/**
 Pauses SPLYT. This causes SPLYT to save off its state to internal storage and stop checking for events to send.
 One would typically call this whenever the application is sent to the background.
 @note One can still make calls to SPLYT functions even when it's paused, but doing so will trigger
       reads and writes to internal storage, so it should be done judiciously.
 */
- (void) pause;

/**
 Resumes SPLYT. This causes SPLYT read its last known state from internal storage and restart polling for events to send.
 One would typically call this whenever the application is brought to the foreground.
 */
- (void) resume;

/**
 Gets the registered ID of the active user.
 */
@property (nonatomic, copy, readonly) NSString* userId;

/**
 Gets the registered ID of the device.
 */
@property (nonatomic, copy, readonly) NSString* deviceId;
@end
