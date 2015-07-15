
@import UIKit;
#import <Cocos2D/Cocos2DFramework.h>

@interface MyNavigationController : UINavigationController <CCDirectorDelegate>
@end

@interface AppController : NSObject <UIApplicationDelegate> {
	UIWindow* mWindow;
	MyNavigationController* mNavController;
	CCDirectorIOS* __unsafe_unretained mDirector;
}

@property (nonatomic, strong) UIWindow* window;
@property (readonly) MyNavigationController* navController;
@property (unsafe_unretained, readonly) CCDirectorIOS* director;

@end
