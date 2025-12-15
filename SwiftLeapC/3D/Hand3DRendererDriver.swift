//
//  Hand3DRendererDriver.swift
//  SwiftLeapC
//
//  Renderer abstraction so UI does not depend on SceneKit.
//  SceneKit (and later RealityKit) implement this.
//

import AppKit

protocol Hand3DRendererDriver: AnyObject {
    func attach(to containerView: NSView)
    func detach()
}
