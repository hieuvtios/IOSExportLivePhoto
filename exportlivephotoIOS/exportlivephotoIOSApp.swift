//
//  exportlivephotoIOSApp.swift
//  exportlivephotoIOS
//
//  Created by Hieu Vu on 6/12/24.
//

import SwiftUI

@main
struct exportlivephotoIOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LivePhotoCreationView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
