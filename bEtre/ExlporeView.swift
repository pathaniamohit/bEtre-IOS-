import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImageSwiftUI

struct IdentifiableString: Identifiable {
    let id: String
}

struct UserPost: Identifiable {
    var id: String
    var content: String
    var imageUrl: String
    var location: String
    var timestamp: TimeInterval
    var userId: String
    var username: String
    var profileImageUrl: String = ""
    var email: String
    var countLike: Int = 0
    var countComment: Int = 0
    var isLiked: Bool = false
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.content = data["content"] as? String ?? ""
        self.imageUrl = data["imageUrl"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.timestamp = data["timestamp"] as? TimeInterval ?? 0
        self.userId = data["userId"] as? String ?? ""
        self.username = data["username"] as? String ?? "Unknown"
        self.email = data["email"] as? String ?? ""
        self.countLike = data["count_like"] as? Int ?? 0
        self.countComment = data["count_comment"] as? Int ?? 0
    }
}

struct ExploreView: View {
    @State private var posts: [UserPost] = []
    @State private var selectedUserId: IdentifiableString? = nil
    private var ref: DatabaseReference = Database.database().reference()

    var body: some View {
            NavigationView {
                VStack {
                    Text("bEtre")
                        .font(.largeTitle)
                        .bold()
                        .padding()

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach($posts) { $post in
                                PostCardView(
                                    post: $post,
                                    updateLikeStatus: updateLikeStatus,
                                    toggleFollowStatus: toggleFollowStatus,
                                    addComment: addComment,
                                    openUserProfile: { userId in selectedUserId = IdentifiableString(id: userId) },
                                    reportPost: reportPost
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear(perform: fetchPosts)
                }
                .sheet(item: $selectedUserId) { identifiableUserId in
                    UserProfileView(userId: identifiableUserId.id)
                }
            }
        }

    func fetchPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        ref.child("following").child(currentUserId).observeSingleEvent(of: .value) { snapshot in
            var followedUserIds: [String] = []
            if let followingDict = snapshot.value as? [String: Any] {
                followedUserIds = Array(followingDict.keys)
            }

            if followedUserIds.isEmpty {
                // If no one is followed, fetch all posts
                fetchAllPosts { fetchedPosts in
                    self.posts = fetchedPosts.sorted(by: { $0.timestamp > $1.timestamp })
                }
            } else {
                // If following others, fetch posts of followed users only
                fetchPostsForUsers(userIds: followedUserIds) { fetchedPosts in
                    self.posts = fetchedPosts.sorted(by: { $0.timestamp > $1.timestamp })
                }
            }
        }
    }

    private func fetchAllPosts(completion: @escaping ([UserPost]) -> Void) {
        var allPosts: [UserPost] = []

        ref.child("posts").observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postData = snapshot.value as? [String: Any] {
                    var post = UserPost(id: snapshot.key, data: postData)
                    
                    // Fetch user data for each post
                    fetchUserData(for: post.userId) { userData in
                        if let userData = userData {
                            post.username = userData.username
                            post.profileImageUrl = userData.profileImageUrl
                            post.email = userData.email
                        }
                        
                        allPosts.append(post)
                        
                        // When all posts are processed, call completion
                        if allPosts.count == snapshot.childrenCount {
                            completion(allPosts)
                        }
                    }
                }
            }
        }
    }

    private func fetchPostsForUsers(userIds: [String], completion: @escaping ([UserPost]) -> Void) {
        var fetchedPosts: [UserPost] = []
        var totalExpectedPosts = 0 // Track the total expected number of posts
        
        for userId in userIds {
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                let postCount = snapshot.childrenCount
                totalExpectedPosts += Int(postCount) // Increment expected count by the posts for this user
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let postData = snapshot.value as? [String: Any] {
                        var post = UserPost(id: snapshot.key, data: postData)
                        
                        // Fetch user details
                        fetchUserData(for: post.userId) { userData in
                            if let userData = userData {
                                post.username = userData.username
                                post.profileImageUrl = userData.profileImageUrl
                                post.email = userData.email
                            }
                            
                            fetchedPosts.append(post) // Append the fetched post
                            
                            // Call completion only when all expected posts have been added
                            if fetchedPosts.count == totalExpectedPosts {
                                completion(fetchedPosts)
                            }
                        }
                    }
                }
                
                // If no posts exist for this user, check completion
                if postCount == 0 && fetchedPosts.count == totalExpectedPosts {
                    completion(fetchedPosts)
                }
            }
        }
    }


    private func fetchUserData(for userId: String, completion: @escaping (UserProfileData?) -> Void) {
        ref.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                let username = userData["username"] as? String ?? "Unknown"
                let email = userData["email"] as? String ?? ""
                
                // Fetch profile image from Firebase Storage
                let profileImagePath = "users/\(userId)/profile.jpg"
                let storageRef = Storage.storage().reference(withPath: profileImagePath)
                
                storageRef.downloadURL { url, error in
                    let profileImageUrl = url?.absoluteString ?? "https://gratisography.com/photo/cool-cat/" // Default image if none exists
                    let profileData = UserProfileData(username: username, email: email, profileImageUrl: profileImageUrl)
                    completion(profileData)
                }
            } else {
                // User data not found
                completion(nil)
            }
        }
    }

    struct UserProfileData {
        var username: String
        var email: String
        var profileImageUrl: String
    }
    
        func toggleFollowStatus(postOwnerId: String, isFollowing: Bool) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let followRef = ref.child("following").child(currentUserId).child(postOwnerId)
            let followersRef = ref.child("followers").child(postOwnerId).child(currentUserId)
            let notificationsRef = ref.child("notifications").child(postOwnerId)

            if isFollowing {
                followRef.removeValue()
                followersRef.removeValue()
                // Add unfollow notification
                let notificationId = notificationsRef.childByAutoId().key
                notificationsRef.child(notificationId ?? "").setValue([
                    "username": Auth.auth().currentUser?.displayName ?? "",
                    "type": "unfollow",
                    "userId": currentUserId,
                    "timestamp": ServerValue.timestamp()
                ])
            } else {
                followRef.setValue(true)
                followersRef.setValue(true)
                // Add follow notification
                let notificationId = notificationsRef.childByAutoId().key
                notificationsRef.child(notificationId ?? "").setValue([
                    "username": Auth.auth().currentUser?.displayName ?? "",
                    "type": "follow",
                    "userId": currentUserId,
                    "timestamp": ServerValue.timestamp()
                ])
            }
        }

        // Update like status and add notification
        func updateLikeStatus(postId: String, isLiked: Bool, postOwnerId: String) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let likesRef = ref.child("likes").child(postId).child(currentUserId)
            let postRef = ref.child("posts").child(postId)
            let notificationsRef = ref.child("notifications").child(postOwnerId)

            if isLiked {
                likesRef.setValue(true)
                postRef.child("count_like").setValue(ServerValue.increment(1))
                // Add like notification
                let notificationId = notificationsRef.childByAutoId().key
                notificationsRef.child(notificationId ?? "").setValue([
                    "username": Auth.auth().currentUser?.displayName ?? "",
                    "type": "like",
                    "userId": currentUserId,
                    "timestamp": ServerValue.timestamp()
                ])
            } else {
                likesRef.removeValue()
                postRef.child("count_like").setValue(ServerValue.increment(-1))
            }
        }

        // Report a post
        func reportPost(postId: String, reportContent: String) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let reportRef = ref.child("reports").child(postId).child(currentUserId)
            let postRef = ref.child("posts").child(postId)
            
            reportRef.setValue(reportContent)
            postRef.child("is_reported").setValue(true)
        }

        // Add a comment and notification
        func addComment(postId: String, content: String, postOwnerId: String) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let commentsRef = ref.child("comments").child(postId)
            let postRef = ref.child("posts").child(postId)
            let notificationsRef = ref.child("notifications").child(postOwnerId)
            let commentId = commentsRef.childByAutoId().key

            let commentData: [String: Any] = [
                "content": content,
                "timestamp": ServerValue.timestamp(),
                "userId": currentUserId,
                "username": Auth.auth().currentUser?.displayName ?? ""
            ]
            
            // Add comment data
            commentsRef.child(commentId ?? "").setValue(commentData)
            
            // Increment comment count in post
            postRef.child("count_comment").setValue(ServerValue.increment(1))
            
            // Add comment notification
            let notificationId = notificationsRef.childByAutoId().key
            notificationsRef.child(notificationId ?? "").setValue([
                "username": Auth.auth().currentUser?.displayName ?? "",
                "content": content,
                "type": "comment",
                "userId": currentUserId,
                "timestamp": ServerValue.timestamp()
            ])
        }
}

struct PostCardView: View {
    @Binding var post: UserPost
    var updateLikeStatus: (String, Bool, String) -> Void
    var toggleFollowStatus: (String, Bool) -> Void
    var addComment: (String, String, String) -> Void
    var openUserProfile: (String) -> Void
    var reportPost: (String, String) -> Void

    @State private var isFollowing = false  // Track follow status of post owner
    @State private var isLiked = false      // Track like status

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let profileImageUrl = URL(string: post.profileImageUrl) {
                    WebImage(url: profileImageUrl)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                VStack(alignment: .leading) {
                    Text(post.username)
                        .bold()
                        .onTapGesture { openUserProfile(post.userId) }
                    Text(post.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    toggleFollowStatus(post.userId, isFollowing)
                    isFollowing.toggle()
                }) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(.subheadline)
                        .padding(5)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .onAppear { checkFollowStatus() }
            }
            
            if let url = URL(string: post.imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(10)
            }

            HStack(spacing: 20) {
                Button(action: {
                    isLiked.toggle()
                    updateLikeStatus(post.id, isLiked, post.userId)
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .primary)
                }
                Text("\(post.countLike)")

                Button(action: {
                    // Code for adding a comment (open a comment input dialog)
                }) {
                    Image(systemName: "message")
                }
                Text("\(post.countComment)")
                
                Button(action: {
                    // Report post with content
                    reportPost(post.id, "Inappropriate content")
                }) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    Text(post.location)
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 8)
            
            Text(post.content)
                .font(.body)
                .padding(.vertical, 4)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private func checkFollowStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let followRef = Database.database().reference().child("following").child(currentUserId).child(post.userId)
        followRef.observeSingleEvent(of: .value) { snapshot in
            isFollowing = snapshot.exists()
        }
    }
}
