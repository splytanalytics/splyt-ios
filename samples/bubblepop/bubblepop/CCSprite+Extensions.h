//
//  CCSprite+Extensions.h
//  
//
//  Created by Andrew Brown on 1/10/14.
//
//

#import <Cocos2D/Cocos2D.h>

@interface CCSprite (Extensions)
-(void)resizeToWidth:(float)width andHeight:(float)height;
-(void)resizeToHeight:(float)height maintainingAspectRatio:(BOOL)keepAspect;
-(void)resizeToWidth:(float)width maintainingAspectRatio:(BOOL)keepAspect;
@end
