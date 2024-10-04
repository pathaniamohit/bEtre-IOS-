//
//  bEtreApp.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//

import SwiftUI
import FirebaseCore

@main
struct bEtreApp: App {
    init() {
        FirebaseApp.configure()
        print("Configured Firebase!")
    }
    var body: some Scene {
        
        WindowGroup {
            SplashScreenView()
            
        }
        
    }
}
