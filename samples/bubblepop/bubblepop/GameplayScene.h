
#import <Cocos2D/Cocos2DFramework.h>

@interface GameplayScene : CCNodeColor {
    NSInteger numberOfPops;
}

+(CCScene *) sceneWithParams:(NSMutableDictionary*)params;

@end
