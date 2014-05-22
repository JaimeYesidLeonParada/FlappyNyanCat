//
//  FNCMyScene.m
//  FlappyNyanCat
//
//  Created by Jaime Yesid Leon Parada on 5/21/14.
//  Copyright (c) 2014 Jaime Yesid Leon Parada. All rights reserved.
//

#import "FNCMyScene.h"

typedef NS_ENUM(int,layer) {
    CapaFondo,
    CapaObstaculo,
    CapaJugador
};

typedef NS_OPTIONS(int, categoriaEntidad)
{
    categoriaEntidadJugador = 1 << 0,
    categoriaEntidadObstaculo = 1 << 1,
    categoriaEntidadFondo = 1 << 2
};


static const float kGravedad = -1500.0;
static const float kImpulso = 400.0;
static const int   kNumFondos = 3;
static const float kVelocidadFondo = 100.0f;
static const float kParteInferior = 0.2;
static const float kParteSuperior = 0.6;
static const float kEspacioObstaculos = 2.4;
static const float kPrimerDelay = 1.75;
static const float kSiempreDelay = 1.5;

@implementation FNCMyScene
{
    SKSpriteNode *_jugador;
    SKNode *_nodoMundo;
    float _limiteComienzo;
    float _limiteAltura;
    
    CGPoint _velocidadJugador;
    
    NSTimeInterval _ultimaVez;
    NSTimeInterval _dt;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size])
    {
        _nodoMundo = [SKNode node];
        [self addChild:_nodoMundo];
        [self asignarFondo];
        [self asignarJugador];
        [self actualizarObstaculos];
    }
    return self;
}

#pragma - mark Inicializacion
- (void)asignarFondo
{
    for (int i = 0; i < kNumFondos; i++) {
        SKSpriteNode *fondo = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        //fondo.anchorPoint = CGPointMake(0.0, 0.0);
        fondo.position = CGPointMake(i * self.size.width, self.size.height/2);
        fondo.zPosition = CapaFondo;
        fondo.name = @"Mundo";
        [_nodoMundo addChild:fondo];
        
        _limiteComienzo = self.size.height - fondo.size.height + 43;
        _limiteAltura = fondo.size.height;
    }
    
    CGPoint izquierdaB = CGPointMake(0, _limiteComienzo + 11);
    CGPoint derechaB = CGPointMake(self.size.width, _limiteComienzo + 11);
    
    self.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:izquierdaB toPoint:derechaB];
    [self skt_attachDebugLineFromPoint:izquierdaB toPoint:derechaB color:[UIColor redColor]];
    self.physicsBody.categoryBitMask = categoriaEntidadFondo;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = categoriaEntidadJugador;
}

- (void)asignarJugador
{
    _jugador = [SKSpriteNode spriteNodeWithImageNamed:@"Cat0"];
    _jugador.position = CGPointMake(self.size.width * 0.2, _limiteAltura * 0.4 + _limiteComienzo);
    _jugador.zPosition = CapaJugador;
    [_nodoMundo addChild:_jugador];
}

- (void)flapNyanCat
{
    _velocidadJugador = CGPointMake(0, kImpulso);
}

- (SKSpriteNode *)crearObstaculo
{
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Cactus"];
    sprite.zPosition = CapaObstaculo;
    return sprite;
}

- (void)mostrarObstaculos
{
    SKSpriteNode *obstaculoInferior = [self crearObstaculo];
    
    float commX = self.size.width + obstaculoInferior.size.width/2;
    
    float obstaculoInfMin = (_limiteComienzo - obstaculoInferior.size.height/2) + _limiteAltura *kParteInferior;
    float obstaculoInfMax = (_limiteComienzo - obstaculoInferior.size.height/2) + _limiteAltura * kParteSuperior;
    
    obstaculoInferior.position = CGPointMake(commX, RandomFloatRange(obstaculoInfMin, obstaculoInfMax));
    [_nodoMundo addChild:obstaculoInferior];
    
    
    SKSpriteNode *obstaculoSuperior = [self crearObstaculo];
    obstaculoSuperior.zRotation = DegreesToRadians(180);
    obstaculoSuperior.position = CGPointMake(commX, obstaculoInferior.position.y + obstaculoInferior.size.height/2 + obstaculoSuperior.size.height/2 + _jugador.size.height * kEspacioObstaculos);
    
    [_nodoMundo addChild:obstaculoSuperior];
    
    
    float movimientoX = self.size.width + obstaculoSuperior.size.width;
    float duracionMovimiento = movimientoX / kVelocidadFondo;
    
    SKAction *secuencia = [SKAction sequence:@[[SKAction moveByX:-movimientoX y:0 duration:duracionMovimiento], [SKAction removeFromParent]]];
    
    [obstaculoSuperior runAction:secuencia];
    [obstaculoInferior runAction:secuencia];
}


- (void)actualizarObstaculos
{
    SKAction *primerDelay = [SKAction waitForDuration:kPrimerDelay];
    SKAction *mostrar = [SKAction performSelector:@selector(mostrarObstaculos) onTarget:self];
    SKAction *siempreDelay = [SKAction waitForDuration:kSiempreDelay];
    SKAction *mostarSecuencia = [SKAction sequence:@[mostrar, siempreDelay]];
    SKAction *siempreMostrar = [SKAction repeatActionForever:mostarSecuencia];
    SKAction *todasSecuencias = [SKAction sequence:@[primerDelay, siempreMostrar]];
    [self runAction:todasSecuencias];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self flapNyanCat];
}

-(void)update:(CFTimeInterval)currentTime
{
    _dt = (_ultimaVez? currentTime - _ultimaVez: 0);
    _ultimaVez = currentTime;
    [self actualizarJugador];
    [self actualizarFondo];
}

- (void)actualizarJugador
{
    CGPoint gravedad = CGPointMake(0, kGravedad);
    CGPoint pasoGravedad = CGPointMultiplyScalar(gravedad, _dt);
    _velocidadJugador = CGPointAdd(_velocidadJugador, pasoGravedad);
    
    CGPoint pasoVelocidad = CGPointMultiplyScalar(_velocidadJugador, _dt);
    _jugador.position = CGPointAdd(_jugador.position, pasoVelocidad);
    
    
    if (_jugador.position.y - _jugador.size.height/2 <= _limiteComienzo) {
        _jugador.position = CGPointMake(_jugador.position.x, _limiteComienzo + _jugador.size.height/2);
    }
    
}

- (void)actualizarFondo
{
    [_nodoMundo enumerateChildNodesWithName:@"Mundo" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *mundo = (SKSpriteNode *)node;
        CGPoint movimiento = CGPointMake(-kVelocidadFondo * _dt, 0);
        mundo.position = CGPointAdd(mundo.position, movimiento);
        
        if (mundo.position.x < -mundo.size.width) {
            mundo.position = CGPointAdd(mundo.position, CGPointMake(mundo.size.width*kNumFondos, 0));
        }
        
    }];
}

@end
