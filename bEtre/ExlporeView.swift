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

        // Step 1: Fetch the list of users the current user is following
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
    
    func updateLikeStatus(postId: String, isLiked: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let postRef = ref.child("posts").child(postId)
        
        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject] {
                var likedBy = post["likedBy"] as? [String] ?? []
                var countLike = post["count_like"] as? Int ?? 0
                if isLiked {
                    if !likedBy.contains(currentUserId) {
                        likedBy.append(currentUserId)
                        countLike += 1
                    }
                } else {
                    if let index = likedBy.firstIndex(of: currentUserId) {
                        likedBy.remove(at: index)
                        countLike -= 1
                    }
                }
                post["likedBy"] = likedBy as AnyObject
                post["count_like"] = countLike as AnyObject
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        })
    }
    
    func toggleFollowStatus(postOwnerId: String, isFollowing: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let followRef = ref.child("following").child(currentUserId).child(postOwnerId)
        let followersRef = ref.child("followers").child(postOwnerId).child(currentUserId)

        if isFollowing {
            followRef.removeValue()
            followersRef.removeValue()
        } else {
            followRef.setValue(true)
            followersRef.setValue(true)
        }
    }

    func reportPost(postId: String) {
        let alert = UIAlertController(title: "Report Post", message: "Enter reason for reporting", preferredStyle: .alert)
        alert.addTextField { textField in textField.placeholder = "Reason (optional)" }
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { _ in
            let reason = alert.textFields?.first?.text ?? "Inappropriate content"
            submitReport(postId: postId, reason: reason)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    func submitReport(postId: String, reason: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let reportRef = ref.child("reports").child(postId).child(currentUserId)
        reportRef.setValue(reason) { error, _ in
            if error == nil {
                ref.child("posts").child(postId).child("is_reported").setValue(true)
            }
        }
    }
}

struct PostCardView: View {
    @Binding var post: UserPost
    var updateLikeStatus: (String, Bool) -> Void
    var toggleFollowStatus: (String, Bool) -> Void
    var openUserProfile: (String) -> Void
    var reportPost: (String) -> Void

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
                    toggleFollowStatus(post.userId, post.isLiked)
                }) {
                    Text(post.isLiked ? "Unfollow" : "Follow")
                        .font(.subheadline)
                        .padding(5)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
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
                    post.isLiked.toggle()
                    updateLikeStatus(post.id, post.isLiked)
                }) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .primary)
                }
                Text("\(post.countLike)")

                Button(action: {}) {
                    Image(systemName: "message")
                }
                Text("\(post.countComment)")
                
                Button(action: {
                    reportPost(post.id)
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
}
