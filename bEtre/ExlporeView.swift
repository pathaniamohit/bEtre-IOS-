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
            
            // Initialize an empty array to hold new posts
            var newPosts: [UserPost] = []
            
            // Step 2: Fetch posts for each followed user
            fetchUserPosts(followedUserIds: followedUserIds) { fetchedPosts in
                self.posts = fetchedPosts.sorted(by: { $0.timestamp > $1.timestamp })
            }
        }
    }

    private func fetchUserPosts(followedUserIds: [String], completion: @escaping ([UserPost]) -> Void) {
        var fetchedPosts: [UserPost] = []
        
        for userId in followedUserIds {
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                           let postData = snapshot.value as? [String: Any] {
                            var post = UserPost(id: snapshot.key, data: postData)
                            
                            // Fetch associated user details
                            fetchUserData(for: post.userId) { userData in
                                if let userData = userData {
                                    post.username = userData.username
                                    post.profileImageUrl = userData.profileImageUrl
                                    post.email = userData.email
                                }
                                
                                fetchedPosts.append(post)
                                
                                // Check if all posts are fetched, then call completion
                                if fetchedPosts.count == followedUserIds.count {
                                    completion(fetchedPosts)
                                }
                            }
                        }
                    }
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
