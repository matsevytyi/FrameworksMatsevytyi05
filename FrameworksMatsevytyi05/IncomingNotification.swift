//
//  IncomingNotification.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 14.10.2025.
//


import Foundation


struct IncomingNotification: Identifiable {
    let id: String
    let title: String
    let due: Date
    var status: NotificationStatus
}

enum NotificationStatus {
    case pending
    case accepted
    case declined
}
