//
//  LeapDemoVisionOSApp.swift
//  LeapDemoVisionOS
//
//  Created by Antony Nasce on 30/06/2023.
//  Copyright © 2023 Kelly Innes. All rights reserved.
//

import SwiftUI

@main
struct LeapDemoVisionOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
