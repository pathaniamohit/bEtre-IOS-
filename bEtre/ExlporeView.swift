import SwiftUI
import Firebase
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImageSwiftUI

struct Post: Identifiable {
    var id: String
    var content: String
    var timestamp: TimeInterval
    var userId: String
    var location: String
    var imageUrl: String
    var isReported: Bool
    var countLike: Int
    var countComment: Int
    var username: String = ""
    var email: String = ""
    var profileImageUrl: String = ""
}

struct Comment: Identifiable {
    var id: String
    var content: String
    var timestamp: TimeInterval
    var userId: String
    var username: String
}

struct User: Identifiable {
    var id: String
    var username: String
    var bio: String
    var email: String
    var gender: String
    var phone: String
    var profileImageUrl: String
    var role: String
}

struct ExploreView: View {
    @State private var posts: [Post] = []
    @State private var likedPosts: Set<String> = []
    @State private var followingUsers: Set<String> = []
    @State private var currentUserId = Auth.auth().currentUser?.uid ?? ""
    @State private var isCommentSheetPresented: Bool = false
    @State private var selectedPostID: String?

    var body: some View {
        ScrollView {
            ForEach(posts) { post in
                VStack(alignment: .leading) {
                    HStack {
                        // Display Profile Image of the Post Owner
                        if let url = URL(string: post.profileImageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }

                        // Display Username and Email
                        VStack(alignment: .leading) {
                            Text(post.username)
                                .font(.headline)
                            Text(post.email)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        // Follow/Unfollow Button
                        Button(action: {
                            toggleFollow(userId: post.userId)
                        }) {
                            Text(followingUsers.contains(post.userId) ? "Unfollow" : "Follow")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }

                    // Post Image
                    if let url = URL(string: post.imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    }

                    // Post Actions (Like, Comment, Report)
                    HStack {
                        Button(action: {
                            toggleLike(postId: post.id)
                        }) {
                            Image(systemName: likedPosts.contains(post.id) ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                        }
                        Text("\(post.countLike)")

                        Button(action: {
                            selectedPostID = post.id
                            isCommentSheetPresented.toggle()
                        }) {
                            Image(systemName: "message")
                        }
                        Text("\(post.countComment)")

                        Button(action: {
                            reportPost(postId: post.id)
                        }) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    }

                    // Post Description and Location
                    Text(post.content)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    Text(post.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .onAppear(perform: loadPosts)
        .sheet(isPresented: $isCommentSheetPresented) {
            if let postId = selectedPostID {
                CommentView(postId: postId)
            }
        }
    }

    // Fetch Posts from Firebase, including owner username, email, and profile image URL
    func loadPosts() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var loadedPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postDict = snapshot.value as? [String: Any] {
                    var post = Post(
                        id: snapshot.key,
                        content: postDict["content"] as? String ?? "",
                        timestamp: postDict["timestamp"] as? TimeInterval ?? 0,
                        userId: postDict["userId"] as? String ?? "",
                        location: postDict["location"] as? String ?? "",
                        imageUrl: postDict["imageUrl"] as? String ?? "",
                        isReported: postDict["is_reported"] as? Bool ?? false,
                        countLike: postDict["count_like"] as? Int ?? 0,
                        countComment: postDict["count_comment"] as? Int ?? 0
                    )
                    
                    fetchUserData(for: post.userId) { username, email, profileImageUrl in
                        post.username = username
                        post.email = email
                        post.profileImageUrl = profileImageUrl
                        loadedPosts.append(post)
                        self.posts = loadedPosts
                    }
                }
            }
        }
    }

    // Fetch User Data (username, email, profile image URL) using userId
    func fetchUserData(for userId: String, completion: @escaping (String, String, String) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                let username = userData["username"] as? String ?? "Unknown User"
                let email = userData["email"] as? String ?? "No Email"
                
                // Fetch profile image URL from Firebase Storage
                let profileImageRef = Storage.storage().reference().child("users/\(userId)/profile.jpg")
                profileImageRef.downloadURL { url, _ in
                    completion(username, email, url?.absoluteString ?? "")
                }
            } else {
                completion("Unknown User", "No Email", "")
            }
        }
    }

    // Toggle Follow/Unfollow and update followers/following in Realtime Database
    func toggleFollow(userId: String) {
        let followingRef = Database.database().reference().child("following").child(currentUserId).child(userId)
        let followersRef = Database.database().reference().child("followers").child(userId).child(currentUserId)

        if followingUsers.contains(userId) {
            // Unfollow: Remove user from following and followers
            followingRef.removeValue()
            followersRef.removeValue()
            followingUsers.remove(userId)
        } else {
            // Follow: Add user to following and followers
            followingRef.setValue(true)
            followersRef.setValue(true)
            followingUsers.insert(userId)
            sendFollowNotification(to: userId)
        }
    }

    // Toggle Like
    func toggleLike(postId: String) {
        let ref = Database.database().reference().child("likes").child(postId).child(currentUserId)
        if likedPosts.contains(postId) {
            ref.removeValue()
            likedPosts.remove(postId)
            decrementLikeCount(for: postId)
        } else {
            ref.setValue(true)
            likedPosts.insert(postId)
            incrementLikeCount(for: postId)
            sendLikeNotification(for: postId)
        }
    }

    // Report Post
    func reportPost(postId: String) {
        let ref = Database.database().reference().child("reports").child(postId).child(currentUserId)
        ref.setValue("Inappropriate content")
    }

    // Send Follow Notification
    func sendFollowNotification(to userId: String) {
        let notificationRef = Database.database().reference().child("notifications").child(userId)
        let notificationId = notificationRef.childByAutoId().key ?? UUID().uuidString
        let notificationData: [String: Any] = [
            "type": "follow",
            "userId": currentUserId,
            "timestamp": Date().timeIntervalSince1970
        ]
        notificationRef.child(notificationId).setValue(notificationData)
    }

    // Send Like Notification
    func sendLikeNotification(for postId: String) {
        let postRef = Database.database().reference().child("posts").child(postId)
        postRef.child("userId").observeSingleEvent(of: .value) { snapshot in
            if let postOwnerId = snapshot.value as? String, postOwnerId != currentUserId {
                let notificationRef = Database.database().reference().child("notifications").child(postOwnerId)
                let notificationId = notificationRef.childByAutoId().key ?? UUID().uuidString
                let notificationData: [String: Any] = [
                    "type": "like",
                    "userId": currentUserId,
                    "postId": postId,
                    "timestamp": Date().timeIntervalSince1970
                ]
                notificationRef.child(notificationId).setValue(notificationData)
            }
        }
    }

    // Increment Like Count
    func incrementLikeCount(for postId: String) {
        let postRef = Database.database().reference().child("posts").child(postId).child("count_like")
        postRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value += 1
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
    }

    // Decrement Like Count
    func decrementLikeCount(for postId: String) {
        let postRef = Database.database().reference().child("posts").child(postId).child("count_like")
        postRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value = max(0, value - 1)
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }
    }
}

struct CommentView: View {
    let postId: String
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""

    var body: some View {
        VStack {
            List(comments) { comment in
                VStack(alignment: .leading) {
                    Text(comment.username).font(.headline)
                    Text(comment.content).font(.body)
                    Text(Date(timeIntervalSince1970: comment.timestamp), style: .time).font(.caption)
                }
            }

            HStack {
                TextField("Add a comment...", text: $newCommentText)
                Button("Send") {
                    addComment()
                }
            }.padding()
        }
        .onAppear(perform: loadComments)
    }

    // Load Comments for Post
    func loadComments() {
        let commentsRef = Database.database().reference().child("comments").child(postId)
        commentsRef.observe(.value) { snapshot in
            var loadedComments: [Comment] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let commentDict = snapshot.value as? [String: Any] {
                    let comment = Comment(
                        id: snapshot.key,
                        content: commentDict["content"] as? String ?? "",
                        timestamp: commentDict["timestamp"] as? TimeInterval ?? 0,
                        userId: commentDict["userId"] as? String ?? "",
                        username: commentDict["username"] as? String ?? ""
                    )
                    loadedComments.append(comment)
                }
            }
            self.comments = loadedComments
        }
    }

    // Add New Comment
    func addComment() {
        guard !newCommentText.isEmpty else { return }
        let commentsRef = Database.database().reference().child("comments").child(postId)
        let commentId = commentsRef.childByAutoId().key ?? UUID().uuidString
        
        let newComment: [String: Any] = [
            "content": newCommentText,
            "timestamp": Date().timeIntervalSince1970,
            "userId": Auth.auth().currentUser?.uid ?? "",
            "username": Auth.auth().currentUser?.displayName ?? "Anonymous"
        ]
        
        commentsRef.child(commentId).setValue(newComment)
        newCommentText = ""
    }

}
