//
//  GameScene.swift
//  LeapDemoSwift
//
//  Originally Created by Kelly Innes on 10/27/15. Modified by Antony Nasce 05/05/2023
//  Copyright (c) 2015 Kelly Innes. All rights reserved.
//

import SpriteKit
import SceneKit

class GameScene: SKScene {
    
    let rightHandSprite = SKSpriteNode(imageNamed: "rightHand")
    let leftHandSprite = SKSpriteNode(imageNamed: "leftHand")
    var leftHasPinched : Bool = false
    var rightHasPinched : Bool = false
    var initialPinchLeftPosX : Float = 0
    var initialPinchRightPosX : Float = 0
    let handSliderMoveThreshold : Float = 1
    
    var scoreValue: Int = 0
    var scoreLabel: SKLabelNode!
    
    /// Leap Stuff
    let handManager = LeapHandManager.sharedInstance
    let pinchDetector = LeapPinchDetector.sharedInstance
    let pointingDetector = LeapExtendedFingerDetector.sharedInstance
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor.darkGray
        rightHandSprite.colorBlendFactor = 1
        rightHandSprite.zPosition = 2
        rightHandSprite.color = .systemRed
        rightHandSprite.scale(to: CGSize(width: 128, height: 128))
        leftHandSprite.colorBlendFactor = 1
        leftHandSprite.zPosition = 1
        leftHandSprite.color = .systemBlue
        leftHandSprite.scale(to: CGSize(width: 128, height: 128))
        
        scoreLabel = SKLabelNode()
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
        addChild(leftHandSprite)
        addChild(rightHandSprite)
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
        rightLoop: if (handManager.rightHandPresent()){
            if (handManager.rightHand == nil){
                break rightLoop
            }
            
            
            
            rightHandSprite.color = .white
            if let newRightHandPosition = handManager.rightHandPosition {
                appDelegate.rightHandSphere.position = handManager.rightPalmPosAsSCNVector3()
                
                let newRightHandX = newRightHandPosition.x
                let newRightHandY = newRightHandPosition.y
                rightHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newRightHandX), y: self.size.height/2 + CGFloat(newRightHandY/2))
                
                if (pinchDetector.rightIsPinching()){
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
                
                else if (pointingDetector.isRightHandPointing()) {
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
        
        leftLoop: if (handManager.leftHandPresent()){
            if (handManager.leftHand == nil){
                break leftLoop
            }
            leftHandSprite.color = .white

            if let newLeftHandPosition = handManager.leftHandPosition {
                let newLeftHandX = newLeftHandPosition.x
                let newLeftHandY = newLeftHandPosition.y
                leftHandSprite.position = CGPoint(x: self.size.width/2 + CGFloat(newLeftHandX), y: self.size.height/2 + CGFloat(newLeftHandY/2))
                
                appDelegate.leftHandSphere.position = handManager.leftPalmPosAsSCNVector3()
                
                if (pinchDetector.leftIsPinching()){
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
                else if (pointingDetector.isLeftHandPointing()) {
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
