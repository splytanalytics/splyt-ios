//
//  SplytCore.m
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

// for scraping device state
#import <sys/utsname.h>
#import <mach/mach_host.h>

#import <Splyt/SplytCore.h>
#import <Splyt/SplytEventDepot.h>
#import <Splyt/SplytInternal.h>

// "private" interfaces
@interface SplytEntityInfo ()
@property (nonatomic, copy) NSString* type;
@property (nonatomic, copy) NSString* entityId;
@property (nonatomic) NSMutableDictionary* state;
@end

@interface SplytInitParams ()
@property (nonatomic, copy) NSString* customerId;
@property (nonatomic, copy) NSString* SDKName;
@property (nonatomic, copy) NSString* SDKVersion;
@end

static NSInteger const Splyt_TIMEOUT_DEFAULT = 3000;
static NSString* const Splyt_DEFAULT_DATACOLLECTOR_HOSTNAME = @"https://data.splyt.com";
static NSString* const Splyt_DEFAULT_NOTIFICATION_HOSTNAME = @"https://notification.splyt.com";
static NSString* const Splyt_SDKNAME_DEFAULT = @"ios";
static NSString* const Splyt_SDKVERSION_DEFAULT = @"5.0.0";
static NSString* const Splyt_WS_VERSION = @"4";

static NSString* const Splyt_DEVICE_ID_KEY = @"com.splyt.deviceId";
static NSString* const Splyt_PROPERTY_ISNEW = @"_SPLYT_isNew";

@implementation SplytEntityInfo {
}

// "private" instance methods
- (id) _initWithType:(NSString*)type entityId:(NSString*)entityId andInitBlock:(void (^)(SplytEntityInfo *))initBlock {
    self = [super init];

    self.type = type;
    self.entityId = entityId;
    if(initBlock)
        initBlock(self);

    return self;
}

// "public" class methods
+ (SplytEntityInfo*) createUserInfo:(NSString*)userId {
    return [[SplytEntityInfo alloc] _initWithType:SPLYT_ENTITY_TYPE_USER entityId:userId andInitBlock:nil];
}

+ (SplytEntityInfo*) createUserInfo:(NSString*)userId withInitBlock:(void (^)(SplytEntityInfo*)) init {
    return [[SplytEntityInfo alloc] _initWithType:SPLYT_ENTITY_TYPE_USER entityId:userId andInitBlock:^(SplytEntityInfo* e){
        if(e)
            init(e);
    }];
}

+ (SplytEntityInfo*) createDeviceInfo {
    return [[SplytEntityInfo alloc] _initWithType:SPLYT_ENTITY_TYPE_DEVICE entityId:nil andInitBlock:nil];
}

+ (SplytEntityInfo*) createDeviceInfoWithInitBlock:(void (^)(SplytEntityInfo*)) init {
    return [[SplytEntityInfo alloc] _initWithType:SPLYT_ENTITY_TYPE_DEVICE entityId:nil andInitBlock:init];
}

// "public" instance methods
- (void) overrideId:(NSString*)entityId {
    self.entityId = entityId;
}

- (void) setIsNew:(BOOL)isNew {
    if(nil == self.state) {
        self.state = [[NSMutableDictionary alloc] initWithDictionary:@{Splyt_PROPERTY_ISNEW:isNew?@YES:@NO}];
    }
    else {
        [self.state setValue:isNew?@YES:@NO forKey:Splyt_PROPERTY_ISNEW];
    }
}

- (void) setProperty:(NSString*)key withValue:(NSObject*)value {
    if(!key) {
        [SplytUtil logDebug:@"Ignoring attempt to set a property with a nil key"];
        return;
    }

    if(nil == self.state) {
        self.state = [[NSMutableDictionary alloc] initWithDictionary:@{key:SPLYT_SAFE(value)}];
    }
    else {
        [self.state setValue:SPLYT_SAFE(value) forKey:key];
    }
}

- (void) setProperties:(NSDictionary*)values {
    if(!values) {
        [SplytUtil logDebug:@"Ignoring attempt to set properties with a nil Dictionary"];
        return;
    }

    if(nil == self.state) {
        self.state = [values mutableCopy];
    }
    else {
        [self.state addEntriesFromDictionary:values];
    }
}

@end

@implementation SplytNotificationInitParams {
}
@end

@implementation SplytInitParams {
}

// "private" instance methods
- (id) _initWithCustomerId:(NSString*)customerId andInitBlock:(void (^)(SplytInitParams*)) initBlock {
    self = [super init];

    if (self) {
        // set customer id
        self.customerId = customerId;

        // establish defaults
        self.host = Splyt_DEFAULT_DATACOLLECTOR_HOSTNAME;
        self.requestTimeout = Splyt_TIMEOUT_DEFAULT;
        self.logEnabled = false;
        self.SDKName = Splyt_SDKNAME_DEFAULT;
        self.SDKVersion = Splyt_SDKVERSION_DEFAULT;
        _notification = [[SplytNotificationInitParams alloc] init];
        self.notification.host = Splyt_DEFAULT_NOTIFICATION_HOSTNAME;
        self.notification.disableAutoClear = NO;

        // now call the init block, as needed, to allow further initialization
        if(initBlock)
            initBlock(self);
    }

    return self;
}

// "public" class methods
+ (SplytInitParams*) createWithCustomerId:(NSString*)customerId {
    return [[SplytInitParams alloc] _initWithCustomerId:customerId andInitBlock:nil];
}

+ (SplytInitParams*) createWithCustomerId:(NSString*)customerId andInitBlock:(void (^)(SplytInitParams*)) init {
    return [[SplytInitParams alloc] _initWithCustomerId:customerId andInitBlock:init];
}

@end

@implementation SplytCore {
    BOOL _initialized;
    NSString* _customerId;
    NSTimeInterval _requestTimeout;
    NSString* _host;
    NSString* _SDKName;
    NSString* _SDKVersion;

    NSMutableSet* _registeredUsers;

    SplytEventDepot* _eventDepot;
    NSOperationQueue* _operationq;
}

// "private" instance methods
- (NSString*) _buildURL:(NSString*)host toApp:(NSString*)app andMethod:(NSString*)method andWsVersion:(NSString*)wsVersion {
    // Build up the URL to any host, app, method, and ws version
    return [NSString stringWithFormat:@"%@/%@/ws/interface/%@?ssf_ws_version=%@&ssf_cust_id=%@&ssf_output=json&ssf_sdk=%@&ssf_sdk_version=%@", host, app, method, wsVersion, _customerId, _SDKName, _SDKVersion];
}

- (NSString*) _buildURL:(NSString*)method {
    // Build up the URL to the data collector
    return [self _buildURL:_host toApp:@"isos-personalization" andMethod:method andWsVersion:Splyt_WS_VERSION];
}

- (SplytError) _initCompleteWithData:(NSDictionary*)data {
    NSString* did = SPLYT_DYNAMIC_CAST([data objectForKey:@"deviceid"], NSString);
    if(SPLYT_ISVALIDID(did)) {
        // register tuning values
        NSDictionary* dtune = SPLYT_DYNAMIC_CAST([data objectForKey:@"devicetuning"], NSDictionary);

        // if this is a response to registerUser, we won't get new device tuning
        if(nil != dtune) {
            [self.tuning updateEntityOfType:SPLYT_ENTITY_TYPE_DEVICE andId:did withValues:dtune];
        }

        [[NSUserDefaults standardUserDefaults] setObject:did forKey:Splyt_DEVICE_ID_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];

        self.deviceId = did;
    }

    NSString* uid = SPLYT_DYNAMIC_CAST([data objectForKey:@"userid"], NSString);
    if(SPLYT_ISVALIDID(uid)) {
        // register tuning values
        NSDictionary* utune = SPLYT_DYNAMIC_CAST([data objectForKey:@"usertuning"], NSDictionary);
        [self.tuning updateEntityOfType:SPLYT_ENTITY_TYPE_USER andId:uid withValues:utune];

        [_registeredUsers addObject:uid];

        self.userId = uid;
    }

    [self.tuning persist];

    return SplytError_Success;
}

- (void) _queueInitTelemFromResponse:(NSDictionary*)data withUserState:(NSDictionary*)userState andDeviceState:(NSDictionary*)deviceState withSendTime:(NSNumber*)timestamp {
    NSMutableDictionary* mutable;

    if(nil != deviceState) {
        mutable = [deviceState mutableCopy];
        [mutable removeObjectForKey:Splyt_PROPERTY_ISNEW];
        [self.instrumentation updateDeviceState:mutable];
    }

    if(nil != userState) {
        mutable = [userState mutableCopy];
        [mutable removeObjectForKey:Splyt_PROPERTY_ISNEW];
        [self.instrumentation updateUserState:mutable];
    }

    // this should never happen, but #paranoia
    if(nil == data)
        return;

    NSObject* newObj = [data objectForKey:@"devicenew"];
    if([newObj isEqual:@(YES)]) {
        [self sendDataPoint:@"datacollector_newDevice" withArgs:nil];
    }

    newObj = [data objectForKey:@"usernew"];
    if([newObj isEqual:@(YES)]) {
        [self sendDataPoint:@"datacollector_newUser" withArgs:nil];
    }
}

- (NSURLRequest*) _buildRequestForURL:(NSURL*)url withArgs:(NSArray*)args {
    NSError* error = nil;
    NSData* data;

    @try {
        data = [NSJSONSerialization dataWithJSONObject:args options:0 error:&error];
    }
    @catch (NSException* e) {
        [SplytUtil logError:[NSString stringWithFormat:@"JSON serialization failed for arguments of %@. Reason: %@", [url lastPathComponent], e.reason]];
        return nil;
    }

    //create the request...
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"true" forHTTPHeaderField:@"ssf-use-positional-post-params"];
    [request setValue:@"true" forHTTPHeaderField:@"ssf-contents-not-url-encoded"];
    [request setHTTPBody:data];


    [request setTimeoutInterval:_requestTimeout];
    // for older OS, we must back-door the value to work around the 240s minimum
    if(request.timeoutInterval != _requestTimeout)
        [request setValue:[NSNumber numberWithInt:5] forKey:@"timeoutInterval"];
    //NSLog(@"%f", request.timeoutInterval);

    return request;
}

- (NSURLRequest*) _buildRequestFor:(NSString*)host toApp:(NSString*)app andMethod:(NSString*)method andWsVersion:(NSString*)wsVersion withArgs:(NSArray*)args {
    NSURL* url = [NSURL URLWithString:[self _buildURL:host toApp:app andMethod:method andWsVersion:wsVersion]];
    return [self _buildRequestForURL:url withArgs:args];
}

- (NSDictionary*) _sendSync:(NSArray*)args toURL:(NSURL*)url
{
    NSURLResponse* response;
    NSError* error;
    NSURLRequest* request = [self _buildRequestForURL:url withArgs:args];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if(nil == data) {
        [SplytUtil logError:[NSString stringWithFormat:@"No data returned from %@. Error: %ld", [url lastPathComponent], (long)error.code]];
        return nil;
    }

    NSDictionary* ssfType = SPLYT_DYNAMIC_CAST([NSJSONSerialization JSONObjectWithData:data options:0 error:&error], NSDictionary);
    if(nil == ssfType) {
        [SplytUtil logError:[NSString stringWithFormat:@"JSON deserialization failed for %@. Error: %ld", [url lastPathComponent], (long)error.code]];
        return nil;
    }

    return ssfType;
}

- (void) _init:(SplytInitParams*)params andThen:(SplytCallback)callback {
    SplytError error = SplytError_Success;

    [SplytUtil setLogEnabled:params.logEnabled];

    if (nil == params) {
        [SplytUtil logError:@"No init parameters provided"];
        error = SplytError_InvalidArgs;
    }
    else if (_initialized) {
        [SplytUtil logError:@"Splyt already initialized"];
        error = SplytError_AlreadyInitialized;
    }
    else if (nil == callback) {
        [SplytUtil logError:@"Please provide a valid SplytCallback"];
        error = SplytError_InvalidArgs;
    }
    else if (SPLYT_ENTITY_TYPE_USER != params.userInfo.type) {
        [SplytUtil logError:@"To provide intitial user settings, be sure to use -createUserInfo"];
        error = SplytError_InvalidArgs;
    }
    else if (SPLYT_ENTITY_TYPE_DEVICE != params.deviceInfo.type) {
        [SplytUtil logError:@"To provide intitial device settings, be sure to use -createDeviceInfo"];
        error = SplytError_InvalidArgs;
    }
    else {
        _customerId = params.customerId;
        _requestTimeout = ((NSTimeInterval)params.requestTimeout) / 1000.0;
        _host = params.host;
        _SDKName = params.SDKName;
        _SDKVersion = params.SDKVersion;

        _registeredUsers = [[NSMutableSet alloc] init];

        // if the device id is not explicitly provided, look for one in the user preferences
        if(SPLYT_ISVALIDID(params.deviceInfo.entityId))
            self.deviceId = params.deviceInfo.entityId;
        else {
            NSString* did = [[NSUserDefaults standardUserDefaults] stringForKey:Splyt_DEVICE_ID_KEY];
            if(SPLYT_ISVALIDID(did))
                self.deviceId = did;
        }

        if(SPLYT_ISVALIDID(params.userInfo.entityId))
            self.userId = params.userInfo.entityId;

        // TODO: - auto-scrape device properties
        NSDictionary* deviceState = [SplytCore _appendDeviceState:params.deviceInfo.state];

        // create an async queue for handling web requests
        _operationq = [[NSOperationQueue alloc] init];

        //build up arguments...
        NSNumber* timestamp = [SplytUtil getTimestamp];
        NSArray* completeArgs = @[
                                  SPLYT_SAFE(timestamp),
                                  SPLYT_SAFE(timestamp),
                                  SPLYT_SAFE(self.userId),
                                  SPLYT_SAFE(self.deviceId),
                                  SPLYT_SAFE(params.userInfo.state),
                                  SPLYT_SAFE(deviceState)
                                  ];

        //make the request...
        [self sendAsync:@"application_init" withArgs:completeArgs andThen:^(NSDictionary *ssfType){
            SplytError splytError;
            NSDictionary* data = [self getDataFromResponse:ssfType forCall:@(__FUNCTION__) error:&splytError];

            if(nil != data) {
                splytError = [self _initCompleteWithData:data];
            }

            // even if there were errors, as long as we have a device id, we can proceed
            if(SPLYT_ISVALIDID(self.deviceId)) {
                // Initialize the event depot now that the subsystem is initialized and will accept events
                _eventDepot = [[SplytEventDepot alloc] initWithURL:[self _buildURL:@"datacollector_batch"] andSender:^(NSString* urlString, NSArray* args) {
                    NSURL* url = [NSURL URLWithString:urlString];

                    return [self _sendSync:args toURL:url];
                }];

                _initialized = YES;
            }

            if(nil != data) {
                [self _queueInitTelemFromResponse:data withUserState:params.userInfo.state andDeviceState:deviceState withSendTime:timestamp];
            }

            if(callback)
                callback(splytError);
        }];

        // count on the async call to raise the callback
        return;
    }

    if(callback)
        callback(error);
}

// "private" class methods
+ (NSDictionary*) _appendDeviceState:(NSDictionary*)initialState {
    NSMutableDictionary* state = [NSMutableDictionary dictionaryWithDictionary:initialState];

    // providing these for consistency w/ android
    [state setObject:@"ios" forKey:@"splyt.platform"];
    [state setObject:@"Apple" forKey:@"splyt.deviceinfo.manufacturer"];
    [state setObject:@"Apple" forKey:@"splyt.deviceinfo.brand"];

    // from http://stackoverflow.com/questions/7241936/how-do-i-detect-a-dual-core-cpu-on-ios
    host_basic_info_data_t hostInfo;
    mach_msg_type_number_t infoCount = HOST_BASIC_INFO_COUNT;
    host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount);

    [state setObject:@(hostInfo.max_cpus) forKey:@"splyt.deviceinfo.cpu_count"];
    [state setObject:@(hostInfo.cpu_type) forKey:@"splyt.deviceinfo.cpu_abi"];
    [state setObject:@(hostInfo.cpu_subtype) forKey:@"splyt.deviceinfo.cpu_abi2"];
    [state setObject:@(hostInfo.memory_size) forKey:@"splyt.deviceinfo.max_mem"];

    // from http://stackoverflow.com/questions/11197509/ios-iphone-get-device-model-and-make
    struct utsname systemInfo;
    uname(&systemInfo);
    [state setObject:@(systemInfo.machine) forKey:@"splyt.deviceinfo.model"];

    // still don't have these things that the android version reports
    // sDeviceAndAppInfo.put("splyt.deviceinfo.product", Build.PRODUCT);
    // sDeviceAndAppInfo.put("splyt.deviceinfo.device", Build.DEVICE);

    NSProcessInfo* processInfo = [NSProcessInfo processInfo];
    [state setObject:processInfo.operatingSystemName forKey:@"splyt.deviceinfo.osname"];
    [state setObject:processInfo.operatingSystemVersionString forKey:@"splyt.deviceinfo.osversion"];

    NSDictionary* bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [bundleInfo objectForKey:@"CFBundleVersion"];
    if(nil != version) {
        NSString* versionShort = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
        NSString* versionNumeric = [bundleInfo objectForKey:@"CFBundleNumericVersion"];
        [state setObject:(versionShort ? versionShort : version) forKey:@"splyt.appinfo.versionName"];
        [state setObject:(versionNumeric ? versionNumeric : version) forKey:@"splyt.appinfo.versionCode"];
    }

    // also don't have these things from android
    // sDeviceAndAppInfo.put("splyt.appinfo.firstInstallTime", info.firstInstallTime);
    // sDeviceAndAppInfo.put("splyt.appinfo.lastUpdateTime", info.lastUpdateTime);
    // sDeviceAndAppInfo.put("splyt.appinfo.requestedPermissions", Arrays.toString(info.requestedPermissions));

    return state;
}

// "package private" instance methods
- (void) sendDataPoint:(NSString*)method withArgs:(NSArray*) args
{
    if(!_initialized) {
        [SplytUtil logError:@"[Splyt] Splyt not initialized"];
        return;
    }

    //must have a customer id and a user id or device id...
    if(!SPLYT_ISVALIDID(_customerId)) {
        [SplytUtil logError:@"[Splyt] Error sending data point, no customer id"];
        return;
    }
    if(!SPLYT_ISVALIDID(self.userId) && !SPLYT_ISVALIDID(self.deviceId)) {
        [SplytUtil logError:@"[Splyt] Error sending data point, no entity IDs"];
        return;
    }

    //grab a timestamp...
    NSNumber* timestamp = [SplytUtil getTimestamp];

    //build up arguments...
    NSMutableArray* completeArgs = [NSMutableArray array];
    // Two timestamps because the interface supports batching
    [completeArgs addObject:timestamp];
    [completeArgs addObject:timestamp];
    [completeArgs addObject:SPLYT_SAFE(self.userId)];
    [completeArgs addObject:SPLYT_SAFE(self.deviceId)];
    if(args != nil){[completeArgs addObjectsFromArray:args];}

    [_eventDepot storeEvent:method withArgs:completeArgs];
}

- (NSDictionary*) getDataFromResponse:(NSDictionary*)ssfType forCall:(NSString*)call error:(SplytError*)splytError {
    NSDictionary* data = nil;
    *splytError = SplytError_Success;

    if(nil == ssfType) {
        *splytError = SplytError_Generic;
    }
    else {
        NSInteger ssfError = [[ssfType objectForKey:@"error"] integerValue];
        if(0 != ssfError) {
            [SplytUtil logError:[NSString stringWithFormat:@"%@ failed on server. SSF Error: %ld", call, (long)ssfError]];
            *splytError = (SplytError)ssfError;
        }
        else {
            data = SPLYT_DYNAMIC_CAST([ssfType objectForKey:@"data"], NSDictionary);
            if(nil == data) {
                [SplytUtil logError:[NSString stringWithFormat:@"%@ failed on server. No data in response", call]];
                *splytError = SplytError_Generic;
            }
        }
    }

    return data;
}

- (void) sendAsync:(NSString*)host toApp:(NSString*)app andMethod:(NSString*)method andWsVersion:(NSString*)wsVersion withArgs:(NSArray*)args andThen:(SplytDataHandler)handler
{
    NSURLRequest* request = [self _buildRequestFor:host toApp:app andMethod:method andWsVersion:wsVersion withArgs:args];

    [NSURLConnection sendAsynchronousRequest:request queue:_operationq completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSDictionary* ssfType = nil;

        if(nil == data) {
            [SplytUtil logError:[NSString stringWithFormat:@"No data returned from %@. Error: %ld", method, (long)error.code]];
        }
        else {
            ssfType = SPLYT_DYNAMIC_CAST([NSJSONSerialization JSONObjectWithData:data options:0 error:&error], NSDictionary);
            if(nil == ssfType) {
                [SplytUtil logError:[NSString stringWithFormat:@"JSON deserialization failed for %@. Error: %ld", method, (long)error.code]];
            }
        }

        if(handler) {
            handler(ssfType);
        }
    }];
}

- (void) sendAsync:(NSString*)method withArgs:(NSArray*)args andThen:(SplytDataHandler)handler
{
    [self sendAsync:_host toApp:@"isos-personalization" andMethod:method andWsVersion:Splyt_WS_VERSION withArgs:args andThen:handler];
}

// "public" instance methods
- (void) init:(SplytInitParams*)params andThen:(SplytCallback)callback {
    // Preinit the notification subsystem.
    // This needs to be called before any subsystems are initialized to avoid some rare potential race conditions at startup
    [self.notification preInit:params.notification.receivedCallback noAutoClear:params.notification.disableAutoClear];

    [self.instrumentation initInstrumentation];

    // default userInfo & deviceInfo if we don't have them, to prevent the need for excessive nil checks later
    if(nil == params.userInfo)
        params.userInfo = [SplytEntityInfo createUserInfo:nil];
    if(nil == params.deviceInfo)
        params.deviceInfo = [SplytEntityInfo createDeviceInfo];

    [self.tuning initAndThen:^(SplytError err) {
        if (SplytError_Success == err) {
            [self _init:params andThen:^(SplytError err) {
                if (SplytError_Success == err) {
                    [self.notification init:params.notification.host];
                }

                if (callback)
                    callback(err);
            }];
        }
        else {
            if (callback)
                callback(err);
        }
    }];
}

- (void) registerUser:(SplytEntityInfo*)userInfo andThen:(SplytCallback)callback{
    SplytError error = SplytError_Success;

    if(!_initialized) {
        [SplytUtil logError:@"Cannot -registerUser before calling -init"];
        error = SplytError_NotInitialized;
    }
    else if(!SPLYT_ISVALIDID(self.deviceId)) {
        [SplytUtil logError:@"No device Id set.  Check for prior errors"];
        error = SplytError_MissingId;
    }
    else if (SPLYT_ENTITY_TYPE_USER != userInfo.type) {
        [SplytUtil logError:@"To provide intitial user settings, be sure to use -createUserInfo"];
        error = SplytError_InvalidArgs;
    }
    else if(!SPLYT_ISVALIDID(userInfo.entityId)) {
        [SplytUtil logError:@"Cannot register a user with a nil id"];
        error = SplytError_MissingId;
    }
    else {
        //build up arguments...
        NSNumber* timestamp = [SplytUtil getTimestamp];
        NSArray* completeArgs = @[
            SPLYT_SAFE(timestamp),
            SPLYT_SAFE(timestamp),
            SPLYT_SAFE(userInfo.entityId),
            SPLYT_SAFE(self.deviceId),
            SPLYT_SAFE(userInfo.state),
        ];

        //make the request...
        [self sendAsync:@"application_updateuser" withArgs:completeArgs andThen:^(NSDictionary *ssfType){
            SplytError splytError;
            NSDictionary* data = [self getDataFromResponse:ssfType forCall:@(__FUNCTION__) error:&splytError];

            if(nil != data) {
                splytError = [self _initCompleteWithData:data];

                [self _queueInitTelemFromResponse:data withUserState:userInfo.state andDeviceState:nil withSendTime:timestamp];
            }

            if(callback)
                callback(splytError);
        }];

        // count on the async call to raise the callback
        return;
    }

    if(callback)
        callback(error);
}

- (SplytError) setActiveUser:(NSString*)userId {
    if(!SPLYT_ISVALIDID(userId)) {
        self.userId = nil;
    }
    else if([_registeredUsers containsObject:userId]) {
        self.userId = userId;
    }
    else {
        [SplytUtil logError:[NSString stringWithFormat:@"User %@ has not been registered. Be sure to call -registerUser to prep an id for usage", userId]];
        return SplytError_InvalidArgs;
    }

    return SplytError_Success;
}
- (SplytError) clearActiveUser {
    self.userId = nil;

    return SplytError_Success;
}

- (void) pause {
    if (nil != _eventDepot) [_eventDepot pause];
}

- (void) resume {
    if (nil != _eventDepot) [_eventDepot resume];

    // Post a NSNotification that the core subsystem has redumed
    [[NSNotificationCenter defaultCenter] postNotificationName:SPLYT_ACTION_CORESUBSYSTEM_RESUMED object:nil];
}

// See http://www.crashlytics.com/blog/what-clang-taught-us-about-objective-c-properties/
// and http://rypress.com/tutorials/objective-c/properties
- (void) setUserId:(NSString*)uid {
    _userId = [uid copy];

    // Post a NSNotification that the user Id has been set
    [[NSNotificationCenter defaultCenter] postNotificationName:SPLYT_ACTION_CORESUBSYSTEM_SETUSERID object:nil];
}

@end