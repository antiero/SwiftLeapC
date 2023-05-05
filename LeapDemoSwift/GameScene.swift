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
        rightHandSprite.xScale = 0.25
        rightHandSprite.yScale = 0.25
        rightHandSprite.physicsBody?.collisionBitMask = 0
        rightHandSprite.physicsBody?.categoryBitMask = 1
        rightHandSprite.physicsBody?.contactTestBitMask = 1
        rightHandSprite.colorBlendFactor = 1
        rightHandSprite.zPosition = 2
        leftHandSprite.xScale = 0.25
        leftHandSprite.yScale = 0.25
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
        
        if (LeapMotionManager.sharedInstance.rightHandPresent()){
            rightHandSprite.colorBlendFactor = 1
        }
        else{
            rightHandSprite.color = .clear
        }
        
        if let newRightHandPosition = LeapMotionManager.sharedInstance.rightHandPosition {
            var newRightHandX = newRightHandPosition.x
            var newRightHandY = newRightHandPosition.y
            if newRightHandX > 225.0 {
                newRightHandX = 225.0
            } else if newRightHandX < -225.0 {
                newRightHandX = -225.0
            }
            if newRightHandY < 100.0 {
                newRightHandY = 100.0
            } else if newRightHandY > 500.0 {
                newRightHandY = 500.0
            }
            rightHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newRightHandX), y: self.size.height/2 + CGFloat(newRightHandY/2))
            if (LeapMotionManager.sharedInstance.rightIsPinching()){
                rightHandSprite.color = NSColor(red: 0.35, green: 0.13, blue: 0.82, alpha: 1.0)
                rightHandSprite.texture = SKTexture(imageNamed: "pinchRight")
            }
            else{
                rightHandSprite.color = .white
                rightHandSprite.texture = SKTexture(imageNamed: "righthand")
            }
        }
        
        if (LeapMotionManager.sharedInstance.leftHandPresent()){
            leftHandSprite.colorBlendFactor = 1
        }
        else{
            leftHandSprite.color = .clear
        }

        
        if let newLeftHandPosition = LeapMotionManager.sharedInstance.leftHandPosition {
            var newLeftHandX = newLeftHandPosition.x
            var newLeftHandY = newLeftHandPosition.y
            if newLeftHandX > 225.0 {
                newLeftHandX = 225.0
            } else if newLeftHandX < -225.0 {
                newLeftHandX = -225.0
            }
            if newLeftHandY < 100.0 {
                newLeftHandY = 100.0
            } else if newLeftHandY > 500.0 {
                newLeftHandY = 500.0
            }
            leftHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newLeftHandX), y: self.size.height/2 + CGFloat(newLeftHandY/2))
            if (LeapMotionManager.sharedInstance.leftIsPinching()){
                leftHandSprite.color = NSColor(red: 0.05, green: 0.92, blue: 0.48, alpha: 1.0)
                leftHandSprite.texture = SKTexture(imageNamed: "pinchLeft")
            }
            else{
                leftHandSprite.color = .white
                leftHandSprite.texture = SKTexture(imageNamed: "lefthand")
            }
        }
   
    }
}
