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
    var leftHasPinched : Bool = false
    var rightHasPinched : Bool = false
    var initialPinchLeftPosX : Float = 0
    var initialPinchRightPosX : Float = 0
    let handSliderMoveThreshold : Float = 1
    
    var scoreValue: Int = 0
    var scoreLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor.darkGray
        rightHandSprite.xScale = 1
        rightHandSprite.yScale = 1
        rightHandSprite.colorBlendFactor = 1
        rightHandSprite.zPosition = 2
        rightHandSprite.color = .white
        leftHandSprite.xScale = 1
        leftHandSprite.yScale = 1
        leftHandSprite.colorBlendFactor = 1
        leftHandSprite.zPosition = 1
        leftHandSprite.color = .white
        
        scoreLabel = SKLabelNode()
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
        addChild(rightHandSprite)
        addChild(leftHandSprite)
    }
        
    override func update(_ currentTime: TimeInterval) {
        updateHandPositions()
    }

    func decrementSlider(){
        scoreValue -= 1
        scoreLabel.text = "Score: " + String(describing: scoreValue)

    }

    func incrementSlider(){
        scoreValue += 1
        scoreLabel.text = "Score: " + String(describing: scoreValue)
    }
    
    func updateHandPositions() {
        
        let handManager = LeapMotionManager.sharedInstance
        
        if (handManager.rightHandPresent()){
            rightHandSprite.color = .white
            if let newRightHandPosition = handManager.rightHandPosition {
                let newRightHandX = newRightHandPosition.x
                let newRightHandY = newRightHandPosition.y
                rightHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newRightHandX), y: self.size.height/2 + CGFloat(newRightHandY/2))
                
                if (handManager.rightIsPinching()){
                    //rightHandSprite.color = NSColor(red: 0.35, green: 0.13, blue: 0.82, alpha: 1.0)
                    rightHandSprite.texture = SKTexture(imageNamed: "pinchRight")

                        //set the initial pinch as the starting point
                        if (!rightHasPinched)
                        {
                            initialPinchRightPosX = Float(rightHandSprite.position.x)
                            rightHasPinched = true;
                        }
                        if (Float(rightHandSprite.position.x) > (initialPinchRightPosX + handSliderMoveThreshold))
                        {
                            incrementSlider()
                        }
                        else if (Float(rightHandSprite.position.x) < initialPinchRightPosX - handSliderMoveThreshold)
                        {
                            decrementSlider()
                        }
                }
                
                else if handManager.isHandPointing(hand: handManager.rightHand!) {
                    rightHasPinched = false
                    rightHandSprite.texture = SKTexture(imageNamed: "pointRight")
                }
                else{
                    rightHasPinched = false
                    rightHandSprite.texture = SKTexture(imageNamed: "rightHand")
                }
            }
        }
        else{
            rightHasPinched = false
            rightHandSprite.color = .clear
        }
        
        if (handManager.leftHandPresent()){
            leftHandSprite.color = .white
            if let newLeftHandPosition = handManager.leftHandPosition {
                let newLeftHandX = newLeftHandPosition.x
                let newLeftHandY = newLeftHandPosition.y
                leftHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newLeftHandX), y: self.size.height/2 + CGFloat(newLeftHandY/2))
                
                if (handManager.leftIsPinching()){
                    //leftHandSprite.color = NSColor(red: 0.05, green: 0.92, blue: 0.48, alpha: 1.0)
                    leftHandSprite.texture = SKTexture(imageNamed: "pinchLeft")
                    
                    //set the initial pinch as the starting point
                    if (!leftHasPinched)
                    {
                        initialPinchLeftPosX = Float(leftHandSprite.position.x)
                        leftHasPinched = true;
                    }
                    if (Float(leftHandSprite.position.x) > (initialPinchLeftPosX + handSliderMoveThreshold))
                    {
                        incrementSlider()
                    }
                    else if (Float(leftHandSprite.position.x) < initialPinchLeftPosX - handSliderMoveThreshold)
                    {
                        decrementSlider()
                    }
                }
                else if handManager.isHandPointing(hand: handManager.leftHand!) {
                    leftHandSprite.texture = SKTexture(imageNamed: "pointLeft")
                    leftHasPinched = false
                }
                else{
                    leftHandSprite.texture = SKTexture(imageNamed: "leftHand")
                    leftHasPinched = false
                }
            }
        }
        else{
            leftHasPinched = false
            leftHandSprite.color = .clear
        }
    }
}
