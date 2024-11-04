import SwiftUI
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

enum NotificationType: String {
    case follow
    case unfollow
    case like
    case comment
    case report
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
    @State private var isReportDialogPresented: Bool = false
    @State private var reportReason: String = ""
    
    var body: some View {
        ScrollView {
            Text("Explore")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
                .padding(.bottom, 10)
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
                            toggleLike(postId: post.id, postOwnerId: post.userId)
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
                            selectedPostID = post.id
                            isReportDialogPresented = true
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
        .alert("Report Post", isPresented: $isReportDialogPresented, actions: {
            TextField("Reason for reporting...", text: $reportReason)
            Button("Submit", action: submitReport)
            Button("Cancel", role: .cancel, action: { isReportDialogPresented = false })
        }, message: {
            Text("Please specify your reason for reporting this post.")
        })
        .sheet(isPresented: $isCommentSheetPresented) {
            if let postId = selectedPostID, let postOwnerId = getPostOwnerId(for: postId) {
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
                
                if followedUsers.isEmpty {
                    // If the user is following no one, fetch all posts except those from the current user
                    self.fetchAllPostsExcludingCurrentUser()
                } else {
                    // Fetch posts only from followed users who exist in the `users` node
                    self.fetchPostsFromFollowedUsers(followedUsers) { postsFound in
                        if !postsFound {
                            // If no posts are found, fallback to fetching all posts excluding the current user's posts
                            self.fetchAllPostsExcludingCurrentUser()
                        }
                    }
                }
            }
        }
    
    func getPostOwnerId(for postId: String) -> String? {
        posts.first { $0.id == postId }?.userId
    }
    
    // Fetch Posts Only from Followed Users with Callback for Existence Check
        func fetchPostsFromFollowedUsers(_ followedUsers: Set<String>, completion: @escaping (Bool) -> Void) {
            let ref = Database.database().reference().child("posts")
            ref.observeSingleEvent(of: .value) { snapshot in
                var loadedPosts: [Post] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let postDict = snapshot.value as? [String: Any],
                       let userId = postDict["userId"] as? String,
                       followedUsers.contains(userId) {
                        
                        checkUserExists(userId: userId) { exists in
                            guard exists else { return } // Skip post if user doesn't exist
                            
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
                            
                            fetchUserData(for: userId) { username, profileImageUrl in
                                post.username = username
                                post.profileImageUrl = profileImageUrl
                                loadedPosts.append(post)
                                self.posts = loadedPosts
                            }
                        }
                    }
                }
                
                // Complete with `true` if posts were found, otherwise `false`
                completion(!loadedPosts.isEmpty)
            }
        }
        
        // Check if a user exists in the `users` node
        func checkUserExists(userId: String, completion: @escaping (Bool) -> Void) {
            let userRef = Database.database().reference().child("users").child(userId)
            
            userRef.observeSingleEvent(of: .value) { snapshot in
                completion(snapshot.exists())
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
                       let userId = postDict["userId"] as? String,
                       userId != currentUserId {
                        
                        checkUserExists(userId: userId) { exists in
                            guard exists else { return } // Skip post if user doesn't exist
                            
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
                            
                            fetchUserData(for: userId) { username, profileImageUrl in
                                post.username = username
                                post.profileImageUrl = profileImageUrl
                                loadedPosts.append(post)
                                self.posts = loadedPosts
                            }
                        }
                    }
                }
            }
        }
        // Fetch User Data (username, profileImageUrl) using userId
        func fetchUserData(for userId: String, completion: @escaping (String, String) -> Void) {
            let userRef = Database.database().reference().child("users").child(userId)
            
            userRef.observeSingleEvent(of: .value) { snapshot in
                if let userData = snapshot.value as? [String: Any] {
                    let username = userData["username"] as? String ?? "Unknown User"
                    let profileImageUrl = userData["profileImageUrl"] as? String ?? ""
                    completion(username, profileImageUrl)
                } else {
                    completion("Unknown User", "")
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
        }
    }
    
    func toggleLike(postId: String, postOwnerId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        let likeRef = ref.child("likes").child(postId).child("users").child(userId)
        let postLikesRef = ref.child("likes").child(postId)

        if likedPosts.contains(postId) {
            // Unlike the post
            likeRef.removeValue { error, _ in
                if error == nil {
                    likedPosts.remove(postId)
                    updateLikeCount(for: postId, increment: false)

                    // Remove the post owner reference if no users are left liking the post
                    postLikesRef.child("users").observeSingleEvent(of: .value) { snapshot in
                        if !snapshot.exists() {
                            postLikesRef.child("ownerId").removeValue()
                        }
                    }
                    
                    // Toggle the heart icon color
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index].isLiked = false // Update the post state to reflect "unliked"
                    }
                } else {
                    print("Error unliking the post:", error?.localizedDescription ?? "Unknown error")
                }
            }
        } else {
            // Like the post
            let likedAt = Date().timeIntervalSince1970
            let likeData: [String: Any] = ["likedAt": likedAt]
            
            likeRef.setValue(likeData) { error, _ in
                if error == nil {
                    likedPosts.insert(postId)
                    updateLikeCount(for: postId, increment: true)
                    
                    // Set the post owner if it's the first like
                    postLikesRef.child("ownerId").setValue(postOwnerId)
                    
                    // Toggle the heart icon color
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index].isLiked = true // Update the post state to reflect "liked"
                    }
                } else {
                    print("Error liking the post:", error?.localizedDescription ?? "Unknown error")
                }
            }
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
    
    func submitReport() {
        guard let postId = selectedPostID, !reportReason.isEmpty else { return }
        guard let reporterId = Auth.auth().currentUser?.uid else { return }
        
        let reportRef = Database.database().reference().child("reports").childByAutoId()
        let postRef = Database.database().reference().child("posts").child(postId)
        
        // Fetch post content to include in the report (optional)
        postRef.observeSingleEvent(of: .value) { snapshot in
            if let postData = snapshot.value as? [String: Any] {
                let content = postData["content"] as? String ?? ""
                let timestamp = Date().timeIntervalSince1970
                
                let reportData: [String: Any] = [
                    "postId": postId,
                    "reportedBy": reporterId,
                    "reason": reportReason,
                    "timestamp": timestamp,
                    "status": "pending",
                    "content": content
                ]
                
                // Save the report data in the "reports" node
                reportRef.setValue(reportData) { error, _ in
                    if error == nil {
                        reportReason = ""
                        isReportDialogPresented = false
                        print("Report submitted successfully.")
                    } else {
                        print("Failed to submit report:", error?.localizedDescription ?? "Unknown error")
                    }
                }
            } else {
                print("Failed to fetch post details.")
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
    @State private var selectedCommentId: String?
    @State private var reportReason: String = ""
    @State private var isReportDialogPresented: Bool = false

    var body: some View {
        VStack {
            Text("Comments")
                .font(.headline)
                .padding()
            
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
                        
                        // Report Button
                        Button(action: {
                            selectedCommentId = comment.id
                            isReportDialogPresented = true
                        }) {
                            Text("Report")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding()
            .alert("Report Comment", isPresented: $isReportDialogPresented, actions: {
                TextField("Reason for reporting...", text: $reportReason)
                Button("Submit", action: submitCommentReport)
                Button("Cancel", role: .cancel, action: { isReportDialogPresented = false })
            }, message: {
                Text("Please specify your reason for reporting this comment.")
            })
            
            // Add Comment Section
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
        let commentsRef = Database.database().reference().child("comments")
        commentsRef.queryOrdered(byChild: "post_Id").queryEqual(toValue: postId).observe(.value) { snapshot in
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
            self.comments = loadedComments.sorted { $0.timestamp < $1.timestamp }
        }
    }
    
    // Add a New Comment
    func addComment() {
        guard !newCommentText.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let commentsRef = Database.database().reference().child("comments")
        let commentId = commentsRef.childByAutoId().key ?? UUID().uuidString
        
        let userRef = Database.database().reference().child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            let username = snapshot.childSnapshot(forPath: "username").value as? String ?? "Unknown User"
            
            let newCommentData: [String: Any] = [
                "content": self.newCommentText,
                "timestamp": Date().timeIntervalSince1970,
                "userId": userId,
                "username": username,
                "post_Id": self.postId
            ]
            
            commentsRef.child(commentId).setValue(newCommentData) { error, _ in
                if error == nil {
                    self.newCommentText = ""
                    incrementCommentCount()
                }
            }
        }
    }
    
    // Increment Comment Count for the Post
    func incrementCommentCount() {
        let postRef = Database.database().reference().child("posts").child(postId).child("count_comment")
        postRef.runTransactionBlock { currentData in
            var count = currentData.value as? Int ?? 0
            count += 1
            currentData.value = count
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, _, snapshot in
            if let count = snapshot?.value as? Int {
                self.commentCount = count
            }
        }
    }

    // Submit Comment Report
    func submitCommentReport() {
        guard let commentId = selectedCommentId else { return }
        guard let reporterId = Auth.auth().currentUser?.uid else { return }
        
        let reportRef = Database.database().reference().child("report_comments").child(commentId)
        let commentRef = Database.database().reference().child("comments").child(commentId)
        
        commentRef.observeSingleEvent(of: .value) { snapshot in
            if let commentData = snapshot.value as? [String: Any] {
                let reportedCommentUserId = commentData["userId"] as? String ?? ""
                let content = commentData["content"] as? String ?? ""
                let timestamp = commentData["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970

                let reportData: [String: Any] = [
                    "reporterId": reporterId,
                    "reportedCommentUserId": reportedCommentUserId,
                    "postId": postId,
                    "timestamp": Date().timeIntervalSince1970,
                    "reason": reportReason,
                    "status": "pending",
                    "content": content
                ]
                
                reportRef.setValue(reportData) { error, _ in
                    if error == nil {
                        reportReason = ""
                        isReportDialogPresented = false
                        print("Comment reported successfully.")
                    } else {
                        print("Failed to report comment:", error?.localizedDescription ?? "Unknown error")
                    }
                }
            } else {
                print("Failed to fetch comment details.")
            }
        }
    }
}
