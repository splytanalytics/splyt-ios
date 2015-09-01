//
//  AppDelegate.m
//  SplytSDKExampleApp
//
//  Created by Eric Turner on 9/1/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import "AppDelegate.h"
#import "Splyt.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    
    [Splyt initWithCustomerId:@"your-customer-id-here"];
    
    /*
    NSString *myUserId = @"myUserId";
    
    NSString *myDeviceId = @"myDeviceID";
    
    NSString *myTimestamp = [Splyt localTimestamp];
    
    NSDictionary *myUserProperties = @{@"name" : @"Bob", @"age" : @"41"};
    
    NSDictionary *myDeviceProperties = @{@"os" : @"iOS", @"version" : @"8.1"};
    
    NSString *myTransactionId = @"txn0000001234";
     */
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new user and (optionally) check whether user exists before creation.
     * @param userId User id of new user.
     * @param checkExists Whether to check if user already exists before creating.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt userManager] newUserWithId:myUserId
                           checkExists:NO
                        eventTimestamp:myTimestamp
                               success:^(NSDictionary *response) {
                                   NSLog(@"%@", response);
                               } failure:^(NSDictionary *response) {
                                   NSLog(@"%@", response);
                               }];*/
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Update user.
     * @param userId User id of user to update.
     * @param properties Dictionary of user properties to update user with.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt userManager] updateUserWithId:myUserId
                               properties:myUserProperties
                           eventTimestamp:myTimestamp
                                  success:^(NSDictionary *response) {
                                      NSLog(@"%@", response);
                                  } failure:^(NSDictionary *response) {
                                      NSLog(@"%@", response);
                                  }];*/
    
    
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new device and (optionally) check whether device exists before creation.
     * @param deviceId Device id of new device.
     * @param checkExists Whether to check if device already exists before creating.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt deviceManager] newDeviceWithId:myDeviceId
                               checkExists:NO
                            eventTimestamp:myTimestamp
                                   success:^(NSDictionary *response) {
                                       NSLog(@"%@", response);
                                   } failure:^(NSDictionary *response) {
                                       NSLog(@"%@", response);
                                   }];*/
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Update device.
     * @param deviceId Device id of device to update.
     * @param properties Dictionary of user properties to update device with.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt deviceManager] updateDeviceWithId:myDeviceId
                                   properties:myDeviceProperties
                               eventTimestamp:myTimestamp
                                      success:^(NSDictionary *response) {
                                          NSLog(@"%@", response);
                                      } failure:^(NSDictionary *response) {
                                          NSLog(@"%@", response);
                                      }];*/
    
    
    
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
    /*[[Splyt transactionManager] beginTransactionWithTimeoutMode:SplytTimeoutModeTXN
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
                                                        }];*/
    
    
    
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
    /*[[Splyt transactionManager] updateTransactionWithProgress:60
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
                                                      }];*/
    
    
    
    
    
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
    /*[[Splyt transactionManager] endTransactionWithResult:@"complete"
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
                                                 }];*/
    
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Fetch a specified Tuning Variable from the API.
     * @param valueName Name of the tuning variable (ex. 'numBubbles')
     * @param entityId The id of a user or device.
     * @param entityType The entity type (use SplytEntityTypeUser or SplytEntityTypeDevice)
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt tuningManager] valueWithName:@"numBubbles"
                                entityId:myUserId
                              entityType:SplytEntityTypeUser
                          eventTimestamp:[Splyt localTimestamp]
                                 success:^(NSDictionary *response) {
                                     NSLog(@"%@", response);
                                 } failure:^(NSDictionary *response) {
                                     NSLog(@"%@", response);
                                 }];*/
    
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Fetch all Tuning Variables from the API.
     * @param entityId The id of a user or device.
     * @param entityType The entity type (use SplytEntityTypeUser or SplytEntityTypeDevice)
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt tuningManager] allValuesWithEntityId:myUserId
                                      entityType:SplytEntityTypeUser
                                  eventTimestamp:myTimestamp
                                         success:^(NSDictionary *response) {
                                             NSLog(@"%@", response);
                                         } failure:^(NSDictionary *response) {
                                             NSLog(@"%@", response);
                                         }];*/
    
    
    
    
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new tuning variable (must be confirmed later in backend)
     * @param valueName Name of the tuning variable (ex. 'numBubbles')
     * @param defaultValue Default value of the new tuning variable (ex. '10')
     * @param userId The id of a user.
     * @param deviceId The id of a device.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /*[[Splyt tuningManager] recordValueWithName:@"numLivesOnStart"
                                  defaultValue:@"3"
                                        userId:@""
                                      deviceId:myDeviceId
                                eventTimestamp:myTimestamp
                                       success:^(NSDictionary *response) {
                                           NSLog(@"%@", response);
                                       } failure:^(NSDictionary *response) {
                                           NSLog(@"%@", response);
                                       }];*/
    

    return YES;
}


- (void)buttonTapped
{
    
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Create a new user and (optionally) check whether user exists before creation.
     * @param userId User id of new user.
     * @param checkExists Whether to check if user already exists before creating.
     * @param eventTimestamp Time at which event occurred.
     * @return response Dictionary representation of API response.
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    [[Splyt userManager] newUserWithId:@"myNewUser12345"
                           checkExists:YES
                        eventTimestamp:[Splyt localTimestamp]
                               success:^(NSDictionary *response) {
                                   NSLog(@"%@", response);
                               } failure:^(NSDictionary *response) {
                                   NSLog(@"%@", response);
                               }];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
