//
//  SplytTransactionManager.h
//  SplytSDK
//
//  Created by Eric Turner on 8/25/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SplytCommon.h"

@interface SplytTransactionManager : NSObject


+ (instancetype)sharedManager;

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
- (void)beginTransactionWithTimeoutMode:(SplytTimeoutMode)timeoutMode
                         timeoutSeconds:(NSInteger)timeoutSeconds
                               category:(NSString *)category
                             properties:(NSDictionary *)properties
                          transactionId:(NSString *)transactionId
                                 userId:(NSString *)userId
                               deviceId:(NSString *)deviceId
                         eventTimestamp:(NSString *)eventTimestamp
                                success:(void (^)(NSDictionary * response))success
                                failure:(void (^)(NSDictionary * response))failure;



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
- (void)updateTransactionWithProgress:(NSInteger)progress
                             category:(NSString *)category
                           properties:(NSDictionary *)properties
                        transactionId:(NSString *)transactionId
                               userId:(NSString *)userId
                             deviceId:(NSString *)deviceId
                       eventTimestamp:(NSString *)eventTimestamp
                              success:(void (^)(NSDictionary * response))success
                              failure:(void (^)(NSDictionary * response))failure;





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
- (void)endTransactionWithResult:(NSString *)result
                        category:(NSString *)category
                      properties:(NSDictionary *)properties
                   transactionId:(NSString *)transactionId
                          userId:(NSString *)userId
                        deviceId:(NSString *)deviceId
                  eventTimestamp:(NSString *)eventTimestamp
                         success:(void (^)(NSDictionary * response))success
                         failure:(void (^)(NSDictionary * response))failure;


@end
