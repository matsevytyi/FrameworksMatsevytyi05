//
//  NotificationService.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 14.10.2025.
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    var permissionPending: Bool = true
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission granted: \(granted)")
            if granted { self.permissionPending = false }
        }
    }
    
    // Schedule notification for a Task/Subtask
    func scheduleNotification(id: String, title: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Завдання закінчується!"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("Заплановано сповіщення на \(dueDate)")
    }
    
    // Cancel notification for a Task/Subtask by identifier
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("Скасовано сповіщення для \(id)")
    }
}
