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
    CapaUI,
    CapaFlash
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
static const float kAnimDalay = 0.3;
static const int kNumerosNyanCats = 4;
static const float kMinGrados = -90;
static const float kMaxGrados = 25;
static const float kVelocidadAngular = 1000;

@implementation FNCMyScene
{
    SKSpriteNode *_jugador;
    SKNode *_nodoMundo;
    float _limiteComienzo;
    float _limiteAltura;
    float _velocidadAngularJugador;
    
    BOOL _chocoFondo;
    BOOL _chocoObstaculo;
    
    SKAction *_accionFlap;
    SKAction *_accionCaer;
    SKAction *_accionChoco;
    
    SKLabelNode *_etiquetaPuntaje;
    int _puntaje;
    
    NSTimeInterval _ultimaVezToco;
    float _ultimaVezY;
    
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
        [self cambiarAMenuPrincipal];
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

- (void)asignarMejorPuntaje:(int)mejorPuntaje
{
    [[NSUserDefaults standardUserDefaults]setInteger:mejorPuntaje forKey:@"mejorPuntaje"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)asignarScoreCard
{
    if (_puntaje > [self mejorPuntaje]) {
        [self asignarMejorPuntaje:_puntaje];
    }
    SKSpriteNode *scorecard = [SKSpriteNode spriteNodeWithImageNamed:@"Scorecard"];
    scorecard.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
    scorecard.name = @"Tutorial";
    scorecard.zPosition = CapaUI;
    [_nodoMundo addChild:scorecard];
    
    
    SKLabelNode *ultimoPuntaje = [[SKLabelNode alloc]initWithFontNamed:kNombreFont];
    ultimoPuntaje.fontColor = [SKColor blackColor];
    ultimoPuntaje.position = CGPointMake(-scorecard.size.width * 0.25,  -scorecard.size.height * 0.25);
    ultimoPuntaje.text = [NSString stringWithFormat:@"%d", _puntaje];
    [scorecard addChild:ultimoPuntaje];
    
    SKLabelNode *mejorPuntaje = [[SKLabelNode alloc]initWithFontNamed:kNombreFont];
    mejorPuntaje.fontColor = [SKColor blackColor];
    mejorPuntaje.position = CGPointMake(scorecard.size.width * 0.25,  -scorecard.size.height * 0.25);
    mejorPuntaje.text = [NSString stringWithFormat:@"%d", [self mejorPuntaje]];
    [scorecard addChild:mejorPuntaje];
    
    SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithImageNamed:@"GameOver"];
    gameOver.position = CGPointMake(self.size.width/2, self.size.height/2 + scorecard.size.height/2 + kMargen + gameOver.size.height/2);
    gameOver.zPosition = CapaUI;
    [_nodoMundo addChild:gameOver];
    
    SKSpriteNode *botonOK = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    botonOK.position = CGPointMake(self.size.width * 0.25, self.size.height/2 -scorecard.size.height -kMargen -botonOK.size.height/2);
    botonOK.zPosition = CapaUI;
    [_nodoMundo addChild:botonOK];
    
    SKSpriteNode *ok = [SKSpriteNode spriteNodeWithImageNamed:@"OK"];
    ok.position = CGPointZero;
    ok.zPosition = CapaUI;
    [botonOK addChild:ok];
    
    SKSpriteNode *botonCompartir = [SKSpriteNode spriteNodeWithImageNamed:@"Button"];
    botonCompartir.position = CGPointMake(self.size.width * 0.75, self.size.height/2 -scorecard.size.height -kMargen -botonCompartir.size.height/2);
    botonCompartir.zPosition = CapaUI;
    [_nodoMundo addChild:botonCompartir];
    
    SKSpriteNode *compartir = [SKSpriteNode spriteNodeWithImageNamed:@"Share"];
    compartir.position = CGPointZero;
    compartir.zPosition = CapaUI;
    [botonCompartir addChild:compartir];
    
    gameOver.scale = 0;
    gameOver.alpha = 0;
    
    SKAction *group = [SKAction group:@[
                                        [SKAction fadeInWithDuration:kAnimDalay],
                                        [SKAction scaleTo:1.0 duration:kAnimDalay]
                                        ]];
    group.timingMode = SKActionTimingEaseInEaseOut;
    [gameOver runAction:[SKAction sequence:@[
                                             [SKAction fadeInWithDuration:kAnimDalay],
                                             group
                                             ]]];
    scorecard.position = CGPointMake(self.size.width * 0.5, -scorecard.size.height/2);
    
    SKAction *moverA = [SKAction moveTo:CGPointMake(self.size.width/2, self.size.height/2) duration:kAnimDalay];
    moverA.timingMode = SKActionTimingEaseInEaseOut;
    [scorecard runAction:[SKAction sequence:@[
                                              [SKAction waitForDuration:kAnimDalay*2],
                                              moverA
                                              ]]];
    
    
    botonOK.alpha = 0;
    botonCompartir.alpha = 0;
    
    SKAction *mostrar = [SKAction sequence:@[
                                             [SKAction waitForDuration:kAnimDalay*3],
                                             [SKAction fadeInWithDuration:kAnimDalay]
                                             ]];
    [botonOK runAction:mostrar];
    [botonCompartir runAction:mostrar];
    
    SKAction *aparecer = [SKAction sequence:@[
                                              [SKAction waitForDuration:kAnimDalay],
                                              _accionChoco,
                                              [SKAction waitForDuration:kAnimDalay],
                                              _accionChoco,
                                              [SKAction waitForDuration:kAnimDalay],
                                              _accionChoco,
                                              [SKAction runBlock:^{
        [self cambiarAGameOver];
    }],
                                              ]];
    
    [self runAction:aparecer];
}

- (void)asignarMenuPrincipal
{
    SKSpriteNode *logo = [SKSpriteNode spriteNodeWithImageNamed:@"Logo"];
    logo.position = CGPointMake(self.size.width / 2, self.size.height *0.8);
    logo.zPosition = CapaUI;
    logo.name = @"MenuP";
    [_nodoMundo addChild:logo];
    
    SKSpriteNode *botonPlay = [SKSpriteNode spriteNodeWithImageNamed:@"Button.png"];
    botonPlay.position = CGPointMake(self.size.width * 0.25, self.size.height * 0.35);
    botonPlay.zPosition = CapaUI;
    botonPlay.name = @"MenuP";
    [_nodoMundo addChild:botonPlay];
    
    SKSpriteNode *play = [SKSpriteNode spriteNodeWithImageNamed:@"Play"];
    play.position = CGPointMake(0, 0);
    [botonPlay addChild:play];
    
    SKSpriteNode *botonRate = [SKSpriteNode spriteNodeWithImageNamed:@"Button.png"];
    botonRate.position = CGPointMake(self.size.width * 0.75, self.size.height * 0.35);
    botonRate.zPosition = CapaUI;
    botonRate.name = @"MenuP";
    [_nodoMundo addChild:botonRate];
    
    SKSpriteNode *rate = [SKSpriteNode spriteNodeWithImageNamed:@"Rate"];
    rate.position = CGPointMake(0, 0);
    [botonRate addChild:rate];
    
    SKSpriteNode *aprender = [SKSpriteNode spriteNodeWithImageNamed:@"button_learn"];
    aprender.position = CGPointMake(self.size.width * 0.5, aprender.size.height / 2 + kMargen + 50);
    aprender.zPosition = CapaUI;
    aprender.name = @"MenuP";
    [_nodoMundo addChild:aprender];
    
    SKAction *scaleUp = [SKAction scaleTo:1.0 duration:0.75];
    scaleUp.timingMode = SKActionTimingEaseInEaseOut;
    SKAction *scaleDown = [SKAction scaleTo:0.98 duration:0.75];
    scaleDown.timingMode = SKActionTimingEaseInEaseOut;
    
    [aprender runAction:[SKAction repeatActionForever:[SKAction sequence:@[scaleUp, scaleDown]]]];
}

- (void)asignarAnimacionJugador
{
    NSMutableArray *texturas = [NSMutableArray array];
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"sprites"];
    
    for (int i = 0; i < kNumerosNyanCats; i++) {
        NSString *nombreTexturas = [NSString stringWithFormat:@"Cat%d",i];
        [texturas addObject:[atlas textureNamed:nombreTexturas]];
    }
    
    for (int i = kNumerosNyanCats - 2; i > 0; i--) {
        NSString *nombreTexturas = [NSString stringWithFormat:@"Cat%d",i];
        [texturas addObject:[atlas textureNamed:nombreTexturas]];
    }
    
    SKAction *animacionJugador = [SKAction animateWithTextures:texturas timePerFrame:0.07];
    [_jugador runAction:[SKAction repeatActionForever:animacionJugador]];
    
}

#pragma mark - Actualizar

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

- (void)actualizarPuntaje
{
    [_nodoMundo enumerateChildNodesWithName:@"ObstaculoInferior" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *obstaculo = (SKSpriteNode*)node;
        NSNumber *paso = obstaculo.userData[@"Paso"];
        
        if (paso && paso.boolValue) {
            return;
        }
        
        if (_jugador.position.x > obstaculo.position.x + obstaculo.size.width/2) {
            _puntaje++;
            _etiquetaPuntaje.text = [NSString stringWithFormat:@"%d", _puntaje];
            obstaculo.userData[@"Paso"] = @YES;
        }
    }];
}


- (void)actualizarJugador
{
    CGPoint gravedad = CGPointMake(0, kGravedad);
    CGPoint pasoGravedad = CGPointMultiplyScalar(gravedad, _dt);
    _velocidadJugador = CGPointAdd(_velocidadJugador, pasoGravedad);
    
    CGPoint pasoVelocidad = CGPointMultiplyScalar(_velocidadJugador, _dt);
    _jugador.position = CGPointAdd(_jugador.position, pasoVelocidad);
    
    
    if (_jugador.position.y < _ultimaVezY) {
        _velocidadAngularJugador = -DegreesToRadians(kVelocidadAngular);
    }
    
    float pasoAngular = _velocidadAngularJugador * _dt;
    _jugador.zRotation += pasoAngular;
    _jugador.zRotation = MIN(MAX(_jugador.zRotation, DegreesToRadians(kMinGrados)), DegreesToRadians(kMaxGrados));
    
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


#pragma mark - Cambiar

- (void)cambiarAMostrarPuntaje
{
    _estadoJuego = EstadoJuegoMostandoPuntaje;
    [_jugador removeAllActions];
    [self detenerActualizar];
    [self asignarScoreCard];
}

- (void)cambiarCaidaLibre
{
    _estadoJuego = EstadoJuegoColision;
    
    SKAction *terremoto = [SKAction skt_screenShakeWithNode:_nodoMundo amount:CGPointMake(0, 7.0) oscillations:10 duration:1.0];
    [_nodoMundo runAction:terremoto];
    
    SKSpriteNode *nodoBlanco = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:self.size];
    nodoBlanco.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
    nodoBlanco.zPosition = CapaFlash;
    [_nodoMundo addChild:nodoBlanco];
    [nodoBlanco runAction:[SKAction sequence:@[
                                               [SKAction waitForDuration:0.01],
                                               [SKAction removeFromParent]
                                               ]]];
    
    
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
    [self asignarAnimacionJugador];
    
    [_nodoMundo enumerateChildNodesWithName:@"MenuP" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.3],
                                             [SKAction removeFromParent]
                                             ]]];
    }];
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

- (void)cambiarAMenuPrincipal
{
    _estadoJuego = EstadoJuegoMenuPrincipal;
    [self asignarFondo];
    [self asignarSonidos];
    [self asignarMenuPrincipal];
    [self asignarAnimacionJugador];
}


#pragma mark Verificar

- (void)verificarChocoFondo
{
    if (_chocoFondo) {
        _chocoFondo = NO;
        _velocidadJugador = CGPointZero;
        _jugador.zRotation = DegreesToRadians(-90);
        _jugador.position = CGPointMake(_jugador.position.x, _limiteComienzo + _jugador.size.width/2);
        
        [self cambiarAMostrarPuntaje];
    }
}

- (void)verificarChocoObstaculo
{
    if(_chocoObstaculo)
    {
        _chocoObstaculo = NO;
        _velocidadJugador = CGPointZero;
        _jugador.zRotation = DegreesToRadians(-90);
        _jugador.Position = CGPointMake(_jugador.position.x, _limiteComienzo + _jugador.size.width/2);
        [self cambiarCaidaLibre];
        [self cambiarAMostrarPuntaje];
    }

}

- (void)flapNyanCat
{
    [self runAction:_accionFlap];
    _velocidadJugador = CGPointMake(0, kImpulso);
    _velocidadAngularJugador = DegreesToRadians(kVelocidadAngular);
    _ultimaVezToco = _ultimaVez;
    _ultimaVezY = _jugador.position.y;
}


- (SKSpriteNode *)crearObstaculo
{
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Cactus"];
    sprite.zPosition = CapaObstaculo;
    sprite.userData = [NSMutableDictionary dictionary];
    
    
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
    UITouch *touch = [touches anyObject];
    CGPoint touchLugar = [touch locationInNode:self];
    
    
    switch (_estadoJuego) {
        case EstadoJuegoMenuPrincipal:
            if (touchLugar.y < self.size.width * 0.35) {
                [self aprender];
            }else if (touchLugar.x < self.size.width * 0.6){
                [self cambiarATutorial];
            }
            
            
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
            [self cambiarANuevoJuego];
            break;
            
        default:
            break;
    }
}






-(void)update:(CFTimeInterval)currentTime
{
 
    /*
    _dt = (_ultimaVez? currentTime - _ultimaVez: 0);
    _ultimaVez = currentTime;
    */
    
    if (_ultimaVez) {
        _dt = currentTime - _ultimaVez;
    } else {
        _dt = 0;
    }

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
            [self actualizarPuntaje];
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

- (int)mejorPuntaje
{
    return [[NSUserDefaults standardUserDefaults]integerForKey:@"mejorPuntaje"];
}


- (void)aprender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http:www.koombea.com"]]];
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
