
#import "CCSprite+Extensions.h"
#import <Splyt/Splyt.h>
#import "HUDLayer.h"

#pragma mark - HUDLayer

typedef NS_ENUM(NSInteger, UserLoginState) {
    UserLoginStateLoggedOut,
    UserLoginStateLoggingIn,
    UserLoginStateLoggedIn
};

@interface HUDLayer()
@property (nonatomic, strong) NSMutableDictionary* mData;
@end

@implementation HUDLayer {
    CCSprite* mHUDBackgroundL;
    CCSprite* mHUDBackgroundR;
    CCLabelTTF* mUserState;
    CCLabelTTF* mLoginLogout;
    CCLabelTTF* mBalance;
    CCLabelTTF* mAddMoreButton;
    UserLoginState mUserLoginState;
}

@synthesize mData;

-(id) init {
    if ((self = [super init])) {
        //allow touches...
        [self setUserInteractionEnabled:YES];
	}
	return self;
}


- (void) setupWithParams:(NSMutableDictionary*) params {
    mData = params;

    // ask director for the window size
    CGSize size = [[CCDirector sharedDirector] viewSize];
    
    //////////////////////////////////
    // BUILD THE HUD
    //////////////////////////////////
    mHUDBackgroundL = [CCSprite spriteWithImageNamed:@"badge.png"];
    [mHUDBackgroundL resizeToWidth:165 maintainingAspectRatio:TRUE];
    mHUDBackgroundL.position = ccp(75, size.height);
    [self addChild:mHUDBackgroundL];

    mUserState = [CCLabelTTF labelWithString:@"Login" fontName:@"Helvetica" fontSize:22];
    mUserState.position = ccp(75, size.height-20);
    [self addChild:mUserState];

    mLoginLogout = [CCLabelTTF labelWithString:@"[ + ]" fontName:@"Helvetica" fontSize:22];
    mLoginLogout.position = ccp(75, size.height-52);
    [self addChild:mLoginLogout];

    mHUDBackgroundR = [CCSprite spriteWithImageNamed:@"badge.png"];
    [mHUDBackgroundR resizeToWidth:165 maintainingAspectRatio:TRUE];
    mHUDBackgroundR.position = ccp(size.width-75, size.height);
    [self addChild:mHUDBackgroundR];
    
    mBalance = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Gold: %d", [[mData objectForKey:@"balance"] intValue]]
                                  fontName:@"Helvetica"
                                  fontSize:22];
    mBalance.position = ccp(size.width-75, size.height-20);
    [self addChild:mBalance];
    
    mAddMoreButton = [CCLabelTTF labelWithString:@"[ + ]" fontName:@"Helvetica" fontSize:22];
    mAddMoreButton.position = ccp(size.width-75, size.height-52);
    [self addChild:mAddMoreButton];
    
    mUserLoginState = UserLoginStateLoggedOut;
}

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchLocation = [self convertToNodeSpace:touch.locationInWorld];
    if(CGRectContainsPoint(mAddMoreButton.boundingBox, touchLocation)) {
        // Update the balance of gold...
        int balance = [[mData objectForKey:@"balance"] intValue];
        balance += 50;
        [mData setObject:@(balance) forKey:@"balance"];
        
        // Report the purchase        
        [[[SplytPlugins Purchase] TransactionWithInitBlock:^(SplytPurchaseTransaction *purchase) {
            [purchase setItemName:@"gold-50"];            // The item that is being purchased -- in this case, 50 gold coins (in-app currency).
            [purchase setPrice:@1.99 inCurrency:@"usd"];  // Price is $1.99 US Dollars
            [purchase setOfferId:@"standard-gold"];       // The offer ID (optional)
            [purchase setPointOfSale:@"hud-plus"];        // The point of sale -- in this case, the "plus" button in the game's heads-up display (optional)
        }] beginAndEnd];
        
        // Update the UI...
        [mBalance setString:[NSString stringWithFormat:@"Gold: %d", [[mData objectForKey:@"balance"] intValue]]];
    }
    else if (CGRectContainsPoint(mLoginLogout.boundingBox, touchLocation)) {
        switch (mUserLoginState) {
            case UserLoginStateLoggedOut: {
                    // Login with "random" user Id and set the user to have a random gender property
                    SplytEntityInfo* randUser = [SplytEntityInfo createUserInfo:[[NSUUID UUID] UUIDString] withInitBlock:^(SplytEntityInfo *info) {
                        [info setProperty:@"gender" withValue:(0 == arc4random() % 2)?@"male":@"female"];
                    }];

                    [[Splyt Core] registerUser:randUser andThen:^(SplytError error) {
                        if (SplytError_Success == error) {
                            // Successful login
                            mUserState.string = @"Logout";
                            mUserLoginState = UserLoginStateLoggedIn;
                        }
                        else {
                            // Failed to log in, reset the state
                            mUserLoginState = UserLoginStateLoggedOut;
                        }
                    }];

                    // User is logging in
                    mUserLoginState = UserLoginStateLoggingIn;
                }
                break;
            case UserLoginStateLoggedIn:
                [[Splyt Core] clearActiveUser];

                mUserState.string = @"Login";
                mUserLoginState = UserLoginStateLoggedOut;
                break;
            default:
                // Do nothing
                break;
        }
    }
    else {
        //Bubble the event up to the next responder...
        [[[CCDirector sharedDirector] responderManager] discardCurrentEvent];
    }
}

@end
