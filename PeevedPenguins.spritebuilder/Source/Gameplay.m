//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Mus Bai on 12.07.14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation Gameplay
{
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    
    CCNode *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    
    CCAction *_followPenguin;
   
}

 static const float MIN_SPEED = 5.f;

-(void) update:(CCTime)delta
{
    if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED)
    {
        [self nextAttempt];
        return;
    }
    
    int xMin = _currentPenguin.boundingBox.origin.x;
    
    if (xMin < self.boundingBox.origin.x) {
        [self nextAttempt];
        return;
    }
    
    int xMax = xMax + _currentPenguin.boundingBox.size.width;
    
    if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width))
    {
        [self nextAttempt];
        return;
    }
    
}





-(void) didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild: level];
    
    //_physicsNode.debugDraw = TRUE;
    
    _pullbackNode.physicsBody.collisionMask = @[];
    
    _mouseJointNode.physicsBody.collisionMask = @[];
    
    _physicsNode.collisionDelegate = self;
}

-(void) touchBegan:(UITouch *) touch withEvent:(UIEvent *) event {
    //[self launchPenguin];
    
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        _mouseJointNode.position = touchLocation;
        
        //_mouseJointNode = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode bodyB:<#(CCPhysicsBody *)#> anchorA:<#(CGPoint)#> anchorB:<#(CGPoint)#> restLength:<#(CGFloat)#> stiffness:<#(CGFloat)#> damping:<#(CGFloat)#>]
      _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
    
        _currentPenguin = [CCBReader load:@"Penguin"];
        
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        
        [_physicsNode addChild:_currentPenguin];
        
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        _penguinCatapultJoint =  [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];;
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

- (void)releaseCatapult {
    if (_mouseJoint != nil)
    {
        // releases the joint and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        CCActionFollow *follow = [CCActionFollow actionWithTarget: _currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];
        
        //_followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        //[_contentNode runAction:_followPenguin];
    }
}


-(void) nextAttempt
{
    _currentPenguin = nil;
    [_contentNode stopAction:_followPenguin];
    
    CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration: 1.f position: ccp(0,0)];
    [_contentNode runAction:actionMoveTo];
}


-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // when touches end, meaning the user releases their finger, release the catapult
    [self releaseCatapult];
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    // when touches are cancelled, meaning the user drags their finger off the screen or onto something else, release the catapult
    [self releaseCatapult];
}

-(void) launchPenguin {
    CCNode *penguin = [CCBReader load: @"Penguin"];
    
    penguin.position = ccpAdd(_catapultArm.position, ccp(16,50));
    
    [_physicsNode addChild:penguin];
    
    
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce: force];
    
    self.position = ccp(0,0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    
    [_contentNode runAction:follow];
    
}

/*
-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB
{
    CCLOG(@"Something collided with a seal!");
}*/

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB {
    float energy = [pair totalKineticEnergy];
    
    // if energy is large enough, remove the seal
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        } key:nodeA];
    }
    
}

- (void)sealRemoved:(CCNode *)seal {

    
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = TRUE;
    // place the particle effect on the seals position
    explosion.position = seal.position;
    // add the particle effect to the same node the seal is on
    [seal.parent addChild:explosion];
    
    // finally, remove the destroyed seal
    [seal removeFromParent];
}

-(void) retry
{
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

@end
