import SwiftUI
import Firebase
import FirebaseAuth

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
        notificationRef.observeSingleEvent(of: .value) { snapshot in
            var loadedNotifications: [Notification] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let notificationData = snapshot.value as? [String: Any] {
                    let notificationId = snapshot.key
                    let userId = notificationData["userId"] as? String ?? ""
                    
                    // Fetch the username from the "users" node
                    fetchUsername(for: userId) { username in
                        var notification = Notification(id: notificationId, data: notificationData)
                        notification.username = username // Assign fetched username
                        loadedNotifications.append(notification)
                        
                        // Sort notifications by timestamp
                        self.notifications = loadedNotifications.sorted(by: { $0.timestamp > $1.timestamp })
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
}

struct Notification: Identifiable {
    var id: String
    var type: NotificationType
    var userId: String
    var postId: String?
    var timestamp: TimeInterval
    var username: String = "Unknown User" // Placeholder until fetched
    
    // Use `username` in the description instead of `userId`
    var description: String {
        switch type {
        case .follow: return "\(username) started following you."
        case .unfollow: return "\(username) unfollowed you."
        case .like: return "\(username) liked your post."
        case .comment: return "\(username) commented on your post."
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
