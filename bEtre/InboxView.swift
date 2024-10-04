//
//  InboxView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI

struct Message: Identifiable {
    var id = UUID()
    var senderName: String
    var isAdminOrModerator: Bool
    var messagePreview: String
    var isNewMessage: Bool
}

struct InboxView: View {
    // Sample messages data
    let messages = [
        Message(senderName: "Admin", isAdminOrModerator: true, messagePreview: "Welcome to the platform!", isNewMessage: true),
        Message(senderName: "Moderator", isAdminOrModerator: true, messagePreview: "Your post has been approved.", isNewMessage: false),
        Message(senderName: "User123", isAdminOrModerator: false, messagePreview: "Hey, how are you?", isNewMessage: true),
        Message(senderName: "User456", isAdminOrModerator: false, messagePreview: "Can we collaborate on this project?", isNewMessage: false)
    ]
    
    var body: some View {
        NavigationView {
            List(messages) { message in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Display the sender name with a special marker for admin/moderator
                        Text(message.senderName)
                            .font(.headline)
                            .foregroundColor(message.isAdminOrModerator ? .red : .primary)
                        
                        // Display a preview of the message
                        Text(message.messagePreview)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Show a new message indicator if applicable
                    if message.isNewMessage {
                        Circle()
                            .foregroundColor(.blue)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Notification")
        }
    }
}

#Preview {
    InboxView()
}
