#import "CCSprite+Extensions.h"
#import <Splyt/Splyt.h>
#import "BubblePopDefaults.h"
#import "GameplayScene.h"
#import "HUDLayer.h"
#import "IntroScene.h"

#pragma mark - IntroScene

@interface IntroScene()
@property (nonatomic, strong) NSMutableDictionary* mData;
@end

@implementation IntroScene {
    CCSprite* mBanner;
    CCLabelTTF* mGameCost;
}

@synthesize mData;

-(int) getGameCostVerticalAdjustment {
    int vAdjust;
    
    // We want the game cost to be visible in the bottom center of the banner.
    // To do this, we adjust the position of the cost down from the vertical center.
    //
    // The amount of adjustment varies, since different devices have different screen heights.
    if ((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)) {
        // iPhone 3.5" or 4", respectively.
        vAdjust = ([[UIScreen mainScreen] bounds].size.height == 480) ? 38 : 45;
    }
    else {
        // iPad.
        vAdjust = 75;
    }
    
    return vAdjust;
}

+(CCScene *) sceneWithParams:(NSMutableDictionary *)params {
	CCScene *scene = [CCScene node];
    
    IntroScene* intro = [IntroScene node];
    [intro setupWithParams:params];
    [scene addChild:intro];
    
    HUDLayer* hud = [[HUDLayer alloc] init];
    [hud setupWithParams:params];
    [scene addChild:hud];
    
	return scene;
}

-(id) init {
    if((self = [super initWithColor:[CCColor colorWithRed:255 green:255 blue:255 alpha:255]])) {
        //allow touches...
        [self setUserInteractionEnabled:YES];
	}
	return self;
}

-(void) setupWithParams:(NSMutableDictionary*) params {
    mData = params;
    
    // ask director for the window size
    CGSize size = [[CCDirector sharedDirector] viewSize];
    
    //////////////////////////////////
    // BUILD THE BANNER
    //////////////////////////////////
    mBanner = [CCSprite spriteWithImageNamed:@"start_game.png"];
    [mBanner resizeToWidth:0.75 * size.width maintainingAspectRatio:TRUE];

    mBanner.position = ccp(size.width/2, size.height/2);
    [self addChild:mBanner];
    
    NSInteger gameCost = [[[Splyt Tuning] getVar:@"gameCost" orDefaultTo:DEFAULT_GAMECOST] integerValue];

    mGameCost = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"$%ld Gold", (long)gameCost]
                                   fontName:@"Helvetica"
                                   fontSize:22];
    mGameCost.position = ccp(size.width/2, (size.height/2) - [self getGameCostVerticalAdjustment]);
    mGameCost.color = [CCColor blackColor];
    [self addChild:mGameCost];
}

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchLocation = [self convertToNodeSpace:touch.locationInWorld];
    if(CGRectContainsPoint(mBanner.boundingBox, touchLocation) || CGRectContainsPoint(mGameCost.boundingBox, touchLocation)) {
        // See if we have enough gold...
        int balance = [[mData objectForKey:@"balance"] intValue];
        NSInteger gameCost = [[[Splyt Tuning] getVar:@"gameCost" orDefaultTo:DEFAULT_GAMECOST] integerValue];
        
        if((balance - gameCost) >= 0) {
            // Update the balance of gold...
            balance -= gameCost;
            [mData setObject:@(balance) forKey:@"balance"];
            
            // Report the purchase
            [[[SplytPlugins Purchase] TransactionWithInitBlock:^(SplytPurchaseTransaction *purchase) {
                [purchase setItemName:@"new-game"];                                        // The item that is being purchased -- in this case, a new game
                [purchase setPrice:[NSNumber numberWithLong:gameCost] inCurrency:@"gold"];  // Price is some number of gold coins (in-app currency), specified by 'gamecost'
                [purchase setOfferId:@"standard-game"];                                    // The offer ID (optional)
                [purchase setPointOfSale:@"start-banner"];                                 // The point of sale -- in this case, the "start game" banner (optional)
            }] beginAndEnd];

            // Transition...            
            [[CCDirector sharedDirector] replaceScene:[GameplayScene sceneWithParams:mData]
                                       withTransition:[CCTransition transitionCrossFadeWithDuration:0.5]];
        }
    }
    else {
        //Bubble the event up to the next responder...
        [[[CCDirector sharedDirector] responderManager] discardCurrentEvent];
    }
}

@end
