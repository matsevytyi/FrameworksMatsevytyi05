//
//  FrameworksMatsevytyi05App.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 07.10.2025.
//

import SwiftUI

@main
struct FrameworksMatsevytyi05App: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        prepareNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func prepareNotifications(){
        
        NotificationService.shared.requestAuthorization()
        
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared // for local&remote
        
        // for remote
        let acceptAction = UNNotificationAction(
            identifier: "AcceptTODO",
            title: "Прийняти"
        )
        
        let deleteAction = UNNotificationAction(
            identifier: "CancelTODO",
            title: "Відмінити"
        )
        
        let category = UNNotificationCategory(
            identifier: "HW6Category",
            actions: [acceptAction, deleteAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
