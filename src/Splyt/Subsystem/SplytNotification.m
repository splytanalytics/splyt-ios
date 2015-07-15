//
//  SplytNotification.m
//  Splyt
//
//  Created by Justin W. Russell on 12/9/14.
//  Copyright (c) 2014 Row Sham Bow, Inc. All rights reserved.
//

// init Use Cases:
// 1) First time initializing & product is registered with Splyt's notification service
//  - Register with APNS to retrieve a device token
//  - Register device and current entities with Splyt's notification service
//  - Cache off registered device token, entities, and current app version
// 2) First time initializing & product is NOT registered with Splyt's notification service
//  - Cache off current app version
// 3) NOT first time initializing & app version has NOT changed & product is registered with Splyt's notification service & what we have cached off is the latest device token and entities
//  - Do nothing, we're good to go
// 4) NOT first time initializing & app version has NOT changed & product is registered with Splyt's notification service & what we have cached off is NOT the latest device token and/or entities
//  - Reregister the device and current entities with Splyt's notification service
//  - Cache off registered device token and entities
// 5) NOT first time initializing & app version has NOT changed & product is NOT registered with Splyt's notification service
//  - Do nothing, we're good to go
// 6) NOT first time initializing & app version has changed & product is registered with Splyt's notification service & what we have cached off is the latest device token and entities
//  - Cache off current app version
// 7) NOT first time initializing & app version has changed & product is registered with Splyt's notification service & what we have cached off is NOT the latest device token and/or entities
//  - Reregister the device and current entities with Splyt's notification service
//  - Cache off registered device token, entities, and current app version
// 8) NOT first time initializing & app version has changed & product is NOT registered with Splyt's notification service
//  - Cache off current app version

@import UIKit;
#import <Splyt/SplytNotification.h>
#import <Splyt/SplytInternal.h>

// "private" interface
@interface SplytNotification ()
- (void) _registerDevice:(NSString*)curDevToken;
- (void) _receivedNotification:(NSDictionary*)info wasLaunchedBy:(BOOL)launchedBy;
@end

static NSDictionary* _launchNotificationInfo = nil;

static NSString* const Splyt_NOTIFICATION_APPVERSION_KEY_NAME = @"com.splyt.notificationAppVersion";
static NSString* const Splyt_NOTIFICATION_DEVICETOKEN_KEY_NAME = @"com.splyt.notificationDeviceToken";
static NSString* const Splyt_NOTIFICATION_ENTITYIDS_KEY_NAME = @"com.splyt.notificationEntityIds";

static void SplytNotificationDidRegisterForRemoteNotificationsWithDeviceToken(id self, SEL _cmd, UIApplication* app, NSData* curDevToken)
{
    // Convert the token to a hexadecimal string
    // See http://stackoverflow.com/questions/1305225/best-way-to-serialize-a-nsdata-into-an-hexadeximal-string
    const unsigned char* dataBuffer = (const unsigned char*)[curDevToken bytes];
    NSUInteger dataLength = [curDevToken length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];

    for (int byteNum = 0; byteNum < dataLength; ++byteNum) {
        [hexString appendFormat:@"%02lx", (unsigned long)dataBuffer[byteNum]];
    }

    //[SplytUtil logDebug:[NSString stringWithFormat:@"[Notification] SplytNotificationDidRegisterForRemoteNotificationsWithDeviceToken: %@", hexString]];

    // And register the device with Splyt's notification service
    // NOTE that we intentionally do NOT nest here to avoid the NSForwarding warnings about the root Splyt class...
    SplytNotification* notif = [Splyt Notification];
    [notif _registerDevice:hexString];
}

static void SplytNotificationFailToRegisterForRemoteNotificationsWithError(id self, SEL _cmd, UIApplication* app, NSError* error)
{
    // Unexpected error, we'll move along and try again next time we init
    [SplytUtil logError:[NSString stringWithFormat:@"[Notification] Apple Push Service cannot successfully complete the registration process: %@.", [error localizedDescription]]];
}

// 3 circumstances in which we can detect that a notification was received:
// 1) Notification is received when app is running and is in the foreground
//    In this case, SplytNotificationDidReceiveRemoteNotification is called and the UIApplicationState is set to UIApplicationStateActive
//    This is detected this immediately
// 2) Notification is received when app is running but is in the background
//    In this case, iff the user brings the app back into the foreground by pressing on the notification,
//    SplytNotificationDidReceiveRemoteNotification is called and the UIApplicationState is set to UIApplicationStateInactive
//    This is detected once the app returns to the foreground
// 3) Notification received when app is not running
//    In this case, iff the user launches the app by pressing on the notification,
//    The notification userInfo is contained in the launch options dictionary in the key UIApplicationLaunchOptionsRemoteNotificationKey
//    See application:didFinishLaunchingWithOptions and application:willFinishLaunchingWithOptions: in the UIApplicationDelegate Protocol Reference)
//    We detect this in the init method

// This method is called when a notification is delivered when the application is running in the foreground (state = UIApplicationStateActive)
// It also gets called when an app returns to the foreground due to the user touching the notification in the notification center (state = UIApplicationStateInactive)
static void SplytNotificationDidReceiveRemoteNotification(id self, SEL _cmd, UIApplication* app, NSDictionary* userInfo)
{
    [SplytUtil logDebug:@"[Notification] SplytNotificationDidReceiveRemoteNotification"];

    // NOTE that we intentionally do NOT nest here to avoid the NSForwarding warnings about the root Splyt class...
    SplytNotification* notif = [Splyt Notification];
    [notif _receivedNotification:userInfo wasLaunchedBy:(UIApplicationStateActive != app.applicationState)];
}

@implementation SplytNotification {
    NSString* _host;
    NSString* _service;
    SplytNotificationReceivedCallback _notificationReceivedCallback;
}

// "private" class methods
+ (void)_applicationDidFinishLaunching:(NSNotification*)notification
{
    // Called when the UIApplicationDidFinishLaunchingNotification notification is received
    _launchNotificationInfo = [notification.userInfo objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];

    if (nil != _launchNotificationInfo) [SplytUtil logDebug:[NSString stringWithFormat:@"[Notification] Launched with Notification %@", _launchNotificationInfo]];
}

+ (void)_clearNotifications {
    UIApplication* app = [UIApplication sharedApplication];

    BOOL canBadgeApplication = YES;
    if ([app respondsToSelector:@selector(currentUserNotificationSettings)]) {
        // iOS 8+ only, we need to check for badge permissions
        UIUserNotificationSettings* settings = [app currentUserNotificationSettings];
        if (!(settings.types & UIUserNotificationTypeBadge)) {
            // No permission to badge the application
            canBadgeApplication = NO;
        }
    }

    if (canBadgeApplication) {
        // Save off the current badge number so that we can restore it
        NSInteger curBadgeNum = app.applicationIconBadgeNumber;

        // Clear the notifications from the Notification Center
        if (0 != curBadgeNum) {
            [app setApplicationIconBadgeNumber:0];

            // Restore the badge number
            [app setApplicationIconBadgeNumber:curBadgeNum];
        }
        else {
            // The badge number must change for the notifications to clear, so we set it to 1 first
            [app setApplicationIconBadgeNumber:1];
            [app setApplicationIconBadgeNumber:0];
        }
    }
}

// "private" instance methods
- (NSDictionary*) _getCurEntityIds
{
    // Gather the entity info (we need to have some entity to associate this with)
    NSMutableDictionary* curEntityIds = [NSMutableDictionary dictionaryWithCapacity:2];

    if (SPLYT_ISVALIDID(self.core.userId)) {
        [curEntityIds setValue:self.core.userId forKey:SPLYT_ENTITY_TYPE_USER];
    }

    if (SPLYT_ISVALIDID(self.core.deviceId)) {
        [curEntityIds setValue:self.core.deviceId forKey:SPLYT_ENTITY_TYPE_DEVICE];
    }

    return curEntityIds;
}

- (BOOL) _entitiesInSync:(NSDictionary*)curEntityIds {
    // Assume the entities are in sync
    BOOL inSync = YES;

    // The entities are considered NOT in sync if:
    // a) The device Id has changed (we're guaranteed to always have a device Id)
    // OR
    // b) The user Id has changed and is NOT nil
    // That is, even if the user Id is nil, the entities can still be considered to be in sync
    NSDictionary* cachedEntityIds = [[NSUserDefaults standardUserDefaults] dictionaryForKey:Splyt_NOTIFICATION_ENTITYIDS_KEY_NAME];
    NSString* curDeviceId = [curEntityIds valueForKey:SPLYT_ENTITY_TYPE_DEVICE];
    NSString* cachedDeviceId = [cachedEntityIds valueForKey:SPLYT_ENTITY_TYPE_DEVICE];
    if ((nil != curDeviceId) && ![curDeviceId isEqualToString:cachedDeviceId]) {
        inSync = NO;
    }
    else {
        // device Ids are in sync, what about the user Ids?
        NSString* curUserId = [curEntityIds valueForKey:SPLYT_ENTITY_TYPE_USER];
        NSString* cachedUserId = [cachedEntityIds valueForKey:SPLYT_ENTITY_TYPE_USER];
        if ((nil != curUserId) && ![curUserId isEqualToString:cachedUserId]) {
            inSync = NO;
        }
    }

    return inSync;
}

- (BOOL) _cacheDefaults:(NSString*)devToken withEntities:(NSDictionary*)entityIds {
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];

    NSString* curAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [ud setObject:curAppVersion forKey:Splyt_NOTIFICATION_APPVERSION_KEY_NAME];
    if (nil != devToken) [ud setObject:devToken forKey:Splyt_NOTIFICATION_DEVICETOKEN_KEY_NAME];
    if (nil != entityIds) [ud setObject:entityIds forKey:Splyt_NOTIFICATION_ENTITYIDS_KEY_NAME];

    return [ud synchronize];
}

- (void) _registerWithAPNS {
    UIApplication* app = [UIApplication sharedApplication];

    Class appDelegateClass = [app.delegate class];

    // Use dynamic method injection to add the hooks into the app delegate before attempting to register for remote push notifications
    class_replaceMethod(appDelegateClass, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), (IMP)SplytNotificationDidRegisterForRemoteNotificationsWithDeviceToken, "v@:^UIApplication^NSData");
    class_replaceMethod(appDelegateClass, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), (IMP)SplytNotificationFailToRegisterForRemoteNotificationsWithError, "v@:^UIApplication^NSError");
    class_replaceMethod(appDelegateClass, @selector(application:didReceiveRemoteNotification:), (IMP)SplytNotificationDidReceiveRemoteNotification, "v@:^UIApplication^NSDictionary");

    [SplytUtil logDebug:@"[Notification] Registering with APNS"];

    // Now attempt to register with the client and obtain a device token
    // See https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW2
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // iOS 8+ only
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings* mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [app registerUserNotificationSettings:mySettings];
        [app registerForRemoteNotifications];
    }
    else {
        // < iOS 8
        UIRemoteNotificationType types = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert;
        [app registerForRemoteNotificationTypes:types];
    }
}

- (void) _checkProductRegistered {
    NSArray* args = @[_service];

    [self.core sendAsync:_host toApp:@"splyt-notification" andMethod:@"product_isregistered" andWsVersion:@"0" withArgs:args andThen:^(NSDictionary *ssfData) {
        SplytError splytError;

        NSDictionary* data = [self.core getDataFromResponse:ssfData forCall:@(__FUNCTION__) error:&splytError];

        if (SplytError_Success == splytError) {
            // No top-level error, so get the response from the method
            NSDictionary* methodData = [self.core getDataFromResponse:[data objectForKey:@"product_isregistered"] forCall:@(__FUNCTION__) error:&splytError];
            if (SplytError_Success == splytError) {
                BOOL registered = [SPLYT_DYNAMIC_CAST([methodData objectForKey:@"registered"], NSNumber) boolValue];
                if (registered) {
                    // The product is registered with Splyt's notification service.
                    // Now register with Apple's Push Service to retrieve a device token
                    // Use case 1
                    [self _registerWithAPNS];
                }
                else {
                    // Product is not registered with splyt's notification service. This is ok.
                    // Just pass nil for the device token and entities in the defaults
                    // Use case 2 or 8
                    if ([self _cacheDefaults:nil withEntities:nil]) {
                        [SplytUtil logDebug:@"[Notification] Product is not registered with Splyt's notification service"];
                    }
                    else {
                        [SplytUtil logError:@"[Notification] Problem caching defaults"];
                    }
                }
            }
            else {
                [SplytUtil logError:@"[Notification] Problem determining product registration"];
            }
        }
        else {
            // Top-level error
            [SplytUtil logError:@"[Notification] Problem determining product registration"];
        }
    }];
}

- (void) _registerDevice:(NSString*)curDevToken {
    if (nil != curDevToken) {
        // If the current device token matches what we already have cached locally and the current entities are in sync, then we're finished
        // Otherwise, we need to (re)register the device with Splyt's notification service
        NSString* cachedDevToken = [[NSUserDefaults standardUserDefaults] stringForKey:Splyt_NOTIFICATION_DEVICETOKEN_KEY_NAME];
        NSDictionary* curEntityIds = [self _getCurEntityIds];
        if ((nil == cachedDevToken) || ![curDevToken isEqualToString:cachedDevToken] || ![self _entitiesInSync:curEntityIds]) {
            // We need to (re)register the device with Splyt's notification service
            NSArray* args = @[_service, curDevToken, curEntityIds];
            [self.core sendAsync:_host toApp:@"splyt-notification" andMethod:@"device_register" andWsVersion:@"0" withArgs:args andThen:^(NSDictionary *ssfData) {
                SplytError splytError;
                NSDictionary* data = [self.core getDataFromResponse:ssfData forCall:@(__FUNCTION__) error:&splytError];
                if (SplytError_Success == splytError) {
                    // No top-level error, so get the error from the method
                    if (SplytError_Success == [[[data objectForKey:@"device_register"] objectForKey:@"error"] integerValue]) {
                        if ([self _cacheDefaults:curDevToken withEntities:curEntityIds]) {
                            // Success!
                            [SplytUtil logDebug:@"[Notification] Device and associated entities successfully registered with Splyt's notification service"];
                        }
                        else {
                            [SplytUtil logError:@"[Notification] Problem caching defaults"];
                        }
                    }
                    else {
                        // Top-level error
                        [SplytUtil logError:@"[Notification] Problem on device registration"];
                    }
                }
                else {
                    // Top-level error
                    [SplytUtil logError:@"[Notification] Problem on device registration"];
                }
            }];
        }
        else {
            // The device is already registered with Splyt's notification service and the entities are in sync
            // Cache the defaults to make sure the app version is up-to-date
            [SplytUtil logDebug:@"[Notification] Already registered with Splyt"];
            [self _cacheDefaults:nil withEntities:nil];
        }
    }
}

- (void) _receivedNotification:(NSDictionary*)info wasLaunchedBy:(BOOL)launchedBy {
    // If the app was launched by the notification, automatically send an event to the data collector
    if (launchedBy) {
        [[[Splyt Instrumentation] Transaction:@"splyt.launchedbynotification" withInitBlock:^(SplytTransaction *txn) {
            // The splyt portion of the payoad is a JSON-encoded string
            NSString* splytStr = [info objectForKey:@"splyt"];
            if (nil != splytStr) {
                @try {
                    NSError* error;
                    NSDictionary* splytData = [NSJSONSerialization JSONObjectWithData:[splytStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                    if (nil != splytData) {
                        NSString* id = [splytData objectForKey:@"id"];
                        if (nil != id) {
                            [txn setProperty:@"id" withValue:id];
                        }

                        NSString* type = [splytData objectForKey:@"type"];
                        if (nil != type) {
                            [txn setProperty:@"type" withValue:type];
                        }
                    }
                }
                @catch (NSException* e) {
                    NSLog(@"[Notification] JSON deserialization of splyt data failed. Reason: %@", e.reason);
                }
            }
        }] beginAndEnd];
    }

    // Call the callback in case the app has need of the notification info/payload
    if (_notificationReceivedCallback) {
        _notificationReceivedCallback(info, launchedBy);
    }
}

// "package private" instance methods
- (void) preInit:notificationReceivedCallback noAutoClear:(BOOL)disableAutoClear {
    // Set the callback as early as possible
    _notificationReceivedCallback = notificationReceivedCallback;

    if (!disableAutoClear) {
        // Set up the observer needed to detect when the core subsystem resumes so that we can auto-clear notifications from the notification center
        [[NSNotificationCenter defaultCenter] addObserverForName:SPLYT_ACTION_CORESUBSYSTEM_RESUMED object:nil queue:nil usingBlock:^(NSNotification *note) {
            [SplytNotification _clearNotifications];
        }];
    }
}

- (void) init:(NSString*)host {

    //[SplytUtil logDebug:@"[Notification] Init"];

    // If we launched via a notification, go ahead and inform the app now
    // This is the earliest we can do this because the core subsystem needs to have successfully initialized for us to send the "launchedby" transaction
    if (nil != _launchNotificationInfo) {
        [self _receivedNotification:_launchNotificationInfo wasLaunchedBy:YES];

        // Clear the info, we have no more need for it
        _launchNotificationInfo = nil;
    }

    // The iOS simulator (still) doesn't support push notifications, so just bail if we detect that we're running from the simulator
    if (![[[UIDevice currentDevice] model] hasSuffix:@"Simulator"]) {
        _host = [host copy];

        // Assume we're in "production" mode
        _service = @"APNS";

        // Now, let's determine if we're a development build by looking at the provisioning profile.  This seems like a hack but I couldn't find a better way to handle this as a library

        // Refer to http://stackoverflow.com/questions/3426467/how-to-determine-at-run-time-if-app-is-for-development-app-store-or-ad-hoc-dist
        // and https://github.com/blindsightcorp/BSMobileProvision/blob/master/UIApplication%2BBSMobileProvision.m
        // and https://github.com/urbanairship/ios-library/blob/ff89ac317f3907c8c6481af446e6439414529022/Airship/Common/UAConfig.m
        // for examples
        NSString *provisioningPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];

        // Note that there is no provisioning profile in AppStore Apps
        if (provisioningPath) {
            // Read as ASCII due to the binary blocks before and after the plist data
            NSError *err = nil;
            NSString *embeddedProfile = [NSString stringWithContentsOfFile:provisioningPath encoding:NSASCIIStringEncoding error:&err];

            if (nil == err) {
                NSScanner* scanner = [NSScanner scannerWithString:embeddedProfile];
                if ([scanner scanUpToString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>" intoString:nil]) {
                    NSString* plistString = nil;
                    if ([scanner scanUpToString:@"</plist>" intoString:&plistString]) {
                        NSData* data = [[plistString stringByAppendingString:@"</plist>"] dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary* plistDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&err];

                        if (nil == err) {
                            if ([plistDict valueForKeyPath:@"ProvisionedDevices"] && [[plistDict valueForKeyPath:@"Entitlements.get-task-allow"] boolValue]) {
                                // Debug/Development provisioning profile detected, use the APNS Sandbox Servers
                                _service = @"APNS_SANDBOX";
                                [SplytUtil logDebug:@"[Notification] Environment: [APNS_SANDBOX]"];
                            }
                        }
                    }
                }
            }
        }

        // Set up the observer needed for when user entity Ids get set/updated (e.g., on login/logout)
        [[NSNotificationCenter defaultCenter] addObserverForName:SPLYT_ACTION_CORESUBSYSTEM_SETUSERID object:nil queue:nil usingBlock:^(NSNotification *note) {
            // Re-register the device, if necessary
            [self _registerDevice:[[NSUserDefaults standardUserDefaults] stringForKey:Splyt_NOTIFICATION_DEVICETOKEN_KEY_NAME]];
        }];

        // First check if this is our first time initializing (i.e., if we have an app version cached in the user defaults)
        NSString* cachedAppVersion = [[NSUserDefaults standardUserDefaults] stringForKey:Splyt_NOTIFICATION_APPVERSION_KEY_NAME];
        if (nil != cachedAppVersion) {
            // NOT the first time initializing, see if the app version has changed
            NSString* curAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            if ([curAppVersion isEqualToString:cachedAppVersion]) {
                [SplytUtil logDebug:@"[Notification] App version has not changed"];
                // App version has not changed
                // Let's see if we have a device token cached locally
                if (nil != [[NSUserDefaults standardUserDefaults] stringForKey:Splyt_NOTIFICATION_DEVICETOKEN_KEY_NAME]) {
                    // We do so we assume that this product is registered for Splyt's for notification service (no need to hit the server to check)
                    // According to https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW2
                    // "Device tokens can change, so your app needs to reregister every time it is launched."
                    // Hence, we'll retrieve the "latest" device token and see if it matches what we have cached locally.
                    // This path is use case 3 or 4
                    [self _registerWithAPNS];
                }
                else {
                    // No device token cached locally, this product is NOT registered for Splyt's notification service, we're done
                    // This path is use case 5
                    [SplytUtil logDebug:@"[Notification] Product is not registered with Splyt's notification service"];
                }
            }
            else {
                // The app version has changed, let's re-run the check if the product is registered for Splyt's notification service
                // This path is use case 6, 7, or 8
                [SplytUtil logDebug:@"[Notification] App version has changed"];
                [self _checkProductRegistered];
            }
        }
        else {
            // This is the first time we're initializing (or we've never successfully completed initialization before)
            // Let's check if the product is registered for Splyt's notification service
            // This path is use case 1 or 2
            [self _checkProductRegistered];
        }
    }
    else{
        [SplytUtil logError:@"[Notification] iOS Simulator does not support push notifications."];
    }
}

// "public" class methods
+ (void)load {
    // Posted immediately after the app finishes launching.
    // See the UIApplication Class Reference:
    // "If the app was launched as a result of in remote notification targeted at it or because another app opened a URL resource claimed the posting app (the notification object), this notification contains a userInfo dictionary.
    // You can access the contents of the dictionary using the UIApplicationLaunchOptionsURLKey and UIApplicationLaunchOptionsSourceApplicationKey constants (for URLs),
    // the UIApplicationLaunchOptionsRemoteNotificationKey constant (for remote notifications), and the UIApplicationLaunchOptionsLocalNotificationKey constant (for local notifications).
    // If the notification was posted for a normal app launch, there is no userInfo dictionary."
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidFinishLaunching:) name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
}
@end