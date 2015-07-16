//
//  SplytInternal.h
//  Splyt
//
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/Splyt.h>
#import <Splyt/SplytCore.h>
#import <Splyt/SplytTuning.h>
#import <Splyt/SplytInstrumentation.h>
#import <Splyt/SplytNotification.h>
#import <Splyt/SplytSession.h>
#import <Splyt/SplytPurchase.h>

#import <Splyt/SplytUtil.h>

#include <objc/runtime.h>

// "package private" constants & interfaces
// See https://developer.apple.com/library/ios/documentation/cocoa/conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html

#define SPLYT_SAFE(_val) ((nil == (_val)) ? [NSNull null] : (_val))
#define SPLYT_ISVALIDID(_id) ((nil != (_id)) && [(_id) isKindOfClass:[NSString class]] && ![(_id) isEqual:@""])
#define SPLYT_DYNAMIC_CAST(_obj, _cls) ([_obj isKindOfClass:(Class)objc_getClass(#_cls)] ? (_cls *)_obj : nil)

extern NSString* const SPLYT_ENTITY_TYPE_DEVICE;
extern NSString* const SPLYT_ENTITY_TYPE_USER;
extern NSString* const SPLYT_ACTION_CORESUBSYSTEM_SETUSERID;
extern NSString* const SPLYT_ACTION_CORESUBSYSTEM_RESUMED;

@interface Splyt()
+ (SplytNotification*) Notification;
@end

typedef void(^SplytDataHandler)(NSDictionary *ssfData);

@interface SplytCore ()
@property (nonatomic) SplytInstrumentation* instrumentation;
@property (nonatomic) SplytNotification* notification;
@property (nonatomic) SplytTuning* tuning;
@property (nonatomic, copy) NSString* userId;
@property (nonatomic, copy) NSString* deviceId;
@property (strong, readonly) NSSet* registeredUsers;

- (void) sendDataPoint:(NSString*)method withArgs:(NSArray*)args;
- (NSDictionary*) getDataFromResponse:(NSDictionary*)ssfType forCall:(NSString*)call error:(SplytError*)splytError;
- (void) sendAsync:(NSString*)method withArgs:(NSArray*)args andThen:(SplytDataHandler)handler;
- (void) sendAsync:(NSString*)host toApp:(NSString*)app andMethod:(NSString*)method andWsVersion:(NSString*)wsVersion withArgs:(NSArray*)args andThen:(SplytDataHandler)handler;
@end

@interface SplytTransaction ()
@property (nonatomic) SplytCore* core;
- (id) initWithCategory:(NSString*)category andId:(NSString*)transactionId andInitBlock:(void(^)(SplytTransaction*)) initBlock;
@end

@interface SplytInstrumentation ()
@property (nonatomic) SplytCore* core;
- (void) initInstrumentation;
@end

@interface SplytNotification ()
@property (nonatomic) SplytCore* core;
- (void) preInit:notificationReceivedCallback noAutoClear:(BOOL)disableAutoClear;
- (void) init:(NSString*)host;
@end

@interface SplytTuning ()
@property (nonatomic) SplytCore* core;
- (void) initAndThen:(SplytCallback)call;
- (void) updateEntityOfType:(NSString*)type andId:(NSString *)entityId withValues:(id)values;
- (void) clearEntityOfType:(NSString*)type andId:(NSString *)entityId;
- (void) persist;
@end

@interface SplytSession ()
@property (nonatomic) SplytInstrumentation* instrumentation;
@end

@interface SplytPurchase ()
@property (nonatomic) SplytInstrumentation* instrumentation;
@end

