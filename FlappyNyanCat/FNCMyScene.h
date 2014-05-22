//
//  FNCMyScene.h
//  FlappyNyanCat
//

//  Copyright (c) 2014 Jaime Yesid Leon Parada. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(int, EstadoJuego) {
    EstadoJuegoMenuPrincipal,
    EstadoJuegoTutorial,
    EstadoJuegoJugar,
    EstadoJuegoColision,
    EstadoJuegoMostandoPuntaje,
    EstadoJuegoGameOver
};

@interface FNCMyScene : SKScene <SKPhysicsContactDelegate>


@end
