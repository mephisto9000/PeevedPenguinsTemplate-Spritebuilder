//
//  WaitingPenguin.m
//  PeevedPenguins
//
//  Created by Mus Bai on 13.07.14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "WaitingPenguin.h"

@implementation WaitingPenguin

-(void) didLoadFromCCB
{
    float delay = (arc4random()%200) / 1000.0f;
    
    [self performSelector:@selector(startBlinkAndJump) withObject:nil afterDelay:delay];
}

- (void)startBlinkAndJump
{
    // the animation manager of each node is stored in the 'animationManager' property
    CCAnimationManager* animationManager = self.animationManager;
    // timelines can be referenced and run by name
    [animationManager runAnimationsForSequenceNamed:@"BlinkAndJump"];
}

@end
