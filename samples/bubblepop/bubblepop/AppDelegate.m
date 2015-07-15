
#import <Cocos2D/Cocos2DFramework.h>
#import <Splyt/Splyt.h>
#import "AppDelegate.h"
#import "BubblePopDefaults.h"
#import "IntroScene.h"

@implementation MyNavigationController {

}

-(NSUInteger)supportedInterfaceOrientations {
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
		return UIInterfaceOrientationMaskLandscape;
	return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void) directorDidReshapeProjection:(CCDirector*)director {
	if(director.runningScene == nil) {

        NSMutableDictionary* data = [[NSMutableDictionary alloc] init];
        NSNumber * startingBalance = (NSNumber *) [[Splyt Tuning] getVar:@"startingBalance" orDefaultTo:DEFAULT_STARTINGBALANCE];

        [data setObject:startingBalance forKey:@"balance"];

		[director runWithScene: [IntroScene sceneWithParams:data]];
	}
}

@end


@implementation AppController {

}

@synthesize window=mWindow, navController=mNavController, director=mDirector;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	mWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    CCGLView *glView = [CCGLView viewWithFrame:[mWindow bounds] pixelFormat:kEAGLColorFormatRGB565 depthFormat:0 preserveBackbuffer:NO sharegroup:nil multiSampling:NO numberOfSamples:0];

    mDirector = (CCDirectorIOS*) [CCDirector sharedDirector];
    mDirector.wantsFullScreenLayout = YES;
    [mDirector setDisplayStats:NO];
    [mDirector setAnimationInterval:1.0/60];
    [mDirector setView:glView];
    [mDirector setProjection:CCDirectorProjection2D];

    mNavController = [[MyNavigationController alloc] initWithRootViewController:mDirector];
    mNavController.navigationBarHidden = YES;
    [mDirector setDelegate:mNavController];
    [mWindow setRootViewController:mNavController];

    // But for a typical application, you will want to set some additional parameters, which can look something like this
    SplytInitParams* initParams = [SplytInitParams createWithCustomerId:@"splyt-bubblepop-test" andInitBlock:^(SplytInitParams *init) {
#if DEBUG
        // (optional) allows NSLog to occur for debug & error info - only enable during development
        init.logEnabled = YES;

        // Use an extra-long timeout when debugging
        init.requestTimeout = 30000;
#endif

        // To send data somewhere other than the default location(s), uncomment the following line(s) and set the URL(s) accordingly.
        // NOTE:  This is typically used for development purposes
        //init.host = @"http://10.0.2.2";
        //init.notification.host = @"http://10.0.2.2";

        // If the app uses Splyt's notification service, you may want to know when notifications are received and/or when the app is launched via a notification...
        init.notification.receivedCallback = ^(NSDictionary* info, BOOL wasLaunchedBy) {
            if (wasLaunchedBy) {
                NSLog(@"Bubble Pop! was launch by notification: [%@]", info);
            }
            else {
                NSLog(@"Bubble Pop! received a notification [%@]", info);
            }

            // The splyt portion of the payoad is a JSON-encoded string
            NSString* splytStr = [info objectForKey:@"splyt"];
            if (nil != splytStr) {
                @try {
                    NSError* error;
                    NSDictionary* splytData = [NSJSONSerialization JSONObjectWithData:[splytStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                    NSLog(@"Splyt payload is [%@]", splytData);
                }
                @catch (NSException* e) {
                    NSLog(@"JSON deserialization of splyt data failed. Reason: %@", e.reason);
                }
            }
        };
    }];

    [[Splyt Core] init:initParams andThen:^(SplytError error) {
        if (SplytError_Success != error) {
            NSLog(@"SPLYT initialization failed with error %ld. Instrumentation and Tuning may not work as expected.", (long) error);
        }

        // Splyt initialization complete, so start up the game on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [mWindow makeKeyAndVisible];

            [[[SplytPlugins Session] Transaction] begin];
        });
    }];

    return YES;
}

-(void) applicationWillResignActive:(UIApplication *)application {
    [[Splyt Core] pause];

	if([mNavController visibleViewController] == mDirector)
        [mDirector pause];
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
    [[Splyt Core] resume];

    [[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
	if([mNavController visibleViewController] == mDirector)
		[mDirector resume];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	if([mNavController visibleViewController] == mDirector)
		[mDirector stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	if([mNavController visibleViewController] == mDirector)
		[mDirector startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[mDirector end];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

@end
