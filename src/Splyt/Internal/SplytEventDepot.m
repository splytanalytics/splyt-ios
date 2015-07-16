//
//  SplytEventDepot.m
//  Splyt
//
//  Created by Jeremy Paulding on 12/16/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytEventDepot.h>

// a SplytEvent is really just a dictionary, but this little bit of handwaving helps the code read better
typedef NSDictionary SplytEvent;
@interface NSDictionary (internal)
+ (SplytEvent*) eventFromName:(NSString*)name andArgs:(NSArray*)args;
@end
@implementation NSDictionary (internal)
+ (SplytEvent*) eventFromName:(NSString*)name andArgs:(NSArray*)args {
    return @{@"method":name, @"args":args};
}
@end

@interface SplytEventDepotState : NSObject <NSCoding>
@property NSArray* resendBin;
@property NSString* resendBinURL;
@property NSArray* holdingBin;
@property NSString* holdingBinURL;
@property NSUInteger archiveStart;
@property NSUInteger archiveEnd;
- (NSUInteger) store:(SplytEvent*)event forURL:(NSString*)url;
@end

@implementation SplytEventDepotState {
    NSMutableArray* _holdingBin;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(nil != self) {
        _resendBin = [aDecoder decodeObjectForKey:@"resendBin"];
        _resendBinURL = [aDecoder decodeObjectForKey:@"resendBinURL"];
        _holdingBin = [aDecoder decodeObjectForKey:@"holdingBin"];
        _holdingBinURL = [aDecoder decodeObjectForKey:@"holdingBinURL"];
        _archiveStart = [[aDecoder decodeObjectForKey:@"archiveStart"] integerValue];
        _archiveEnd = [[aDecoder decodeObjectForKey:@"archiveEnd"] integerValue];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_resendBin forKey:@"resendBin"];
    [aCoder encodeObject:_resendBinURL forKey:@"resendBinURL"];
    [aCoder encodeObject:_holdingBin forKey:@"holdingBin"];
    [aCoder encodeObject:_holdingBinURL forKey:@"holdingBinURL"];
    [aCoder encodeObject:@(_archiveStart) forKey:@"archiveStart"];
    [aCoder encodeObject:@(_archiveEnd) forKey:@"archiveEnd"];
}

- (NSUInteger) store:(SplytEvent*)event forURL:(NSString*)url {
    if(nil == _holdingBin) {
        _holdingBin = [NSMutableArray new];
        _holdingBinURL = url;
    }
    else {
        NSAssert([url isEqualToString:_holdingBinURL], @"Should never be placing events in a bin with a different URL");
    }

    [_holdingBin addObject:event];

    return _holdingBin.count;
}
@end

@interface SplytEventDepot ()
    @property SplytEventDepotState* state;
@end

@implementation SplytEventDepot {
    SplytEventSender _sender;
    NSString* _url;
    NSString* _libraryPath;
    dispatch_queue_t _queue;
    BOOL _paused;
    NSTimeInterval _processDelay;
}
static const NSTimeInterval SplytEventDepot_PROCESSBIN_MINPERIOD = 5.0;
static const NSTimeInterval SplytEventDepot_PROCESSBIN_MAXPERIOD = 30.0;
static const NSUInteger SplytEventDepot_MAXEVENTSPERBIN = 50;
static const NSUInteger SplytEventDepot_MAXBINS = 200;

#if DEBUG
static char SplytEventDepot_SENTINEL[] = "YES";
#endif
static NSString* const SplytEventDepot_STATE_FILENAME = @"com.splyt.eventDepotCache";
static NSString* const SplytEventDepot_BATCH_PFX = @"com.splyt.eventDepotBatch_";
static char* const SplytEventDepot_QUEUENAME = "com.splyt.eventdepot";

// simple internal property, whose job is to make sure that all accesses to the state are done using the _queue
@synthesize state = _state_raw;
- (SplytEventDepotState*)state { NSAssert(SplytEventDepot_SENTINEL == dispatch_get_specific(SplytEventDepot_SENTINEL), @"state being accessed outside _queue"); return _state_raw; }
- (void)setState:(SplytEventDepotState *)state { _state_raw = state; }

- (void) _binSave:(NSArray*)bin withURL:(NSString*)url{
    @try {
        NSString* file = [NSString stringWithFormat:@"%@%lu", SplytEventDepot_BATCH_PFX, (unsigned long)self.state.archiveEnd];
        NSString* path = [_libraryPath stringByAppendingPathComponent:file];

        [NSKeyedArchiver archiveRootObject:@{@"bin":bin, @"url":url} toFile:path];
    }
    @catch (NSException* exception) {
        [SplytUtil logError:[NSString stringWithFormat:@"Unable to save queued events to storage! Exception: %@", [exception reason]]];
    }

    self.state.archiveEnd += 1;
    if(self.state.archiveEnd == SplytEventDepot_MAXBINS)
        self.state.archiveEnd = 0;

    // if we looped around, advance the start
    if(self.state.archiveEnd == self.state.archiveStart) {
        self.state.archiveStart += 1;
        if(self.state.archiveStart == SplytEventDepot_MAXBINS)
            self.state.archiveStart = 0;
    }

    // keep state in sync w/ bin files
    [self _stateSave];
}

- (id) _binLoad:(NSString**)url {
    NSArray* bin = nil;
    *url = nil;

    if(self.state.archiveStart != self.state.archiveEnd) {
        // load a batch from storage
        @try {
            NSString* file = [NSString stringWithFormat:@"%@%lu", SplytEventDepot_BATCH_PFX, (unsigned long)self.state.archiveStart];
            NSString* path = [_libraryPath stringByAppendingPathComponent:file];

            NSDictionary* contents = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            bin = [contents objectForKey:@"bin"];
            *url = [contents objectForKey:@"url"];

            // delete from storage
            NSError *error;
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (!success) {
                [SplytUtil logError:[NSString stringWithFormat:@"Failed to delete event batch (%@) from storage", path]];
            }
        }
        @catch (NSException* exception) {
            [SplytUtil logError:[NSString stringWithFormat:@"Failed to load event batch %lu from storage", (unsigned long)self.state.archiveStart]];
        }

        self.state.archiveStart += 1;
        if(self.state.archiveStart == SplytEventDepot_MAXBINS)
            self.state.archiveStart = 0;

        // keep state in sync w/ bin files
        [self _stateSave];
    }

    return bin;
}

- (BOOL) _binSend:(NSArray*)bin toURL:(NSString*)url{
    NSNumber* timestamp = [SplytUtil getTimestamp];
    NSArray* args = @[SPLYT_SAFE(timestamp), SPLYT_SAFE(bin)];

    if(nil == url) {
        [SplytUtil logError:@"Internal Error: Trying to send data w/o a bin url. Using default."];
        url = _url;
    }

    NSDictionary* data = _sender(url, args);

    if(nil == data) {
        // decay processing interval when a send fails
        _processDelay = fmin(_processDelay * 2.0, SplytEventDepot_PROCESSBIN_MAXPERIOD);

        [SplytUtil logDebug:@"Sending batch failed.  Retry pending"];
    }
    else {
        _processDelay = fmax(_processDelay / 2.0, SplytEventDepot_PROCESSBIN_MINPERIOD);
    }

    return nil != data;
}

- (void) _stateSave {
    @try {
        NSString* path = [_libraryPath stringByAppendingPathComponent:SplytEventDepot_STATE_FILENAME];
        [NSKeyedArchiver archiveRootObject:self.state toFile:path];
    }
    @catch (NSException* exception) {
        [SplytUtil logError:[NSString stringWithFormat:@"Unable to save queued events to storage! Exception: %@", [exception reason]]];
    }
}

- (void) _stateRestore {
    if(nil == self.state) {
        @try {
            NSString* path = [_libraryPath stringByAppendingPathComponent:SplytEventDepot_STATE_FILENAME];
            self.state = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        }
        @catch (NSException* exception) {
            // for the super unlikely event that a non-coded file exists at the location
            self.state = nil;
        }

        // if we didn't load cached state, just init the structure so it's ready for future use
        if(nil == self.state)
            self.state = [[SplytEventDepotState alloc] init];
    }
    else {
        [SplytUtil logDebug:@"Not loading queued events from storage because state was never released"];
    }
}

- (void) _stateProcessBins:(BOOL)flushHoldingBin {
    NSArray* bin;

    // if there are events to be re-sent, they get priority
    if(nil != self.state.resendBin && self.state.resendBin.count > 0) {
        if([self _binSend:self.state.resendBin toURL:self.state.resendBinURL]) {
            self.state.resendBin = nil;
            self.state.resendBinURL = nil;
        }
    }
    // next, we try to empty our queue from storage, if there is one
    else {
        NSString* url;
        if(nil != (bin = [self _binLoad:&url]) && bin.count > 0) {
            if(![self _binSend:bin toURL:url]) {
                self.state.resendBin = bin;
                self.state.resendBinURL = url;
            }
        }
        // finally, just fire off the holding bin, if we didn't have other stuff to send
        else if(nil != self.state.holdingBin && self.state.holdingBin.count > 0){
            if(![self _binSend:self.state.holdingBin toURL:self.state.holdingBinURL]) {
                self.state.resendBin = self.state.holdingBin;
                self.state.resendBinURL = self.state.holdingBinURL;
            }
            self.state.holdingBin = nil;
            self.state.holdingBinURL = nil;
        }
    }

    // if the holding bin is oversized, flush it to disk
    if(nil != self.state.holdingBin && (flushHoldingBin || self.state.holdingBin.count > SplytEventDepot_MAXEVENTSPERBIN)) {
        [self _binSave:self.state.holdingBin withURL:self.state.holdingBinURL];
        self.state.holdingBin = nil;
        self.state.holdingBinURL = nil;
    }
}

- (void) _stateProcessJob {
    dispatch_async(_queue, ^{
        [self _stateProcessBins:false];

        // add self back to queue after delay (note that this uses GCD main queue)
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_processDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _stateProcessJob];
        });
    });
}

- (id) initWithURL:(NSString*)url andSender:(SplytEventSender)sender {
    self = [super init];

    _url = url;
    _sender = sender;
    _queue = dispatch_queue_create(SplytEventDepot_QUEUENAME, DISPATCH_QUEUE_SERIAL);

#if DEBUG
    // setup some protection against touching the state outside the serial queue
    // re: http://stackoverflow.com/questions/12806506/how-can-i-verify-that-i-am-running-on-a-given-gcd-queue-without-using-dispatch-g
    // and: https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html#//apple_ref/c/func/dispatch_queue_set_specific
    dispatch_queue_set_specific(_queue, SplytEventDepot_SENTINEL, SplytEventDepot_SENTINEL, NULL);
#endif

    _paused = NO;
    _processDelay = SplytEventDepot_PROCESSBIN_MINPERIOD;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    _libraryPath = [paths objectAtIndex:0];

    // dispatch an init job to insure that the queue is properly set up before anything tries to use it
    dispatch_async(_queue, ^{
        [self _stateRestore];
        BOOL flush = ![_url isEqualToString:self.state.holdingBinURL];
        [self _stateProcessBins:flush];
    });

    // start up the recurring state-processing job
    [self _stateProcessJob];

    return self;
}

- (SplytError) storeEvent:(NSString*)eventName withArgs:(NSArray*)args {
    if(nil == _queue)
        return SplytError_NotInitialized;

    dispatch_async(_queue, ^{
        if(_paused) {
            [self _stateRestore];
        }

        NSUInteger count = [self.state store:[SplytEvent eventFromName:eventName andArgs:args] forURL:_url];
        if(count > SplytEventDepot_MAXEVENTSPERBIN) {
            [self _stateProcessBins:NO];
        }

        if(_paused) {
            [self _stateSave];
            self.state = nil;
        }
    });

    return SplytError_Success;
}

- (void) pause {
    if(nil == _queue)
        return;

    dispatch_async(_queue, ^{
        if(!_paused) {
            _paused = YES;

            [self _stateSave];
            self.state = nil;
        }
    });
}

- (void) resume {
    if(nil == _queue)
        return;

    dispatch_async(_queue, ^{
        if(_paused) {
            [self _stateRestore];

            // assume that we have connectivity after a resume
            _processDelay = SplytEventDepot_PROCESSBIN_MINPERIOD;

            _paused = NO;
        }
    });
}
@end
