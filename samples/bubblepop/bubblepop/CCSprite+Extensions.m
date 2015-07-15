//
//  CCSprite+Extensions.m
//  
//
//  Created by Andrew Brown on 1/10/14.
//
//

#import "CCSprite+Extensions.h"

@implementation CCSprite (Extensions)

-(void)resizeToWidth:(float)width andHeight:(float)height
{
    self.scaleX = width / self.contentSize.width;
    self.scaleY = height / self.contentSize.height;
}

-(void)resizeToHeight:(float)height maintainingAspectRatio:(BOOL)keepAspect
{
    self.scaleY = height / self.contentSize.height;
    if (keepAspect) {
        self.scaleX = self.scaleY;
    }
}

-(void)resizeToWidth:(float)width maintainingAspectRatio:(BOOL)keepAspect
{
    self.scaleX = width / self.contentSize.width;
    if (keepAspect) {
        self.scaleY = self.scaleX;
    }
}

@end
