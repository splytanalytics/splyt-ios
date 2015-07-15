
#import <Splyt/Splyt.h>
#import "BubblePopDefaults.h"
#import "GameoverScene.h"
#import "GameplayScene.h"
#import "HUDLayer.h"

#pragma mark - GameplayScene

@implementation GameplayScene {
    NSMutableArray* mBubbles;
    NSMutableDictionary* mData;
    int mNumBubbles;
    int mStarIdx;
}

+(CCScene *) sceneWithParams:(NSMutableDictionary*)params {
	CCScene *scene = [CCScene node];
    
    GameplayScene* gameplay = [GameplayScene node];
    [gameplay setupWithParams:params];
	[scene addChild:gameplay];
    
    HUDLayer* hud = [[HUDLayer alloc] init];
    [hud setupWithParams:params];
    [scene addChild:hud];
    
	return scene;
}

-(id) init {
    numberOfPops = 0;
    if ((self = [super initWithColor:[CCColor colorWithRed:255 green:255 blue:255 alpha:255]])) {
        // Allow touches...
        [self setUserInteractionEnabled:YES];
    }
    return self;
}
    
- (void) setupWithParams:(NSMutableDictionary*) params {
    mData = params;

    mNumBubbles = [(NSNumber *) [[Splyt Tuning] getVar:@"numBubbles" orDefaultTo:DEFAULT_NUMBUBBLES] intValue];
    mStarIdx = arc4random() % mNumBubbles;
    
    CGSize size = [CCDirector sharedDirector].viewSize;

    mBubbles = [[NSMutableArray alloc] init];
    
    for(int i=0; i<mNumBubbles; i++) {
        CGFloat x = (size.width/(mNumBubbles+1))*(i+1);
        CGFloat y = size.height/2;
        
        CCSprite* bubble = [CCSprite spriteWithImageNamed:@"bubble.png"];
        bubble.position = ccp(x,y);

        [self addChild:bubble];
        
        CCActionEaseSineIn* actionEaseDown = [CCActionEaseSineIn actionWithAction:[CCActionMoveTo actionWithDuration:2 position:ccp(x,y-40)]];
        CCActionEaseSineIn* actionEaseUp = [CCActionEaseSineIn actionWithAction:[CCActionMoveTo actionWithDuration:2 position:ccp(x,y)]];
        [bubble runAction:[CCActionRepeatForever actionWithAction:[CCActionSequence actions:actionEaseDown, actionEaseUp, nil]]];
        
        [mBubbles addObject:bubble];
    }

    [[[Splyt Instrumentation] Transaction:@"play_game"] begin];
}

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL handled = FALSE;
    CGPoint touchLocation = [self convertToNodeSpace:touch.locationInWorld];
    
    // Loop through all bubbles...
    for(int i=0; i<mNumBubbles; i++) {
        // Get the bubble at this index...
        CCNode* node = [mBubbles objectAtIndex:i];
        
        // If this bubble is the one that was clicked...
        if(![node isEqual:[NSNull null]] && CGRectContainsPoint(node.boundingBox, touchLocation)) {
            handled = TRUE;
            
            // Increment the total number of bubble pops during this game
            numberOfPops++;
            
            // Set it to nil in the array...
            [mBubbles replaceObjectAtIndex:i withObject:[NSNull null]];
            
            // Remove the node...
            [self removeChild:node];
            
            if(i == mStarIdx) {
                [self gameOver];
            }
            break;
        }
    }
    
    if (!handled) {
        //Bubble the event up to the next responder...
        [[[CCDirector sharedDirector] responderManager] discardCurrentEvent];
    }
}

-(void)gameOver {
    SplytTransaction *trx = [[Splyt Instrumentation] Transaction:@"play_game"];
    [trx setProperty:@"number_of_pops" withValue:[NSNumber numberWithLong:numberOfPops]];
    [trx setProperty:@"win_quality" withValue:[self getWinQuality:numberOfPops]];
    [trx end];
    
    // Transition to game end scene...
    [[CCDirector sharedDirector] replaceScene:[GameoverScene sceneWithParams:mData]];
}

-(NSNumber *)getWinQuality:(NSInteger)totalPops {
    float winQuality = (mNumBubbles - totalPops) / (float) (mNumBubbles - 1);
    return [NSNumber numberWithFloat:winQuality];
}

@end
