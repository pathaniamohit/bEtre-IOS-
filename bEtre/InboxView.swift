import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

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
                    notification.description
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
        print("Loading notifications for user: \(currentUserId)")
        var loadedNotifications: [Notification] = []
        let dispatchGroup = DispatchGroup()
        
        // Load follow notifications
        dispatchGroup.enter()
        loadFollowNotifications { followNotifications in
            loadedNotifications.append(contentsOf: followNotifications)
            dispatchGroup.leave()
        }
        
        // Load like notifications
        dispatchGroup.enter()
        loadLikeNotifications { likeNotifications in
            loadedNotifications.append(contentsOf: likeNotifications)
            dispatchGroup.leave()
        }
        
        // Load comment notifications
        dispatchGroup.enter()
        loadCommentNotifications { commentNotifications in
            loadedNotifications.append(contentsOf: commentNotifications)
            dispatchGroup.leave()
        }
        
        // Update UI after all notifications are loaded
        dispatchGroup.notify(queue: .main) {
            self.notifications = loadedNotifications.sorted(by: { $0.timestamp > $1.timestamp })
            print("Final notifications: \(self.notifications)")
        }
    }
    
    func loadFollowNotifications(completion: @escaping ([Notification]) -> Void) {
        let followersRef = Database.database().reference().child("followers").child(currentUserId)
        let dispatchGroup = DispatchGroup()
        var followNotifications: [Notification] = []
        
        followersRef.observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let isFollowing = snapshot.value as? Bool, isFollowing {
                    let followerId = snapshot.key
                    dispatchGroup.enter()
                    
                    fetchUsername(for: followerId) { username in
                        let notification = Notification(
                            id: UUID().uuidString,
                            type: .follow,
                            userId: followerId,
                            timestamp: Date().timeIntervalSince1970,
                            username: username
                        )
                        followNotifications.append(notification)
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(followNotifications)
            }
        }
    }
    
    func loadLikeNotifications(completion: @escaping ([Notification]) -> Void) {
        let likesRef = Database.database().reference().child("likes")
        let dispatchGroup = DispatchGroup()
        var likeNotifications: [Notification] = []
        
        print("Fetching likes from 'likes' node")
        
        // Access each postId in the "likes" node
        likesRef.observeSingleEvent(of: .value) { snapshot in
            for postSnapshot in snapshot.children {
                if let postSnapshot = postSnapshot as? DataSnapshot {
                    let postId = postSnapshot.key
                    print("Found post with ID: \(postId)")
                    
                    // Retrieve the post owner userId directly from the "likes/{postId}/ownerId" path
                    if let postOwnerId = postSnapshot.childSnapshot(forPath: "ownerId").value as? String {
                        print("Post owner ID for post \(postId): \(postOwnerId)")
                        
                        // Check if the current user is the owner of the post
                        if postOwnerId == currentUserId {
                            print("Current user is the owner of post \(postId)")
                            
                            // Loop through each userId under this post's "users" in the likes node
                            let usersSnapshot = postSnapshot.childSnapshot(forPath: "users")
                            for userSnapshot in usersSnapshot.children {
                                if let userSnapshot = userSnapshot as? DataSnapshot {
                                    let likerUserId = userSnapshot.key
                                    let likedAt = userSnapshot.childSnapshot(forPath: "likedAt").value as? TimeInterval ?? Date().timeIntervalSince1970
                                    dispatchGroup.enter()
                                    
                                    // Fetch the username of the liker from the "users" node
                                    fetchUsername(for: likerUserId) { likerUsername in
                                        print("\(likerUsername) liked your post \(postId)")
                                        
                                        let notification = Notification(
                                            id: UUID().uuidString,
                                            type: .like,
                                            userId: likerUserId,
                                            postId: postId,
                                            timestamp: likedAt,
                                            username: likerUsername
                                        )
                                        
                                        likeNotifications.append(notification)
                                        dispatchGroup.leave()
                                    }
                                }
                            }
                        } else {
                            print("Post \(postId) does not belong to the current user, skipping.")
                        }
                    } else {
                        print("Error: Could not retrieve ownerId for post ID: \(postId)")
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                print("All like notifications loaded: \(likeNotifications)")
                completion(likeNotifications)
            }
        }
    }

//    // Helper function to fetch a username based on userId
//    func fetchUsername(for userId: String, completion: @escaping (String) -> Void) {
//        let userRef = Database.database().reference().child("users").child(userId)
//        userRef.observeSingleEvent(of: .value) { snapshot in
//            let username = snapshot.childSnapshot(forPath: "username").value as? String ?? "Unknown User"
//            completion(username)
//        }
//    }



//    // Helper function to fetch a username based on userId
//    func fetchUsername(for userId: String, completion: @escaping (String) -> Void) {
//        let userRef = Database.database().reference().child("users").child(userId)
//        userRef.observeSingleEvent(of: .value) { snapshot in
//            if snapshot.exists() {
//                let username = snapshot.childSnapshot(forPath: "username").value as? String ?? "Unknown User"
//                print("Fetched username: \(username) for userId: \(userId)")
//                completion(username)
//            } else {
//                print("Error: No user found for userId \(userId)")
//                completion("Unknown User")
//            }
//        }
//    }

    
    func loadCommentNotifications(completion: @escaping ([Notification]) -> Void) {
        let commentsRef = Database.database().reference().child("comments")
        let dispatchGroup = DispatchGroup()
        var commentNotifications: [Notification] = []
        
        print("Fetching comments for posts owned by user: \(currentUserId)")
        
        commentsRef.observeSingleEvent(of: .value) { snapshot in
            for commentSnapshot in snapshot.children {
                if let commentSnapshot = commentSnapshot as? DataSnapshot,
                   let commentData = commentSnapshot.value as? [String: Any],
                   let postId = commentData["post_Id"] as? String,
                   let commenterId = commentData["userId"] as? String,
                   let commentContent = commentData["content"] as? String,
                   let timestamp = commentData["timestamp"] as? TimeInterval {
                    
                    // Fetch post to verify ownership
                    dispatchGroup.enter()
                    let postRef = Database.database().reference().child("posts").child(postId)
                    
                    postRef.observeSingleEvent(of: .value) { postSnapshot in
                        guard let postData = postSnapshot.value as? [String: Any],
                              let postOwnerId = postData["userId"] as? String else {
                            print("Error: Could not retrieve post owner for post ID: \(postId)")
                            dispatchGroup.leave()
                            return
                        }
                        
                        if postOwnerId == currentUserId {
                            print("Adding comment notification for post ID \(postId)")
                            
                            // Fetch the username of the commenter
                            fetchUsername(for: commenterId) { commenterUsername in
                                let notification = Notification(
                                    id: UUID().uuidString,
                                    type: .comment,
                                    userId: commenterId,
                                    postId: postId,
                                    timestamp: timestamp,
                                    username: commenterUsername,
                                    commentContent: commentContent  // Include comment content
                                )
                                
                                commentNotifications.append(notification)
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                print("All comment notifications loaded: \(commentNotifications)")
                completion(commentNotifications)
            }
        }
    }



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
    var username: String = "Unknown User"
    var commentContent: String? = nil  // New property for the comment content
    
    var description: Text {
        switch type {
        case .follow:
            return Text("\(username) started following you.")
        case .like:
            return Text("\(username) liked your post.")
        case .comment:
            // Show the comment content with blue styling
            return Text("\(username) commented: ").font(.headline) +
                   Text(commentContent ?? "").foregroundColor(.blue)
        case .unfollow:
            return Text("\(username) unfollowed you.")
        case .report:
            return Text("\(username) reported your post.")
        }
    }
    
    init(id: String, type: NotificationType, userId: String, postId: String? = nil, timestamp: TimeInterval, username: String = "Unknown User", commentContent: String? = nil) {
        self.id = id
        self.type = type
        self.userId = userId
        self.postId = postId
        self.timestamp = timestamp
        self.username = username
        self.commentContent = commentContent
    }
}

