import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct InboxView: View {
    @State private var notifications: [Notification] = []
    @State private var currentUserId = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        VStack {
            Text("Inbox")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            List(notifications) { notification in
                VStack(alignment: .leading) {
                    Text(notification.description)
                        .font(.headline)
                    Text(Date(timeIntervalSince1970: notification.timestamp), style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onAppear(perform: loadNotifications)
        }
    }
    
    func loadNotifications() {
        let notificationRef = Database.database().reference().child("notifications").child(currentUserId)
        
        // Using observe(.value) to enable real-time updates
        notificationRef.observe(.value) { snapshot in
            var loadedNotifications: [Notification] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let notificationData = snapshot.value as? [String: Any] {
                    let notificationId = snapshot.key
                    let senderUserId = notificationData["userId"] as? String ?? ""
                    
                    // Fetch the sender's username
                    fetchUsername(for: senderUserId) { username in
                        var notification = Notification(id: notificationId, data: notificationData)
                        notification.username = username
                        
                        // If it's a comment notification, fetch comment content
                        if notification.type == .comment, let postId = notification.postId, let commentId = notificationData["commentId"] as? String {
                            fetchCommentContent(postId: postId, commentId: commentId) { commentContent in
                                notification.commentContent = commentContent
                                loadedNotifications.append(notification)
                                
                                // Sort notifications by timestamp
                                self.notifications = loadedNotifications.sorted(by: { $0.timestamp > $1.timestamp })
                            }
                        } else {
                            // Non-comment notifications
                            loadedNotifications.append(notification)
                            self.notifications = loadedNotifications.sorted(by: { $0.timestamp > $1.timestamp })
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to fetch a username based on userId
    func fetchUsername(for userId: String, completion: @escaping (String) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            let username = snapshot.childSnapshot(forPath: "username").value as? String ?? "Unknown User"
            completion(username)
        }
    }
    
    // Helper function to fetch the comment content based on postId and commentId
    func fetchCommentContent(postId: String, commentId: String, completion: @escaping (String) -> Void) {
        let commentRef = Database.database().reference().child("comments").child(postId).child(commentId)
        commentRef.observeSingleEvent(of: .value) { snapshot in
            let content = snapshot.childSnapshot(forPath: "content").value as? String ?? "A comment"
            completion(content)
        }
    }
}

struct Notification: Identifiable {
    var id: String
    var type: NotificationType
    var userId: String
    var postId: String?
    var timestamp: TimeInterval
    var username: String = "Unknown User"
    var commentContent: String? // Store the comment content for comment notifications
    
    // Description with dynamic comment content
    var description: String {
        switch type {
        case .follow: return "\(username) started following you."
        case .unfollow: return "\(username) unfollowed you."
        case .like: return "\(username) liked your post."
        case .comment:
            // Show the comment content in the notification description
            return commentContent != nil ? "'\(commentContent!)' has been made on your post." : "\(username) commented on your post."
        case .report: return "\(username) reported your post."
        }
    }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.type = NotificationType(rawValue: data["type"] as? String ?? "") ?? .follow
        self.userId = data["userId"] as? String ?? ""
        self.postId = data["postId"] as? String
        self.timestamp = data["timestamp"] as? TimeInterval ?? 0
    }
}
