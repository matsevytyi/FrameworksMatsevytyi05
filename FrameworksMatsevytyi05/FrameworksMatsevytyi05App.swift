//
//  FrameworksMatsevytyi05App.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 07.10.2025.
//

import SwiftUI
import Security

@main
struct FrameworksMatsevytyi05App: App {
    let persistenceController = PersistenceController.shared
    let authenticated = false
    
    init() {
        prepareNotifications()
        print(getFromKeyChain())
        addToKeyChain()
        print(getFromKeyChain())
    }

    var body: some Scene {
        WindowGroup {
            if let _ = getFromKeyChain() {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView()
            }
        }
    }
    
    func getFromKeyChain() -> String?{
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "username",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
            if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == noErr,
               let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
            return nil
    }
    
    func addToKeyChain() {

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "username",
            kSecValueData as String: "password".data(using: .utf8)!
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: "password".data(using: .utf8)!
        ]

        let status: OSStatus
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            var newItem = query
            newItem[kSecValueData as String] = "password".data(using: .utf8)!
            status = SecItemAdd(newItem as CFDictionary, nil)
        }

        if status == errSecSuccess {
            print("query saved")
        } else {
            print("Error saving: \(status)")
        }
    }

    
//    private func checkLogin(){
//        let username = KeychainService.shared.get(key: "username"),
//        let password = KeychainService.shared.get(key: "password")
//    }
    
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
