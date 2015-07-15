Getting Started
=========

Last Updated: February 10, 2014

##Singleton Instances

Singleton instances of the SPLYT framework classes that you'll use most often are available through the Splyt class:

    [Splyt Core];             // Provides access to the SplytCore singleton
    [Splyt Instrumentation];  // Provides access to the SplytInstrumentation singleton
    [Splyt Tuning];           // Provides access to the SplytTuning singleton
    [SplytPlugins Purchase];  // Provides access to the SplytPurchase singleton
    [SplytPlugins Session];   // Provides access to the SplytSession singleton

See the BubblePop sample in the `samples` subfolder of the SDK for examples of how these singletons get used in an app.  To get started with that sample, refer to [our walkthrough](md_sample-walkthrough_sample-walkthrough.html).

##Initialization
SPLYT initialization should be completed as early as possible in the flow of an application. This allows 
telemetry reporting and the usage of SPLYT tuned variables throughout the application. 

For iOS apps, the logical spot to initialize SPLYT is often in your app delegate's `application:didFinishLaunchingWithOptions:` method.

Note that the initialization call triggers a callback upon completion, after which point you can reliably use any of the other calls in the SPLYT SDK. Here's an example, passing ::SplytInitParams to SplytCore::init:andThen:

    // contact SPLYT if you do not have a customer ID
    SplytInitParams* initParams = [SplytInitParams createWithCustomerId:@"my-customer-id"
                                                           andInitBlock:^(SplytInitParams *init) {
                                                               
        // If you have additional information about your user or device to report at startup, you can.
        init.userInfo = myUserInfo;              // See the next section for more about user
        init.deviceInfo = myDeviceInfo;          // and device entities.
                                                               
    }];

    [[Splyt Core] init:initParams andThen:^(SplytError error) {
        if (SplytError_Success != error) {
            NSLog(@"SPLYT initialization failed with error %ld. Instrumentation and tuning may not work as expected.", (long) error);
        }
        
        [[[SplytPlugins Session] Transaction] begin];
    }];

###Devices
SPLYT will automatically track some hardware information about your device, but if you have additional (perhaps application-specific) properties to report, you can do so at initialization time.  To do this, use SplytEntityInfo::createDeviceInfo: or SplytEntityInfo::createDeviceInfoWithInitBlock: to create an info object that describes the device, and then use that object as the value of SplytInitParams.deviceInfo :

    SplytInitParams* initParams = [SplytInitParams createWithCustomerId:@"my-customer-id" 
                                                           andInitBlock:^(SplytInitParams *init) {

        init.userInfo = [SplytEntityInfo createUserInfo:self.currentUser.id];
        
        init.deviceInfo = [SplytEntityInfo createDeviceInfoWithInitBlock:^(SplytEntityInfo *device) {
        	[device setProperty:@"screen_orientation" withValue:@"landscape"];
        	[device setProperty:@"uiwebview_useragent" withValue:[webView stringByEvaluatingJavaScriptFromString:"@navigator.userAgent"]];    	
        }];    
    }];

To report any changes to the state of the device at any later point, see SplytInstrumentation::updateDeviceState:.

###Users
Many applications track individual users with some form of user ID. For such applications, if you know the user ID at startup, it is recommended to set `userInfo` in the callback for SplytCore::init:andThen:.

An example of this can be seen in previous code snippet.  That example uses SplytEntityInfo::createUserInfo: to create a `userInfo` that includes a user ID.

If you have additional user state, you may use SplytEntityInfo::createUserInfo:withInitBlock: together with SplytEntityInfo::setProperty:withValue: or SplytEntityInfo::setProperties: to set up an object that includes that additional state:

    SplytInitParams* initParams = [SplytInitParams createWithCustomerId:@"my-customer-id" 
                                                           andInitBlock:^(SplytInitParams *init) {

        init.userInfo = [SplytEntityInfo createUserInfo:self.currentUser.id withInitBlock:^(SplytEntityInfo *user) {
            [user setProperty:@"gender" withValue:@"male"];
            [user setProperty:@"publicProfile" withValue:@"true"];      
        }];        
    }];

If the user is *not* known at startup, they can be registered at a later point by creating a SplytEntityInfo instance in the same fashion as above and then passing it to SplytCore::registerUser:andThen:

    [[Splyt Core] registerUser:[SplytEntityInfo createUserInfo:self.currentUser.id]
                       andThen:^(SplytError error) {
        // The app may now safely log telemetry and use tuned variables for the user
    }];

Additional notes:

* For applications which allow multiple concurrent users, see SplytCore::setActiveUser:
* For applications which need to support users "logging out", see SplytCore::clearActiveUser:
* To report any changes to the state of the user at any later point, see SplytInstrumentation::updateUserState:

##Telemetry
###Transactions
Transactions are the primary unit of telemetry in SPLYT. Reporting events with a SplytTransaction is simple, but powerful. Consider:

    SplytTransaction* gameTxn = [[Splyt Instrumentation] Transaction:@"play_game"];
    [gameTxn begin];

    // Time passes...

    [gameTxn setProperty:@"something interesting" withValue:@"about the transaction"];
    [gameTxn end];

Note that properties of the transaction may be set at the beginning or end of the transaction, or at any point in between as part of an `updateAtProgress`, but as a best practice, transaction properties should be reported as early as their value is known or known to have changed.

To handle the somewhat common case where a transaction occurs instantaneously, use the SplytTransaction::beginAndEnd method.

Also note that the setting of transaction properties is only persisted after a call to one of the `begin`, `updateAtProgress`, `end`, or `beginAndEnd` methods of SplytTransaction.

###Collections
Collections in SPLYT are an abstraction for anything the user of the application might accumulate or have a varying quantity of. Common examples of this might be virtual currency, number of contacts, or achievements. SplytInstrumentation::updateCollection:toBalance:byAdding:andTreatAsCurrency: can be used at any point where the quantity
of a collection is known to have changed:

    [[Splyt Instrumentation] updateCollection:@"friendCount"
                                    toBalance:@27
                                     byAdding:@-2
                           andTreatAsCurrency:NO];

It is recommended to instrument all of the important collections in the application, as they will add surprising power to your data analysis through contextualization.

###Entity State
As previously mentioned, users and devices (commonly referred to as "entities" in SPLYT) may have their state recorded during initialization, or at a later point in the app by calling SplytInstrumentation::updateUserState: or SplytInstrumentation::updateDeviceState:, respectively. Reporting
changes in entity state is another great way to unlock the power of contextualization.

##Tuning
SPLYT's tuning system provides a means for dynamically altering the behavior of the application, conducting an A/Z test, and creating customized behavior for segments of your user base (targeting).  The instrumentation is very simple, and the hardest part might be deciding what you want to be able to tune. When initialized, SPLYT will retrieve any dynamic tuning for the device or user. At any point thereafter, the application may request a value using SplytTuning::getVar:orDefaultTo:

    // before SPLYT
    NSString *welcomeString = @"Hi there!";
    NSNumber *welcomeDuration = @3.0;

    // with SPLYT tuning variables
    NSString *welcomeString = Tuning.getVar("welcomeString", "Hi there!");
    NSNumber *welcomeDuration = Tuning.getVar("welcomeTime", 3.0);

Note that we specify a default value using the `orDefaultTo` parameter. It is important to provide a "safe" default value to provide reliable behavior in the event that a dynamic value is not available. This also allows for the application to be safely instrumented in advance of any dynamic tuning, targeting, or A/Z test.

In addition to instrumenting key points in your code with SplytTuning::getVar:orDefaultTo:, applications which may remain running for long periods of time are encouraged to utilize SplytTuning::refreshAndThen: in order to make sure that the application has access to the latest tuned values at any point in time. A typical integration point for `refreshAndThen:` on a mobile app might be whenever the application is brought to the foreground, and the code for handling it is quite simple:

    [[Splyt Tuning] refreshAndThen:^(SplytError error) {
        // At this point, tuning for the device and any and all registered users should be refreshed.
    }];

It is not necessary to block for the completion of this call, as is typically recommended for SplytCore::init:andThen:
and SplytCore::registerUser:andThen:, since the application should already have access to viable tuned variables prior to the call to
`refreshAndThen:`.  However, the callback is provided, leaving it to the discretion of the integrator.

##Mobile Apps
For mobile apps, it is likely that the app may come active and inactive many times during it's lifetime. In addition, it is best practice to ensure that applications can function properly under poor network conditions, or even when the device has no network connection. In order to support these characteristics, the SPLYT SDK is designed to protect your telemetry in these situations. However, there's a small bit that needs to be done by the implementor.

When the application is becoming inactive, call SplytCore::pause.  For example, the BubblePop sample does the following from the app delegate's `applicationWillResignActive` method:

    -(void) applicationWillResignActive:(UIApplication *)application {
        [[Splyt Core] pause];
        
        // other, non-SPLYT code.
    }

And then when it becomes active again, call SplytCore::resume :

    -(void) applicationDidBecomeActive:(UIApplication *)application {
        [[Splyt Core] resume];
        
        // other, non-SPLYT code.
    }

If necessary, you can still report telemetry while SPLYT is in a paused state, but the telemetry calls may execute more slowly, due to data being read and written from the device's local storage.