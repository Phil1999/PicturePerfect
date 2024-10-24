//
//  GameScene.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    unowned let context: GameContext
    var gameInfo: GameInfo { context.gameInfo }
    var layoutInfo: LayoutInfo { context.layoutInfo }
    
    var playState: PlayState?

    init(context: GameContext, size: CGSize) {
        self.context = context
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        context.stateMachine?.enter(MemorizeState.self)
        
        // Enable user interaction
        self.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PlayState {
            playState.touchesBegan(touches, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PlayState {
            playState.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let playState = context.stateMachine?.currentState as? PlayState {
            playState.touchesEnded(touches, with: event)
        }
    }
}
