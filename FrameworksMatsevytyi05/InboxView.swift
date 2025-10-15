//
//  InboxView.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 14.10.2025.
//

import SwiftUI

struct InboxView: View {
    
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        List(notificationService.inbox) { notification in
            HStack {
                VStack(alignment: .leading) {
                    Text(notification.title)
                        .font(.headline)
                    Text(notification.due, style: .date)
                }
                Spacer()
                statusIcon(for: notification.status)
            }
            .background(bgColor(for: notification.status))
        }
        .navigationTitle("Вхідні")
    }
    
    func statusIcon(for status: NotificationStatus) -> some View {
        switch status {
        case .pending: return Image(systemName: "questionmark.circle").foregroundColor(.yellow)
        case .accepted: return Image(systemName: "checkmark.circle").foregroundColor(.green)
        case .declined: return Image(systemName: "xmark.circle").foregroundColor(.red)
        }
    }
    func bgColor(for status: NotificationStatus) -> Color {
        switch status {
        case .pending: return Color.clear
        case .accepted: return Color.green.opacity(0.1)
        case .declined: return Color.red.opacity(0.1)
        }
    }
}
