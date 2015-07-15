#import <Splyt/Splyt.h>
#import <Splyt/SplytInternal.h>
#import <Splyt/SplytNotification.h>

@implementation Splyt
static SplytCore *core = nil;
static SplytInstrumentation* instrumentation = nil;
static SplytNotification* notification = nil;
static SplytTuning* tuning = nil;

// these singletons must be created together in order for dependencies to be bi-directional
+ (void) validate {
    static dispatch_once_t lock;
    
    dispatch_once(&lock, ^{
        core = [[SplytCore alloc] init];
        instrumentation = [[SplytInstrumentation alloc] init];
        notification = [[SplytNotification alloc] init];
        tuning = [[SplytTuning alloc] init];
        
        // inject dependencies
        core.tuning = tuning;
        core.instrumentation = instrumentation;
        core.notification = notification;
        instrumentation.core = core;
        notification.core = core;
        tuning.core = core;
    });
}

+ (SplytCore*) Core {
    [self validate];
    
    return core;
}
+ (SplytInstrumentation*) Instrumentation {
    [self validate];
    
    return instrumentation;
}
+ (SplytTuning*) Tuning {
    [self validate];
    
    return tuning;
}
+ (SplytNotification*) Notification {
    [self validate];
    
    return notification;
}
@end

@implementation SplytPlugins
+ (SplytSession*) Session {
    static SplytSession *session = nil;
    static dispatch_once_t lock;
    
    dispatch_once(&lock, ^{
        session = [[SplytSession alloc] init];
        session.instrumentation = [Splyt Instrumentation];
    });
    
    return session;
}

+ (SplytPurchase*) Purchase {
    static SplytPurchase *purchase = nil;
    static dispatch_once_t lock;
    
    dispatch_once(&lock, ^{
        purchase = [[SplytPurchase alloc] init];
        purchase.instrumentation = [Splyt Instrumentation];
    });
    
    return purchase;
}
@end
