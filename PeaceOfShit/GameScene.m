//
//  GameScene.m
//  PeaceOfShit
//
//  Created by Никита Шарапов on 16.10.15.
//  Copyright (c) 2015 Никита Шарапов. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene
{
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    BOOL _didShoot;
}

static const CGFloat SHOOT_SPEED = 1000.0f;
static const CGFloat kCCHaloLowAngle = 200.0 * M_PI / 180.0;
static const CGFloat kCCHaloHighAngle = 340.0 * M_PI / 180.0;
static const CGFloat kCCHaloSpeed = 100.0;

static const uint32_t haloCategory = 0x1 << 0; // 00000001
static const uint32_t bulletCategory = 0x1 << 1; // 00000010
static const uint32_t edgeCategory = 0x1 << 2; // 00000100



static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat higt)
{
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (higt - low) + low;
}

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size] ) {
        
        // Turn off gravity
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        self.physicsWorld.contactDelegate = self;
        
        
        
        //add edges
        SKNode * leftEdge = [[SKNode alloc]init];
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody.categoryBitMask = edgeCategory;
        leftEdge.physicsBody.contactTestBitMask = bulletCategory;
        leftEdge.physicsBody.collisionBitMask = bulletCategory;
        [self addChild:leftEdge];
        
        SKNode * rightEdge = [[SKNode alloc]init];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
        rightEdge.position = CGPointMake(self.size.width, 0.0);
        rightEdge.physicsBody.categoryBitMask = edgeCategory;
        rightEdge.physicsBody.contactTestBitMask = bulletCategory;
        rightEdge.physicsBody.collisionBitMask = bulletCategory;
        [self addChild:rightEdge];
        
        //add main layor
        _mainLayer = [[SKNode alloc]init];
        [self addChild:_mainLayer];
        
        //add cannon
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"cannon"];
        _cannon.size = CGSizeMake(120, 120);
        _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
        _cannon.anchorPoint = CGPointMake(0.1, 0.5);
        
        [_mainLayer addChild:_cannon];
        
        //Create cannon rotation actions.
        SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                      [SKAction rotateByAngle:-M_PI duration:2]]];
        [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
        
        // create spawn halo actions
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnHalo]];

    }
    return self;
}

-(void)shoot
{
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * rotationVector.dx),
                                _cannon.position.y + (_cannon.size.height * rotationVector.dy));
    ball.size = CGSizeMake(20, 20);
    [_mainLayer addChild:ball];
    
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20/2];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    // чтобы отскакивал без потери
    ball.physicsBody.restitution = 1.0;
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.friction = 0.0;
    ball.physicsBody.categoryBitMask = bulletCategory;
    ball.physicsBody.collisionBitMask = edgeCategory;
    ball.physicsBody.contactTestBitMask = edgeCategory;
}


-(void)spawnHalo
{
    int k = randomInRange(40, 60);
    
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"halo"];
    halo.size = CGSizeMake(k, k);
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:k/2];
    CGVector direction = radiansToVector(randomInRange(kCCHaloLowAngle, kCCHaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kCCHaloSpeed, direction.dy * kCCHaloSpeed);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = haloCategory;
    halo.physicsBody.collisionBitMask = edgeCategory;
    halo.physicsBody.contactTestBitMask = bulletCategory;
    
    [_mainLayer addChild:halo];
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    if (firstBody.categoryBitMask == haloCategory && secondBody.categoryBitMask == bulletCategory) {
        // collision between halo and ball
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"]; // HaloExplosion
        
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if (firstBody.categoryBitMask == bulletCategory && secondBody.categoryBitMask == edgeCategory) {
        [self addExplosion:contact.contactPoint withName:@"BounceExplosion"];
        [firstBody.node removeFromParent];
    }
}


-(void)addExplosion:(CGPoint)position withName:(NSString*)name
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    SKAction *removeExploision = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                      [SKAction removeFromParent]]];
    
    [explosion runAction:removeExploision];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *touch in touches) {
        _didShoot = YES;
            }
}

-(void)didSimulatePhysics
{
    //Shoot
    if (_didShoot){
        [self shoot];
        _didShoot = NO;
    }
    //Remove unused nodes
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
