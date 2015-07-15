
#import "GameoverScene.h"
#import "IntroScene.h"

#pragma mark - GameoverScene

@implementation GameoverScene {
    CCSprite* mStar;
    NSMutableDictionary* mData;
}

+(CCScene *) sceneWithParams:(NSMutableDictionary*)params {
	CCScene *scene = [CCScene node];
    
    GameoverScene* gameover = [GameoverScene node];
    [gameover setupWithParams:params];
	[scene addChild:gameover];
	
	return scene;
}

-(id) init {
    self = [super initWithColor:[CCColor colorWithRed:255 green:255 blue:255 alpha:255]];
    return self;
}

- (void) setupWithParams:(NSMutableDictionary*) params {
    mData = params;
    
    CGSize size = [CCDirector sharedDirector].viewSize;
    
    mStar = [CCSprite spriteWithImageNamed:@"star.png"];
    mStar.position = ccp(size.width/2, size.height/2);
    //mStar.color = ccc3(0x00, 0x00, 0x00);
    [self addChild:mStar];
    
    id scaleAction = [CCActionScaleTo actionWithDuration:1 scale:2.0f];
    id delayTimeAction = [CCActionDelay actionWithDuration:1];
    id myCallFunc = [CCActionCallFunc actionWithTarget:self selector:@selector(restartGame)];
    
    [mStar runAction:[CCActionSequence actions:scaleAction, delayTimeAction, myCallFunc, nil]];
}

- (void) restartGame {
    [[CCDirector sharedDirector] replaceScene:[IntroScene sceneWithParams:mData]
                               withTransition:[CCTransition transitionCrossFadeWithDuration:0.5]];
}

@end
