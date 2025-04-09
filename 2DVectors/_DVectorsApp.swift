//
//  _DVectorsApp.swift
//  2DVectors
//
//  Created by Влад Иванов on 14.03.25.
//

import SwiftData
import SwiftUI

@main
struct _DVectorsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Vector.self])
    }
}
