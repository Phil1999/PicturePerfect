//
//  PlayState.swift
//  PixelPainter
//
//  Created by Tim Hsieh on 10/22/24.
//

import GameplayKit
import SpriteKit

class PlayState: GKState {
    unowned let gameScene: GameScene
    let gridManager: GridManager
    let bankManager: BankManager
    let hudManager: HUDManager
    var powerUpManager: PowerUpManager!
    
    init(gameScene: GameScene) {
        self.gameScene = gameScene
        self.gridManager = GridManager(gameScene: gameScene)
        self.bankManager = BankManager(gameScene: gameScene)
        self.hudManager = HUDManager(gameScene: gameScene)
        super.init()
        self.powerUpManager = PowerUpManager(gameScene: gameScene, playState: self)
    }
    
    override func didEnter(from previousState: GKState?) {
        setupPlayScene()
        startTimer()
    }
    
    override func willExit(to nextState: GKState) {
        gameScene.removeAllChildren()
        gameScene.removeAction(forKey: "updateTimer")
    }
    
    private func setupPlayScene() {
        gridManager.createGrid()
        bankManager.createPictureBank()
        hudManager.createHUD()
        powerUpManager.setupPowerUps()
        gameScene.context.gameInfo.timeRemaining = 60
    }
    
    func startTimer() {
        let updateTimerAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.hudManager.updateTimer()
            },
            SKAction.wait(forDuration: 1.0)
        ])
        gameScene.run(SKAction.repeatForever(updateTimerAction), withKey: "updateTimer")
    }
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gameScene)
        
        // Check for power-up touches
        if powerUpManager.handleTouch(at: location) {
            return
        }
        
        // Handle piece selection in bank
        if let bankNode = bankManager.bankNode,
           bankNode.contains(location) {
            let bankLocation = bankNode.convert(location, from: gameScene)
            if let touchedPiece = bankNode.nodes(at: bankLocation)
                .first(where: { $0.name?.starts(with: "piece_") == true }) as? SKSpriteNode {
                bankManager.selectPiece(touchedPiece)
            }
            return
        }
        
        // Handle grid placement
        if let gridNode = gameScene.childNode(withName: "grid") as? SKSpriteNode,
           let selectedPiece = bankManager.getSelectedPiece(),
           gridNode.contains(location) {
            let gridLocation = gridNode.convert(location, from: gameScene)
            if gridManager.tryPlacePiece(selectedPiece, at: gridLocation) {
                hudManager.updateScore()
                bankManager.clearSelection()
                bankManager.refreshBankIfNeeded()
                
                if gameScene.context.gameInfo.score == 9 {
                    gameScene.context.stateMachine?.enter(GameOverState.self)
                }
            }
        }
    }

    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}

class PowerUpManager {
    weak var gameScene: GameScene?
    weak var playState: PlayState?
    private var powerUps: [PowerUpType: SKNode] = [:]
    
    init(gameScene: GameScene, playState: PlayState) {
        self.gameScene = gameScene
        self.playState = playState
    }
    
    func setupPowerUps() {
        guard let gameScene = gameScene else { return }
        
        let powerUpTypes: [PowerUpType] = [.timeStop, .place, .flash]
        let spacing: CGFloat = 80
        let startX = gameScene.size.width - CGFloat(powerUpTypes.count) * spacing
        
        for (index, type) in powerUpTypes.enumerated() {
            let powerUp = createPowerUpNode(type: type)
            powerUp.position = CGPoint(x: startX + CGFloat(index) * spacing, y: gameScene.size.height - 50)
            gameScene.addChild(powerUp)
            powerUps[type] = powerUp
        }
    }
    
    private func createPowerUpNode(type: PowerUpType) -> SKNode {
        let container = SKNode()
        
        let circle = SKShapeNode(circleOfRadius: 25)
        circle.fillColor = .blue
        circle.strokeColor = .white
        circle.lineWidth = 2
        container.addChild(circle)
        
        let label = SKLabelNode(text: type.rawValue.prefix(1).uppercased())
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        container.name = "powerup_\(type.rawValue)"
        return container
    }
    
    func handleTouch(at location: CGPoint) -> Bool {
        guard let gameScene = gameScene else { return false }
        
        let touchedNodes = gameScene.nodes(at: location)
        for node in touchedNodes {
            if let powerUpType = getPowerUpType(from: node.name) {
                activatePowerUp(powerUpType)
                return true
            }
        }
        return false
    }
    
    private func getPowerUpType(from nodeName: String?) -> PowerUpType? {
        guard let name = nodeName,
              name.starts(with: "powerup_"),
              let typeString = name.split(separator: "_").last,
              let type = PowerUpType(rawValue: String(typeString)) else {
            return nil
        }
        return type
    }
    
    private func activatePowerUp(_ type: PowerUpType) {
        switch type {
        case .timeStop:
            gameScene?.removeAction(forKey: "updateTimer")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.playState?.startTimer()
            }
        case .place:
            // Auto-place next piece correctly
            if let selectedPiece = gameScene?.context.gameInfo.pieces.first(where: { !$0.isPlaced }) {
                // Implementation for auto-placing piece
            }
        case .flash:
            // Show original image briefly
            if let image = gameScene?.context.gameInfo.currentImage {
                let imageNode = SKSpriteNode(texture: SKTexture(image: image))
                imageNode.position = CGPoint(x: gameScene?.size.width ?? 0 / 2,
                                          y: gameScene?.size.height ?? 0 / 2)
                gameScene?.addChild(imageNode)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    imageNode.removeFromParent()
                }
            }
        }
    }
}