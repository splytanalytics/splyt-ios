//
//  SplytTuningManager.h
//  SplytSDK
//
//  Created by Eric Turner on 8/25/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SplytCommon.h"

@interface SplytTuningManager : NSObject


+ (instancetype)sharedManager;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Fetch a specified Tuning Variable from the API.
 * @param valueName Name of the tuning variable (ex. 'numBubbles')
 * @param entityId The id of a user or device.
 * @param entityType The entity type (use SplytEntityTypeUser or SplytEntityTypeDevice)
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
-(void)valueWithName:(NSString *)valueName
            entityId:(NSString *)entityId
          entityType:(SplytEntityType)entityType
      eventTimestamp:(NSString *)timestamp
             success:(void (^)(NSDictionary * response))success
             failure:(void (^)(NSDictionary * response))failure;






/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Fetch all Tuning Variables from the API.
 * @param entityId The id of a user or device.
 * @param entityType The entity type (use SplytEntityTypeUser or SplytEntityTypeDevice)
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
-(void)allValuesWithEntityId:(NSString *)entityId
                  entityType:(SplytEntityType)entityType
              eventTimestamp:(NSString *)timestamp
                     success:(void (^)(NSDictionary * response))success
                     failure:(void (^)(NSDictionary * response))failure;






/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Create a new tuning variable (must be confirmed later in backend)
 * @param valueName Name of the tuning variable (ex. 'numBubbles')
 * @param defaultValue Default value of the new tuning variable (ex. '10')
 * @param userId The id of a user.
 * @param deviceId The id of a device.
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)recordValueWithName:(NSString *)valueName
               defaultValue:(NSString *)defaultValue
                     userId:(NSString *)userId
                   deviceId:(NSString *)deviceId
             eventTimestamp:(NSString *)timestamp
                    success:(void (^)(NSDictionary * response))success
                    failure:(void (^)(NSDictionary * response))failure;






@end
