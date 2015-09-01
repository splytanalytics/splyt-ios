Splyt SDK (iOS)
==============

Splyt is a great way to add analytics functionality to your iOS apps. Splyt provides a full-featured and robust Analytics solution, right out of the box. This is the iOS wrapper for the [Splyt Analytics API](https://www.splyt.com/). The package includes both the **SDK** as well as an **example app project**. Continue reading to learn how to integrate Splyt into your iOS apps.



## What You'll Need
* An XCode iOS app project targeting 7.0 or greater
* An iOS device (or Simulator)
* Internet connectivity



---



## How to do a Quick Demo
If you just want to do a quick test run, open the **example app project** that is included with the SDK and follow these steps:

1. [Create a Splyt account](https://www.splyt.com/signup) and get a **Customer Id**
3. Paste your **Customer Id** into the *initWithCustomerId* method in AppDelegate.m 
4. Run the app on your **device**, and tap the 'start' button.
5. Check the debug console where the API response will appear.



---


## How to Install Splyt in your own App

1. [Create your free Splyt account](https://www.splyt.com/signup) if you don't already have one.
2. Log into the [dashboard](https://www.splyt.com/login) and create a new app.
3. Copy down your **Customer Id** (you'll need it later).
4. [Download](https://github.com/splytanalytics/splyt-ios) the SDK and unzip the package.
5. Open the folder named **SplytSDK** containing the SDK library and header files.
6. Drag the binary (**libSplytSDK.a** or libSplytSDKSimulator.a) into your Xcode project.
7. Drag the folder **Splyt Headers** into your Xcode project.
8. In the "Build Phases" section of your project target, navigate to "**Link Binary with Libraries**" and add libSplytSDK.a to the list (if not already there).
9. While you're still in "Link Binary with Libraries" add the frameworks if not already present: 
	* Foundation.framework


10. **IMPORTANT**: In the "Build Settings" section of your project target, navigate to "Other Linker Flags" and add '**-all_load**' if not already present.
  
11. Import the Splyt.h wherever you want to use the SDK

```
 #import "Splyt.h"
```

## Setting your Customer Id

Before you can make any method calls you'll need to pass Splyt your **Customer Id** (You only need to do this once). Paste your Customer Id into the init method initWithCustomerId:

```
[Splyt initWithCustomerId:@"myCustomerId"];
```



## Function Specific Singletons

The Splyt SDK provides user, device, transaction, and tuning functionality via singleton manager classes, each of which expose instance methods.  Use the following syntax to get a handle to the managers at any time:

```
SplytUserManager *userMgr = [Splyt userManager];

SplytDeviceManager *deviceMgr = [Splyt deviceManager];

SplytTransactionManager *txnMgr = [Splyt transactionManager];

SplytTuningManager *tuningMgr = [Splyt tuningManager];

```
**Note:** *Documentation on the Singleton Manager classes is visible in each classes header file. The header files are located in the folder '**Splyt Headers**'.*


## Special Data Types

The Splyt SDK has a few special data types to be used with some methods:

```
SplytEntityTypeUser - Specifies that the entity is a User.

SplytEntityTypeDevice - Specifies that the entity is a Device.

SplytTransactionModeTXT - Specifies the transaction mode qualifier 'TXN'.

SplytTransactionModeANY - Specifies the transaction mode qualifier 'ANY'.

```
**Note:** *Documentation on the Singleton Manager classes is visible in each classes header file. The header files are located in the folder '**Splyt Headers**'.*

## Timestamps

Most of the methods in the Splyt SDK allow you to send an 'eventTimestamp' recording when an event took place. You may want to use the provided Splyt timestamp method to generate a local UNIX timestamp for convenience:

```
NSString *myTimestamp = [Splyt localTimestamp];

```

---


## Create New User

This method declares that a given user id (userId) is new at the given timestamp (eventTimestamp). Usage enables the New Users and Retention visualizations in the SPLYT dashboard. This method also (optionally )checks whether user exists before creation.

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new user and (optionally) check whether user exists before creation.
     * @param userId User id of new user.
     * @param checkExists Whether to check if user already exists before creating.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt userManager] newUserWithId:myUserId
                           checkExists:NO
                        eventTimestamp:myTimestamp
                               success:^(NSDictionary *response) {
                                   NSLog(@"%@", response);
                             } failure:^(NSDictionary *response) {
                                   NSLog(@"%@", response);
                               }];
```

## Update User

This method can set new properties, or update existing properties of a user.

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Update user.
     * @param userId User id of user to update.
     * @param properties Dictionary of user properties to update user with.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt userManager] updateUserWithId:myUserId
                               properties:myUserProperties
                           eventTimestamp:myTimestamp
                                  success:^(NSDictionary *response) {
                                      NSLog(@"%@", response);
                                } failure:^(NSDictionary *response) {
                                      NSLog(@"%@", response);
                                  }];
```


## Create New Device

This method declares that a given device id (deviceId) is new at the given timestamp (eventTimestamp), or (optionally) should only be marked as new if it was not already. 

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new device and (optionally) check whether device exists before creation.
     * @param deviceId Device id of new device.
     * @param checkExists Whether to check if device already exists before creating.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt deviceManager] newDeviceWithId:myDeviceId
                               checkExists:NO
                            eventTimestamp:myTimestamp
                                   success:^(NSDictionary *response) {
                                       NSLog(@"%@", response);
                                 } failure:^(NSDictionary *response) {
                                       NSLog(@"%@", response);
                                   }];
```



## Update Device

This method can set new properties, or update existing properties of a user. 

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Update device.
     * @param deviceId Device id of device to update.
     * @param properties Dictionary of user properties to update device with.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt deviceManager] updateDeviceWithId:myDeviceId
                                   properties:myDeviceProperties
                               eventTimestamp:myTimestamp
                                      success:^(NSDictionary *response) {
                                          NSLog(@"%@", response);
                                    } failure:^(NSDictionary *response) {
                                          NSLog(@"%@", response);
                                      }];
```


## Begin Transaction

This method begins a new transaction for a given user/device.

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Begin a new transaction.
     * @param timeoutMode Timeout mode (use SplytTimeoutModeTXN or SplytTimeoutModeANY)
     * @param timeoutSeconds Seconds it takes to reach timeout.
     * @param category Category of your transaction.
     * @param properties Dictionary of properties for your transaction.
     * @param transactionId An identifier for your transaction.
     * @param userId The id of a user associated with your transaction.
     * @param deviceId The id of a device associated with your transaction.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt transactionManager] beginTransactionWithTimeoutMode:SplytTimeoutModeTXN
                                                 timeoutSeconds:60
                                                       category:@"purchases"
                                                     properties:@{@"amount" : @"$2.99"}
                                                  transactionId:myTransactionId
                                                         userId:myUserId
                                                       deviceId:@""
                                                 eventTimestamp:myTimestamp
                                                        success:^(NSDictionary *response) {
                                                            NSLog(@"%@", response);
                                                      } failure:^(NSDictionary *response) {
                                                            NSLog(@"%@", response);
                                                        }];
```

## Update Transaction

This method updates a transaction with new properties and a progress. 

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Update a transaction.
     * @param progress Integer representing progress of your transaction (0-99)
     * @param category Category of your transaction.
     * @param properties Dictionary of properties for your transaction.
     * @param transactionId An identifier for your transaction.
     * @param userId The id of a user associated with your transaction.
     * @param deviceId The id of a device associated with your transaction.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt transactionManager] updateTransactionWithProgress:60
                                                     category:@"purchases"
                                                   properties:@{@"amount" : @"$3.99"}
                                                transactionId:myTransactionId
                                                       userId:myUserId
                                                     deviceId:@""
                                               eventTimestamp:myTimestamp
                                                      success:^(NSDictionary *response) {
                                                          NSLog(@"%@", response);
                                                    } failure:^(NSDictionary *response) {
                                                          NSLog(@"%@", response);
                                                      }];
```
## End Transaction

This method ends a transaction for a user and device, optionally updating or adding new properties. This method can also be used to create instantaneous events that start and end in the same call.

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * End a transaction.
     * @param result Description of the result of the transaction. (ex. @"completed")
     * @param category Category of your transaction.
     * @param properties Dictionary of properties for your transaction.
     * @param transactionId An identifier for your transaction.
     * @param userId The id of a user associated with your transaction.
     * @param deviceId The id of a device associated with your transaction.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt transactionManager] endTransactionWithResult:@"complete"
                                                category:@"purchases"
                                              properties:@{}
                                           transactionId:myTransactionId
                                                  userId:myUserId
                                                deviceId:@""
                                          eventTimestamp:[Splyt localTimestamp]
                                                 success:^(NSDictionary *response) {
                                                     NSLog(@"%@", response);
                                               } failure:^(NSDictionary *response) {
                                                     NSLog(@"%@", response);
                                                 }];
```
## Fetch a Tuning Variable

Retrieve the value of a specific tuning variable for an entity.

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Fetch a specified Tuning Variable from the API.
     * @param valueName Name of the tuning variable (ex. 'numBubbles')
     * @param entityId The id of a user or device.
     * @param entityType The entity type (use SplytEntityTypeUser or SplytEntityTypeDevice)
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt tuningManager] valueWithName:@"numBubbles"
                                entityId:myUserId
                              entityType:SplytEntityTypeUser
                          eventTimestamp:[Splyt localTimestamp]
                                 success:^(NSDictionary *response) {
                                     NSLog(@"%@", response);
                               } failure:^(NSDictionary *response) {
                                     NSLog(@"%@", response);
                                 }];
```
## Fetch All Tuning Variables

Retrieve all tuning variables for a specific entity. If no variables exist, the "value" array will be empty. 

```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Fetch all Tuning Variables from the API.
     * @param entityId The id of a user or device.
     * @param entityType The entity type (use SplytEntityTypeUser or SplytEntityTypeDevice)
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt tuningManager] allValuesWithEntityId:myUserId
                                      entityType:SplytEntityTypeUser
                                  eventTimestamp:myTimestamp
                                         success:^(NSDictionary *response) {
                                             NSLog(@"%@", response);
                                       } failure:^(NSDictionary *response) {
                                             NSLog(@"%@", response);
                                         }];
```

## Record a New Tuning Variable

This method allows sending new tuning variables to the Splyt dashboard. The variable will need to be confirmed from the dashboard to become active.


```
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new tuning variable (must be confirmed later in backend)
     * @param valueName Name of the tuning variable (ex. 'numBubbles')
     * @param defaultValue Default value of the new tuning variable (ex. '10')
     * @param userId The id of a user.
     * @param deviceId The id of a device.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt tuningManager] recordValueWithName:@"numLivesOnStart"
                                  defaultValue:@"3"
                                        userId:@""
                                      deviceId:myDeviceId
                                eventTimestamp:myTimestamp
                                       success:^(NSDictionary *response) {
                                           NSLog(@"%@", response);
                                     } failure:^(NSDictionary *response) {
                                           NSLog(@"%@", response);
                                       }];
```

---


## View the Examples

Also see provided example app project **SplytSDKExampleApp** included in the SDK download bundle. It contains clear examples on how to use all of the available methods in the file AppDelegate.m. 


##Support 
Have an issue? Visit our [website](https://www.splyt.com/) or [create an issue on GitHub](https://github.com/splytanalytics/splyt-ios)