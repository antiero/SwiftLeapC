//
//  GameScene.swift
//  LeapDemoSwift
//
//  Originally Created by Kelly Innes on 10/27/15. Modified by Antony Nasce 05/05/2023
//  Copyright (c) 2015 Kelly Innes. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let rightHandSprite = SKSpriteNode(imageNamed: "righthand")
    let leftHandSprite = SKSpriteNode(imageNamed: "lefthand")
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor.darkGray
        rightHandSprite.xScale = 1
        rightHandSprite.yScale = 1
        rightHandSprite.physicsBody?.collisionBitMask = 0
        rightHandSprite.physicsBody?.categoryBitMask = 1
        rightHandSprite.physicsBody?.contactTestBitMask = 1
        rightHandSprite.colorBlendFactor = 1
        rightHandSprite.zPosition = 2
        leftHandSprite.xScale = 1
        leftHandSprite.yScale = 1
        leftHandSprite.physicsBody?.collisionBitMask = 0
        leftHandSprite.physicsBody?.categoryBitMask = 1
        leftHandSprite.physicsBody?.contactTestBitMask = 1
        leftHandSprite.colorBlendFactor = 1
        leftHandSprite.zPosition = 1
        
        addChild(rightHandSprite)
        addChild(leftHandSprite)
    }
        
    override func update(_ currentTime: TimeInterval) {
        updateHandPositions()
    }
    
    func updateHandPositions() {
        
        let handManager = LeapMotionManager.sharedInstance
        
        if (handManager.rightHandPresent()){
            rightHandSprite.colorBlendFactor = 1
            if handManager.isHandPointing(hand: handManager.rightHand!) {
                rightHandSprite.texture = SKTexture(imageNamed: "pointRight")
            }
            else{
                rightHandSprite.color = .white
                rightHandSprite.texture = SKTexture(imageNamed: "rightHand")
            }
        }
        else{
            rightHandSprite.color = .clear
        }
        
        if let newRightHandPosition = handManager.rightHandPosition {
            let newRightHandX = newRightHandPosition.x
            let newRightHandY = newRightHandPosition.y
            rightHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newRightHandX), y: self.size.height/2 + CGFloat(newRightHandY/2))
            if (handManager.rightIsPinching()){
                rightHandSprite.color = NSColor(red: 0.35, green: 0.13, blue: 0.82, alpha: 1.0)
                rightHandSprite.texture = SKTexture(imageNamed: "pinchRight")
            }
        }
        
        if (handManager.leftHandPresent()){
            leftHandSprite.colorBlendFactor = 1
            if handManager.isHandPointing(hand: handManager.leftHand!) {
                leftHandSprite.texture = SKTexture(imageNamed: "pointLeft")
            }
            else{
                leftHandSprite.color = .white
                leftHandSprite.texture = SKTexture(imageNamed: "leftHand")
            }
        }
        else{
            leftHandSprite.color = .clear
        }

        if let newLeftHandPosition = handManager.leftHandPosition {
            let newLeftHandX = newLeftHandPosition.x
            let newLeftHandY = newLeftHandPosition.y
            leftHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newLeftHandX), y: self.size.height/2 + CGFloat(newLeftHandY/2))
            if (handManager.leftIsPinching()){
                leftHandSprite.color = NSColor(red: 0.05, green: 0.92, blue: 0.48, alpha: 1.0)
                leftHandSprite.texture = SKTexture(imageNamed: "pinchLeft")
            }
        }
    }
}
