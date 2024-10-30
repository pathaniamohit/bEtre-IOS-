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
    var isLiked: Bool = false
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
    @State private var selectedPostCommentCount: Int = 0

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
                            selectedPostCommentCount = post.countComment
                            isCommentSheetPresented.toggle()
                        }) {
                            Image(systemName: "message")
                        }

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
        .onAppear(perform: loadFollowingAndPosts)
        .sheet(isPresented: $isCommentSheetPresented) {
            if let postId = selectedPostID {
                CommentView(postId: postId, commentCount: $selectedPostCommentCount)
            }
        }
    }
    // Load Following Users and Fetch Posts Based on Following Status
        func loadFollowingAndPosts() {
            let followingRef = Database.database().reference().child("following").child(currentUserId)
            
            followingRef.observeSingleEvent(of: .value) { snapshot in
                var followedUsers: Set<String> = []
                
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot, childSnapshot.value as? Bool == true {
                        followedUsers.insert(childSnapshot.key)
                    }
                }
                
                self.followingUsers = followedUsers
                
                // Fetch posts based on following list
                if followedUsers.isEmpty {
                    // Fetch all posts excluding current user's posts if no following
                    self.fetchAllPostsExcludingCurrentUser()
                } else {
                    // Fetch posts only from followed users
                    self.fetchPostsFromFollowedUsers()
                }
            }
        }

        // Fetch Posts Only from Followed Users
        func fetchPostsFromFollowedUsers() {
            let ref = Database.database().reference().child("posts")
            ref.observeSingleEvent(of: .value) { snapshot in
                var loadedPosts: [Post] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let postDict = snapshot.value as? [String: Any],
                       let userId = postDict["userId"] as? String, followingUsers.contains(userId) {
                        
                        var post = Post(
                            id: snapshot.key,
                            content: postDict["content"] as? String ?? "",
                            timestamp: postDict["timestamp"] as? TimeInterval ?? 0,
                            userId: userId,
                            location: postDict["location"] as? String ?? "",
                            imageUrl: postDict["imageUrl"] as? String ?? "",
                            isReported: postDict["is_reported"] as? Bool ?? false,
                            countLike: postDict["count_like"] as? Int ?? 0,
                            countComment: postDict["count_comment"] as? Int ?? 0,
                            isLiked: likedPosts.contains(snapshot.key)
                        )
                        
                        fetchUserData(for: userId) { username, email, profileImageUrl in
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
    
    // Fetch All Posts Excluding Current User's Posts
    func fetchAllPostsExcludingCurrentUser() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var loadedPosts: [Post] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postDict = snapshot.value as? [String: Any],
                   let userId = postDict["userId"] as? String, userId != currentUserId {
                    
                    var post = Post(
                        id: snapshot.key,
                        content: postDict["content"] as? String ?? "",
                        timestamp: postDict["timestamp"] as? TimeInterval ?? 0,
                        userId: userId,
                        location: postDict["location"] as? String ?? "",
                        imageUrl: postDict["imageUrl"] as? String ?? "",
                        isReported: postDict["is_reported"] as? Bool ?? false,
                        countLike: postDict["count_like"] as? Int ?? 0,
                        countComment: postDict["count_comment"] as? Int ?? 0
                    )
                    
                    fetchUserData(for: userId) { username, email, profileImageUrl in
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
            let ref = Database.database().reference()
            let likeRef = ref.child("likes").child(postId).child(currentUserId)
            let postRef = ref.child("posts").child(postId)
            
            if likedPosts.contains(postId) {
                // Unlike the post
                likeRef.removeValue()
                likedPosts.remove(postId)
                updateLikeCount(for: postId, increment: false)
            } else {
                // Like the post
                likeRef.setValue(true)
                likedPosts.insert(postId)
                updateLikeCount(for: postId, increment: true)
            }
            
            // Toggle the `isLiked` status on the corresponding post in `posts` array
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].isLiked.toggle()
            }
        }

        // Update Like Count in Firebase
        func updateLikeCount(for postId: String, increment: Bool) {
            let postRef = Database.database().reference().child("posts").child(postId).child("count_like")
            
            postRef.runTransactionBlock { currentData in
                var value = currentData.value as? Int ?? 0
                value = increment ? value + 1 : max(0, value - 1)
                currentData.value = value
                return TransactionResult.success(withValue: currentData)
            } andCompletionBlock: { error, _, snapshot in
                if let value = snapshot?.value as? Int {
                    if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                        self.posts[index].countLike = value
                    }
                }
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
    @Binding var commentCount: Int
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Comments")
                .font(.headline)
                .padding()

            // List of Existing Comments
            ScrollView {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.username)
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text(comment.content)
                            .font(.body)
                        Text(Date(timeIntervalSince1970: comment.timestamp), style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding()

            // Add New Comment
            HStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .bottom])
                
                Button(action: addComment) {
                    Text("Post")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding([.trailing, .bottom])
            }
        }
        .onAppear(perform: loadComments)
    }

    // Load Comments for the Post
    func loadComments() {
        let commentsRef = Database.database().reference().child("comments").child(postId)
        commentsRef.observe(.value) { snapshot in
            var loadedComments: [Comment] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let commentData = snapshot.value as? [String: Any] {
                    let comment = Comment(
                        id: snapshot.key,
                        content: commentData["content"] as? String ?? "",
                        timestamp: commentData["timestamp"] as? TimeInterval ?? 0,
                        userId: commentData["userId"] as? String ?? "",
                        username: commentData["username"] as? String ?? "Anonymous"
                    )
                    loadedComments.append(comment)
                }
            }
            
            // Update the comments list
            self.comments = loadedComments.sorted { $0.timestamp < $1.timestamp }
        }
    }

    // Add a New Comment with the User's Actual Username
    func addComment() {
        guard !newCommentText.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let commentsRef = Database.database().reference().child("comments").child(postId)
        let commentId = commentsRef.childByAutoId().key ?? UUID().uuidString

        // Fetch the user's username from the "users" node
        let userRef = Database.database().reference().child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { snapshot, _ in
            let username = snapshot.childSnapshot(forPath: "username").value as? String ?? "Unknown User"

            // Prepare the comment data
            let newCommentData: [String: Any] = [
                "content": self.newCommentText,
                "timestamp": Date().timeIntervalSince1970,
                "userId": userId,
                "username": username
            ]

            // Save the comment data to Firebase
            commentsRef.child(commentId).setValue(newCommentData) { error, _ in
                if error == nil {
                    // Update the comment count in the post node
                    self.newCommentText = ""
                }
            }
        }
    }

    // Increment the Comment Count for the Post
    func incrementCommentCount() {
        let postRef = Database.database().reference().child("posts").child(postId).child("count_comment")
        
        postRef.runTransactionBlock { currentData in
            var count = currentData.value as? Int ?? 0
            count += 1
            currentData.value = count
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, _, snapshot in
            if let count = snapshot?.value as? Int {
                // Update the comment count in the parent view
                self.commentCount = count
            }
        }
    }
}
