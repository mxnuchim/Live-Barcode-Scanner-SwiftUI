//
//  LiveScannerApp.swift
//  LiveScanner
//
//  Created by Manuchim Oliver on 26/04/2023.
//

import SwiftUI

@main
struct LiveScannerApp: App {
    
    @StateObject private var vm = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .task {
                    await vm.requestDataScannerAccess()
                }
        }
    }
}
