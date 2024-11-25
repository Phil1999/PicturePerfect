//
//  EffectManager.swift
//  PixelPainter
//
//  Created by Philip Lee on 10/25/24.
//

import Foundation
import SpriteKit

class EffectManager {
    weak var gameScene: GameScene?
    private var isFlashing = false

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }

    func flashScreen(color: UIColor, alpha: CGFloat) {

        guard let gameScene = gameScene, !isFlashing else { return }  // Prevent overlapping flashes

        isFlashing = true

        // add overlay
        let overlay = SKSpriteNode(color: color, size: gameScene.size)
        overlay.position = CGPoint(
            x: gameScene.size.width / 2, y: gameScene.size.height / 2)
        overlay.zPosition = 9999  // arbitrary value here just want to make it above everything
        overlay.alpha = 0  // Start transparent
        gameScene.addChild(overlay)

        // Flash the screen
        let fadeIn = SKAction.fadeAlpha(to: alpha, duration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.1)
        let remove = SKAction.removeFromParent()
        let flashSequence = SKAction.sequence([
            fadeIn, fadeOut, fadeIn, fadeOut,
            SKAction.run { [weak self] in
                self?.isFlashing = false  // reset flashing status
            },
            remove,
        ])
        overlay.run(flashSequence)
    }

    func shakeNode(
        _ node: SKNode, duration: TimeInterval = 0.05, distance: CGFloat = 10
    ) {
        let shakeLeft = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let shakeRight = SKAction.moveBy(
            x: distance * 2, y: 0, duration: duration)
        let shakeSequence = SKAction.sequence([
            shakeLeft, shakeRight, shakeLeft,
        ])
        node.run(shakeSequence)
    }

    func disableInteraction(for duration: TimeInterval = 1.0) {
        let disableTouchAction = SKAction.run { [weak self] in
            self?.gameScene?.isUserInteractionEnabled = false
        }
        let waitAction = SKAction.wait(forDuration: duration)
        let enableTouchAction = SKAction.run { [weak self] in
            self?.gameScene?.isUserInteractionEnabled = true

        }

        let sequence = SKAction.sequence([
            disableTouchAction, waitAction, enableTouchAction,
        ])
        gameScene?.run(sequence)
    }
    
    // Note that the duration should match with the actual expected duration.
    func cooldown(_ node: SKNode, duration: TimeInterval) {
            // Save original states recursively
            let originalStates = storeNodeStates(node)
            
            // Apply cooldown effect to all nodes
            greyOutNode(node)
            
            // Create cooldown overlay
            let cooldownNode = SKShapeNode(circleOfRadius: 33) // Standard size for power-ups
            cooldownNode.strokeColor = UIColor.white.withAlphaComponent(0.3)
            cooldownNode.lineWidth = 3
            cooldownNode.name = "cooldown"
            
            let startAngle = CGFloat.pi / 2
            let path = CGMutablePath()
            path.addArc(
                center: .zero,
                radius: 33,
                startAngle: startAngle,
                endAngle: startAngle + CGFloat.pi * 2,
                clockwise: true
            )
            cooldownNode.path = path
            node.addChild(cooldownNode)
            
            // Animate cooldown
            let animate = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                guard let cooldown = node as? SKShapeNode else { return }
                let progress = elapsedTime / CGFloat(duration)
                let endAngle = startAngle + (.pi * 2 * progress)
                
                let newPath = CGMutablePath()
                newPath.addArc(
                    center: .zero,
                    radius: 33,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                cooldown.path = newPath
            }
            
            // Reset everything back to original state
            let reset = SKAction.run { [weak self] in
                cooldownNode.removeFromParent()
                self?.restoreNodeStates(node, states: originalStates)
            }
            
            cooldownNode.run(SKAction.sequence([animate, reset]))
        }
        
        private struct NodeState {
            let alpha: CGFloat
            let color: UIColor?                 // For colored nodes
            let fillColor: UIColor?             // For shape nodes
            let strokeColor: UIColor?           // For shape nodes
            let colorBlendFactor: CGFloat       // For sprite nodes
        }
        
        private func storeNodeStates(_ node: SKNode) -> [SKNode: NodeState] {
            var states: [SKNode: NodeState] = [:]
            
            // Store state for current node
            states[node] = NodeState(
                alpha: node.alpha,
                color: (node as? SKSpriteNode)?.color,
                fillColor: (node as? SKShapeNode)?.fillColor,
                strokeColor: (node as? SKShapeNode)?.strokeColor,
                colorBlendFactor: (node as? SKSpriteNode)?.colorBlendFactor ?? 0
            )
            
            // Recursively store states for all children
            node.children.forEach { child in
                states.merge(storeNodeStates(child)) { current, _ in current }
            }
            
            return states
        }
        
        private func greyOutNode(_ node: SKNode) {
            // Set alpha for all nodes
            node.alpha = 0.5
            
            // Handle specific node types
            if let shapeNode = node as? SKShapeNode {
                shapeNode.fillColor = .gray
                shapeNode.strokeColor = .darkGray
            }
            
            if let spriteNode = node as? SKSpriteNode {
                spriteNode.color = .gray
                spriteNode.colorBlendFactor = 0.8
            }
            
            // Recursively grey out children
            node.children.forEach { greyOutNode($0) }
        }
        
        private func restoreNodeStates(_ node: SKNode, states: [SKNode: NodeState]) {
            if let state = states[node] {
                // Restore alpha
                node.alpha = state.alpha
                
                // Restore specific node properties
                if let shapeNode = node as? SKShapeNode {
                    shapeNode.fillColor = state.fillColor ?? .clear
                    shapeNode.strokeColor = state.strokeColor ?? .clear
                }
                
                if let spriteNode = node as? SKSpriteNode {
                    spriteNode.color = state.color ?? .white
                    spriteNode.colorBlendFactor = state.colorBlendFactor
                }
            }
            
            // Recursively restore children
            node.children.forEach { restoreNodeStates($0, states: states) }
        }

}
