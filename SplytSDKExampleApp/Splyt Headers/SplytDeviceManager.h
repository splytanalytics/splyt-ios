//
//  SplytDeviceManager.h
//  SplytSDK
//
//  Created by Eric Turner on 8/26/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SplytDeviceManager : NSObject

+ (instancetype)sharedManager;



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Create a new device and (optionally) check whether device exists before creation.
 * @param deviceId Device id of new device.
 * @param checkExists Whether to check if device already exists before creating.
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)newDeviceWithId:(NSString*)deviceId
            checkExists:(BOOL)checkExists
         eventTimestamp:(NSString *)eventTimestamp
                success:(void (^)(NSDictionary * response))success
                failure:(void (^)(NSDictionary * response))failure;






/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Update device.
 * @param deviceId Device id of device to update.
 * @param properties Dictionary of user properties to update device with.
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
-(void)updateDeviceWithId:(NSString*)deviceId
               properties:(NSDictionary*)properties
           eventTimestamp:(NSString *)eventTimestamp
                  success:(void (^)(NSDictionary * response))success
                  failure:(void (^)(NSDictionary * response))failure;





@end
