//
//  SplytTuning.m
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytTuning.h>
#import <Splyt/SplytInternal.h>

@interface SplytTuningValues : NSObject <NSCoding>
- (void) updateEntityOfType:(NSString*)type andId:(NSString*)id withValues:(NSDictionary*)values;
- (void) removeEntityOfType:(NSString*)type andId:(NSString*)id;
- (id) getValue:(NSString*)name forEntityOfType:(NSString*)type andId:(NSString*)id usingDefault:(id)defaultValue;
- (id) init;

// NSCoding serialization implementation
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

@implementation SplytTuningValues {
    NSMutableDictionary* _storage;
    NSMutableDictionary* _used;
}

- (void) updateEntityOfType:(NSString*)type andId:(NSString*)entityId withValues:(NSDictionary*)values {
    if(nil == values) {
        [SplytUtil logDebug:@"Trying to set nil tuning values. Possibly an unexpected server result?"];
        return;
    }

    if(nil == entityId) {
        [SplytUtil logDebug:@"Trying to set tuning vars for a nil entity. Unsupported."];
        return;
    }

    NSMutableDictionary *typeStorage = [_storage objectForKey:type];
    if(nil != typeStorage) {
        [typeStorage setObject:values forKey:entityId];
    }
    else {
        typeStorage = [[NSMutableDictionary alloc] initWithDictionary:@{entityId:values}];
        [_storage setObject:typeStorage forKey:type];
    }
}

- (void) removeEntityOfType:(NSString*)type andId:(NSString*)entityId {
    NSMutableDictionary *typeStorage = [_storage objectForKey:type];
    if(nil != typeStorage) {
        [typeStorage removeObjectForKey:entityId];
    }
}

- (BOOL) markUsed:(NSString*)name every:(NSTimeInterval)interval{
    // don't try to record a nameless variable - bad things happen
    if(nil == name)
        return NO;

    NSDate* then = [_used objectForKey:name];
    NSDate* now = [NSDate date];

    if(nil == then || [now timeIntervalSinceDate:then] > interval) {
        [_used setObject:now forKey:name];
        return YES;
    }

    return NO;
}

- (id) getValue:(NSString*)name forEntityOfType:(NSString*)type andId:(NSString*)entityId usingDefault:(id)defaultValue {
    id value = nil;

    NSDictionary *typeStorage = [_storage objectForKey:type];
    if(nil != typeStorage) {
        NSDictionary *entityStorage = [typeStorage objectForKey:entityId];
        if(nil != entityStorage) {
            id rawValue = [entityStorage objectForKey:name];

            if(nil != rawValue) {
                if([rawValue isKindOfClass:[NSString class]]) {
                    if([defaultValue isKindOfClass:[NSString class]]) {
                        value = rawValue;
                    }
                    else if([defaultValue isKindOfClass:[NSNumber class]]) {
                        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                        [f setNumberStyle:NSNumberFormatterDecimalStyle];
                        value = [f numberFromString:rawValue];
                    }
                    else {
                        [SplytUtil logDebug:[NSString stringWithFormat:@"Using defaultValue of type %@. Currently only NSString and NSNumber types are supported.", NSStringFromClass([defaultValue class])]];
                    }
                }
                else {
                    [SplytUtil logError:[NSString stringWithFormat:@"Non-string %@ receieved from server.", rawValue]];
                }
            }
        }
    }

    if(nil == value)
        return defaultValue;

    return value;
}

- (id)init {
    self = [super init];
    if(self) {
        _storage = [[NSMutableDictionary alloc] init];
        _used = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder {
    _storage = [decoder decodeObjectForKey:@"_storage"];
    _used = [decoder decodeObjectForKey:@"_used"];
    return self;
}
- (void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:_storage forKey:@"_storage"];
    [encoder encodeObject:_used forKey:@"_used"];
}
@end

@implementation SplytTuning {
    SplytTuningValues* _cacheVars;
    NSString* _cachePath;
    BOOL _cacheDirty;
}
static const NSTimeInterval SplytTuning_INTERVAL_RECORDAGAIN = 8.0*60.0*60.0; // only record each 8 hours
static NSString* const SplytTuning_CACHE_FILENAME = @"com.splyt.tuningCache";

#pragma mark - private

- (void) readCache {
    @try {
        _cacheVars = [NSKeyedUnarchiver unarchiveObjectWithFile:_cachePath];
    }
    @catch (NSException *exception) {
        // for the super unlikely event that a non-coded file exists at the location
        _cacheVars = nil;
    }

    // if we didn't load cached vars, just init the structure so it's ready for future use
    if(nil == _cacheVars)
        _cacheVars = [[SplytTuningValues alloc] init];
}

- (void) writeCache {
    @try {
        [NSKeyedArchiver archiveRootObject:_cacheVars toFile:_cachePath];
    }
    @catch (NSException* exception) {
        [SplytUtil logError:[NSString stringWithFormat:@"Unable to cache tuning to storage! Exception: %@", [exception reason]]];
    }
}

- (SplytError) parseRefreshData:(NSDictionary*)ssfType {
    // this would mean something failed prior to this point
    if(nil == ssfType)
        return SplytError_Generic;

    NSInteger ssfError = [[ssfType objectForKey:@"error"] integerValue];
    if(0 != ssfError) {
        [SplytUtil logError:[NSString stringWithFormat:@"-refresh failed on server. SSF Error: %ld", (long)ssfError]];
        return SplytError_Generic;
    }

    NSDictionary* refreshRet = SPLYT_DYNAMIC_CAST([ssfType objectForKey:@"data"], NSDictionary);
    if(nil == refreshRet) {
        [SplytUtil logError:@"-refresh failed on server. No data in response"];
        return SplytError_Generic;
    }

    NSDictionary* deviceTuning = SPLYT_DYNAMIC_CAST([refreshRet objectForKey:@"deviceTuning"], NSDictionary);
    if(nil != deviceTuning) {
        NSDictionary* deviceData = SPLYT_DYNAMIC_CAST([deviceTuning objectForKey:@"data"], NSDictionary);
        if(nil != deviceData) {
            NSDictionary* deviceValues = SPLYT_DYNAMIC_CAST([deviceData objectForKey:@"value"], NSDictionary);
            if(nil != deviceValues) {
                [self updateEntityOfType:SPLYT_ENTITY_TYPE_DEVICE andId:self.core.deviceId withValues:deviceValues];
            }
        }
    }

    NSDictionary* userTuning = SPLYT_DYNAMIC_CAST([refreshRet objectForKey:@"userTuning"], NSDictionary);
    if(nil != userTuning) {
        NSDictionary* userData = SPLYT_DYNAMIC_CAST([userTuning objectForKey:@"data"], NSDictionary);
        if(nil != userData) {
            NSDictionary* userValues = SPLYT_DYNAMIC_CAST([userData objectForKey:@"value"], NSDictionary);
            if(nil != userValues) {
                [userValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    if([self.core.registeredUsers containsObject:key]) {
                        [self updateEntityOfType:SPLYT_ENTITY_TYPE_USER andId:key withValues:obj];
                    }
                    else {
                        [SplytUtil logDebug:[NSString stringWithFormat:@"Received tuning data for unregistered user %@.  Disregarding", key]];
                    }
                }];
            }
        }
    }

    [self persist];

    return SplytError_Success;
}

#pragma mark - internal

- (void) initAndThen:(SplytCallback)callback {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    _cachePath = [libraryDirectory stringByAppendingPathComponent:SplytTuning_CACHE_FILENAME];
    _cacheDirty = NO;

    [self readCache];

    if(callback)
        callback(SplytError_Success);
}

- (void) updateEntityOfType:(NSString*)type andId:(NSString *)entityId withValues:(id)values {
    if([values isKindOfClass:[NSDictionary class]]) {
        [_cacheVars updateEntityOfType:type andId:entityId withValues:values];
    }
    else {
        if(!values || [values isKindOfClass:[NSArray class]]) {
            [_cacheVars updateEntityOfType:type andId:entityId withValues:[NSDictionary new]];
        }
        else {
            [SplytUtil logError:[NSString stringWithFormat:@"Unexpected data structure of type %@ received, tuning values dictionary expected", [values class]]];
        }
    }

    _cacheDirty = YES;
}

- (void) clearEntityOfType:(NSString*)type andId:(NSString *)entityId {
    [_cacheVars removeEntityOfType:type andId:entityId];

    _cacheDirty = YES;
}

- (void) persist {
    [self writeCache];
}

#pragma mark - public

- (void) refreshAndThen:(SplytCallback)callback {
    NSArray* users = [[self.core registeredUsers] allObjects];

    //grab a timestamp...
    NSNumber* timestamp = [SplytUtil getTimestamp];

    [self.core sendAsync:@"tuner_refresh" withArgs:@[timestamp, timestamp, SPLYT_SAFE(self.core.deviceId), SPLYT_SAFE(users)] andThen:^(NSDictionary *ssfData) {
        SplytError splytError = [self parseRefreshData:ssfData];
        if(callback)
            callback(splytError);
    }];
}

- (id) getVar:(NSString*)varName orDefaultTo:(id)defaultValue {
    if([_cacheVars markUsed:varName every:SplytTuning_INTERVAL_RECORDAGAIN]) {
        [self.core sendDataPoint:@"tuner_recordUsed" withArgs:@[SPLYT_SAFE([varName copy]), SPLYT_SAFE([defaultValue copy])]];
    }

    NSString* entityType = SPLYT_ENTITY_TYPE_DEVICE;
    NSString* entityId = self.core.deviceId;

    if(SPLYT_ISVALIDID(self.core.userId)) {
        entityType = SPLYT_ENTITY_TYPE_USER;
        entityId = self.core.userId;
    }

    return [_cacheVars getValue:varName forEntityOfType:entityType andId:entityId usingDefault:defaultValue];
}
@end
