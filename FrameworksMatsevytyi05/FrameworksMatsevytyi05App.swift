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
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                NotificationService.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
