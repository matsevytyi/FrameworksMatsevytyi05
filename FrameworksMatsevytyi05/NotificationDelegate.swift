//
//  NotificationDelegate.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 14.10.2025.
//
import Foundation
import SwiftUI

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let id = userInfo["task_id"] as? String,
           let name = userInfo["task_name"] as? String,
           let dueStr = userInfo["due"] as? String,
           let due = ISO8601DateFormatter().date(from: dueStr) {
            
            NotificationCenter.default.post(name: Notification.Name("didReceiveIncomingNotification"),
                                            object: nil,
                                            userInfo: ["id": id, "name": name, "due": due, "private": false])
            
            switch response.actionIdentifier {
            case "AcceptTODO":
                print("\(name) notification accepted")
                
                NotificationService.shared.inbox.append(IncomingNotification(id: id, title: name, due: due, status: .accepted))
                
                NotificationCenter.default.post(
                        name: Notification.Name("didAcceptInboxTodo"),
                        object: nil,
                        userInfo: ["id": id,"name": name,"due": due, "private": false]
                    )
                
            case "CancelTODO":
                print("\(name) notification cancelled")
                // and here maybe directly update inbox in ContentView or ise NptificationCenter
                NotificationService.shared.inbox.append(IncomingNotification(id: id, title: name, due: due, status: .declined))
            default:
                print("\(name) notification ignored")
            }
        }
        
        completionHandler()
    }

}
