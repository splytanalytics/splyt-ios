//
//  SplytUserManager.h
//  SplytSDK
//
//  Created by Eric Turner on 8/25/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SplytUserManager : NSObject

+ (instancetype)sharedManager;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Create a new user and (optionally) check whether user exists before creation.
 * @param userId User id of new user.
 * @param checkExists Whether to check if user already exists before creating.
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)newUserWithId:(NSString*)userId
          checkExists:(BOOL)checkExists
       eventTimestamp:(NSString *)eventTimestamp
              success:(void (^)(NSDictionary * response))success
              failure:(void (^)(NSDictionary * response))failure;






/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Update user.
 * @param userId User id of user to update.
 * @param properties Dictionary of user properties to update user with.
 * @param eventTimestamp Time at which event occurred.
 * @return response Dictionary representation of API response.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
-(void)updateUserWithId:(NSString*)userId
             properties:(NSDictionary*)properties
         eventTimestamp:(NSString *)eventTimestamp
                success:(void (^)(NSDictionary * response))success
                failure:(void (^)(NSDictionary * response))failure;





@end
