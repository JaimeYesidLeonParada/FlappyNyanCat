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
    CapaJugador,
    CapaUI
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
static const float kMargen = 20.0;
static NSString *const kNombreFont = @"AmericanTypewriter-Bold";



@implementation FNCMyScene
{
    SKSpriteNode *_jugador;
    SKNode *_nodoMundo;
    float _limiteComienzo;
    float _limiteAltura;
    
    BOOL _chocoFondo;
    BOOL _chocoObstaculo;
    
    SKAction *_accionFlap;
    SKAction *_accionCaer;
    SKAction *_accionChoco;
    
    SKLabelNode *_etiquetaPuntaje;
    int _puntaje;
    
    
    CGPoint _velocidadJugador;
    
    NSTimeInterval _ultimaVez;
    NSTimeInterval _dt;
    
    EstadoJuego _estadoJuego;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size])
    {
        _nodoMundo = [SKNode node];
        [self addChild:_nodoMundo];
        
        _estadoJuego = EstadoJuegoJugar;
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        //[self flapNyanCat];
        
        [self cambiarATutorial];
        
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
    //[self skt_attachDebugLineFromPoint:izquierdaB toPoint:derechaB color:[UIColor redColor]];
    self.physicsBody.categoryBitMask = categoriaEntidadFondo;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = categoriaEntidadJugador;
}

- (void)asignarTutorial
{
    SKSpriteNode *tutorial = [SKSpriteNode spriteNodeWithImageNamed:@"Tutorial"];
    tutorial.position = CGPointMake((int)self.size.width *0.5, (int)_limiteAltura * 0.4 + _limiteComienzo);
    tutorial.name = @"Tutorial";
    tutorial.zPosition = CapaUI;
    [_nodoMundo addChild:tutorial];
    
    SKSpriteNode *ready = [SKSpriteNode spriteNodeWithImageNamed:@"Ready"];
    ready.position = CGPointMake(self.size.width * 0.5, _limiteAltura * 0.7 + _limiteComienzo);
    ready.name = @"Tutorial";
    ready.zPosition = CapaUI;
    [_nodoMundo addChild:ready];
}

- (void)asignarJugador
{
    _jugador = [SKSpriteNode spriteNodeWithImageNamed:@"Cat0"];
    _jugador.position = CGPointMake(self.size.width * 0.2, _limiteAltura * 0.4 + _limiteComienzo);
    _jugador.zPosition = CapaJugador;
    [_nodoMundo addChild:_jugador];
    
    CGFloat offsetX = _jugador.frame.size.width * _jugador.anchorPoint.x;
    CGFloat offsetY = _jugador.frame.size.height * _jugador.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 0 - offsetX, 40 - offsetY);
    CGPathAddLineToPoint(path, NULL, 108 - offsetX, 40 - offsetY);
    CGPathAddLineToPoint(path, NULL, 118 - offsetX, 27 - offsetY);
    CGPathAddLineToPoint(path, NULL, 117 - offsetX, 18 - offsetY);
    CGPathAddLineToPoint(path, NULL, 111 - offsetX, 14 - offsetY);
    CGPathAddLineToPoint(path, NULL, 0 - offsetX, 12 - offsetY);
    
    CGPathCloseSubpath(path);
    
    _jugador.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    //[_jugador skt_attachDebugFrameFromPath:path color:[SKColor redColor]];
    _jugador.physicsBody.categoryBitMask = categoriaEntidadJugador;
    _jugador.physicsBody.collisionBitMask = 0;
    _jugador.physicsBody.contactTestBitMask = categoriaEntidadObstaculo | categoriaEntidadFondo;
    
    
}

- (void)flapNyanCat
{
    [self runAction:_accionFlap];
    _velocidadJugador = CGPointMake(0, kImpulso);
}


- (SKSpriteNode *)crearObstaculo
{
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Cactus"];
    sprite.zPosition = CapaObstaculo;
    
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 7 - offsetX, 316 - offsetY);
    CGPathAddLineToPoint(path, NULL, 61 - offsetX, 316 - offsetY);
    CGPathAddLineToPoint(path, NULL, 61 - offsetX, 280 - offsetY);
    CGPathAddLineToPoint(path, NULL, 60 - offsetX, 202 - offsetY);
    CGPathAddLineToPoint(path, NULL, 58 - offsetX, 136 - offsetY);
    CGPathAddLineToPoint(path, NULL, 59 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 58 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 34 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 8 - offsetX, 0 - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    //[sprite skt_attachDebugFrameFromPath:path color:[SKColor redColor]];
    sprite.physicsBody.categoryBitMask = categoriaEntidadObstaculo;
    sprite.physicsBody.collisionBitMask = 0;
    sprite.physicsBody.contactTestBitMask = categoriaEntidadJugador;
    
    return sprite;
}

- (void)mostrarObstaculos
{
    SKSpriteNode *obstaculoInferior = [self crearObstaculo];
    
    float commX = self.size.width + obstaculoInferior.size.width/2;
    
    float obstaculoInfMin = (_limiteComienzo - obstaculoInferior.size.height/2) + _limiteAltura *kParteInferior;
    float obstaculoInfMax = (_limiteComienzo - obstaculoInferior.size.height/2) + _limiteAltura * kParteSuperior;
    
    obstaculoInferior.position = CGPointMake(commX, RandomFloatRange(obstaculoInfMin, obstaculoInfMax));
    obstaculoInferior.name = @"ObstaculoInferior";
    [_nodoMundo addChild:obstaculoInferior];
    
    
    SKSpriteNode *obstaculoSuperior = [self crearObstaculo];
    obstaculoSuperior.name = @"ObstaculoSuperior";
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
    [self runAction:todasSecuencias withKey:@"Mostrar"];
}

- (void)detenerActualizar
{
    [self removeActionForKey:@"Mostrar"];
    [_nodoMundo enumerateChildNodesWithName:@"ObstaculoSuperior" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    
    [_nodoMundo enumerateChildNodesWithName:@"ObstaculoInferior" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch (_estadoJuego) {
        case EstadoJuegoMenuPrincipal:
            break;
            
        case EstadoJuegoTutorial:
            [self cambiarAJugar];
            break;
        case EstadoJuegoJugar:
            [self flapNyanCat];
            break;
            
        case EstadoJuegoColision:
            break;
            
        case EstadoJuegoMostandoPuntaje:
            break;
            
        case EstadoJuegoGameOver:
            break;
            
        default:
            break;
    }
}

- (void)asignarSonidos
{
    _accionFlap = [SKAction playSoundFileNamed:@"flapping.wav" waitForCompletion:NO];
    _accionCaer = [SKAction playSoundFileNamed:@"falling.wav" waitForCompletion:NO];
    _accionChoco = [SKAction playSoundFileNamed:@"whack.wav" waitForCompletion:NO];
}

- (void)asignarEtiquetaPuntaje
{
    _etiquetaPuntaje = [[SKLabelNode alloc]initWithFontNamed:kNombreFont];
    _etiquetaPuntaje.fontColor = [UIColor colorWithRed:101.0/255.0 green:71.0/255.0 blue:73.0/255.0 alpha:1.0];
    _etiquetaPuntaje.position = CGPointMake(self.size.width/2, self.size.height - kMargen);
    _etiquetaPuntaje.text = @"0";
    _etiquetaPuntaje.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    _etiquetaPuntaje.zPosition = CapaUI;
    [_nodoMundo addChild:_etiquetaPuntaje];
}


-(void)update:(CFTimeInterval)currentTime
{
    _dt = (_ultimaVez? currentTime - _ultimaVez: 0);
    _ultimaVez = currentTime;
    
    switch (_estadoJuego) {
        case EstadoJuegoMenuPrincipal:
        break;
            
        case EstadoJuegoTutorial:
        break;
            
        case EstadoJuegoJugar:
            [self actualizarJugador];
            [self actualizarFondo];
            [self verificarChocoFondo];
            [self verificarChocoObstaculo];
        break;
            
        case EstadoJuegoColision:
            [self verificarChocoFondo];
            [self actualizarJugador];
        break;
            
        case EstadoJuegoMostandoPuntaje:
        break;
            
        case EstadoJuegoGameOver:
        break;
            
        default:
            break;
    }
    
}

- (void)cambiarAMostrarPuntaje
{
    _estadoJuego = EstadoJuegoMostandoPuntaje;
    [_jugador removeAllActions];
    [self detenerActualizar];
}

- (void)verificarChocoFondo
{
    if (_chocoFondo) {
        _chocoFondo = NO;
        _velocidadJugador = CGPointZero;
        _jugador.zRotation = DegreesToRadians(-90);
        _jugador.position = CGPointMake(_jugador.position.x, _limiteComienzo + _jugador.size.width);
        [self runAction:_accionChoco];
        [self cambiarAMostrarPuntaje];
    }
}

- (void)verificarChocoObstaculo
{
    if (_chocoObstaculo) {
        _chocoObstaculo = NO;
        [self cambiarCaidaLibre];
    }
}

- (void)cambiarCaidaLibre
{
    _estadoJuego = EstadoJuegoColision;
    [self runAction:[SKAction sequence:@[_accionChoco,[SKAction waitForDuration:0.1],_accionCaer]]];
    [_jugador removeAllActions];
    [self detenerActualizar];
}

- (void)cambiarANuevoJuego
{
    SKScene *newScene = [[FNCMyScene alloc]initWithSize:self.size];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScene transition:transition];
}

- (void)cambiarAGameOver
{
    _estadoJuego = EstadoJuegoGameOver;
}

- (void)cambiarATutorial
{
    _estadoJuego = EstadoJuegoTutorial;
    [self asignarFondo];
    [self asignarJugador];
    [self asignarEtiquetaPuntaje];
    [self asignarSonidos];
    [self asignarTutorial];
}

- (void)cambiarAJugar
{
    _estadoJuego = EstadoJuegoJugar;
    [_nodoMundo enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]
                                             ]]];
    }];
    
    [self actualizarObstaculos];
    [self flapNyanCat];
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

#pragma mark - Contact Delegates
- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *otro = (contact.bodyA.categoryBitMask == categoriaEntidadJugador ? contact.bodyB : contact.bodyA);
    
    if (otro.categoryBitMask == categoriaEntidadFondo) {
        _chocoFondo = YES;
        return;
    }
    
    if (otro.categoryBitMask == categoriaEntidadObstaculo) {
        _chocoObstaculo = YES;
        return;
    }
    
    
}



@end
