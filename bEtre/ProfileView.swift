import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImageSwiftUI

struct UserPost: Identifiable {
    var id: String
    var content: String
    var countComment: Int
    var countLike: Int
    var imageUrl: String
    var isReported: Bool
    var location: String
    var userId: String
    var timestamp: TimeInterval
    var isViral: Bool
    var isLiked: Bool = false
    var likedBy: [String] = []
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.content = data["content"] as? String ?? ""
        self.countComment = data["count_comment"] as? Int ?? 0
        self.countLike = data["count_like"] as? Int ?? 0
        self.imageUrl = data["imageUrl"] as? String ?? ""
        self.isReported = data["is_reported"] as? Bool ?? false
        self.location = data["location"] as? String ?? ""
        self.userId = data["userId"] as? String ?? ""
        self.timestamp = data["timestamp"] as? TimeInterval ?? 0
        self.isViral = data["isViral"] as? Bool ?? false
        self.likedBy = data["likedBy"] as? [String] ?? []
        if let currentUserId = Auth.auth().currentUser?.uid {
            self.isLiked = likedBy.contains(currentUserId)
        }
    }
}

struct UserComment: Identifiable {
    var id: String
    var userId: String
    var username: String
    var content: String
    var timestamp: TimeInterval
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.timestamp = data["timestamp"] as? TimeInterval ?? 0
    }
}

struct ProfileView: View {
    @State private var posts: [UserPost] = []
    @State private var isShowingSettings = false
    @State private var profileImageUrl: String = ""
    @State private var username: String = "Loading..."
    @State private var bio: String = "Loading bio..."
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    
    let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Text("My Profile")
                        .font(.custom("RobotoSerif-Bold", size: 30))
                        .padding(.leading, 40)
                    Spacer()
                    Button(action: {
                        isShowingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                            .padding(.trailing, 16)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        
                        profileStats
                        
                        LazyVStack(spacing: 10) { // LazyVStack for efficient vertical scrolling
                            ForEach($posts) { $post in
                                UserPostView(post: $post)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .onAppear {
                        fetchPostsForLoggedInUser()
                        fetchUserProfile()
                        fetchFollowersCount()
                        fetchFollowingCount()
                    }
                }
                .navigationBarHidden(true)
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack {
            if let url = URL(string: profileImageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 5)
            }
            Text(username)
                .font(.headline)
                .bold()
        }
        .padding(.bottom, 10)
    }
    
    private var profileStats: some View {
        HStack(spacing: 50) {
            statView(number: posts.count, label: "Photos")
            statView(number: followerCount, label: "Followers")
            statView(number: followingCount, label: "Follows")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private func statView(number: Int, label: String) -> some View {
        VStack {
            Text("\(number)")
                .font(.headline)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func fetchPostsForLoggedInUser() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }
        
        let ref = Database.database().reference().child("posts")
        ref.queryOrdered(byChild: "userId").queryEqual(toValue: userId).observe(.value) { snapshot in
            var fetchedPosts: [UserPost] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postData = snapshot.value as? [String: Any] {
                    let post = UserPost(id: snapshot.key, data: postData)
                    fetchedPosts.append(post)
                }
            }
            self.posts = fetchedPosts
        }
    }
    
    private func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }
        
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            
            if let userData = snapshot.value as? [String: Any] {
                self.username = userData["username"] as? String ?? "Unknown User"
                self.bio = userData["bio"] as? String ?? "No bio available"
                self.profileImageUrl = userData["profileImageUrl"] as? String ?? ""
                let isViral = userData["isViral"] as? Bool ?? false
                
            }
            
        }
    }
    
    private func fetchFollowersCount() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child("followers").child(userId)
        ref.observe(.value) { snapshot in
            if let followersDict = snapshot.value as? [String: Any] {
                self.followerCount = followersDict.count
            } else {
                self.followerCount = 0
            }
        }
    }
    
    
    private func fetchFollowingCount() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child("following").child(userId)
        ref.observe(.value) { snapshot in
            if let followingDict = snapshot.value as? [String: Any] {
                self.followingCount = followingDict.count
            } else {
                self.followingCount = 0
            }
        }
    }
}


struct UserPostView: View {
    @Binding var post: UserPost
    @State private var showComments = false
    @State private var showDeleteConfirmation = false
    @State private var username: String = ""
    @State private var profileImageUrl: String = ""
    @State private var showEditPostView = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                if let url = URL(string: profileImageUrl) {
                    WebImage(url: url)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                Text(username)
                    .font(.headline)
                Spacer()
            }
            .padding([.leading, .top])
            
            
            if let url = URL(string: post.imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
            } else {
                Color.gray.frame(height: 300)
            }
            
            
            Text(post.content)
                .font(.body)
                .padding([.leading, .trailing, .top])
            
            
            HStack(spacing: 20) {
                
                Button(action: {
                    toggleLike()
                }) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .primary)
                }
                
                
                Button(action: {
                    showComments = true
                }) {
                    Image(systemName: "message")
                }
                
                if post.userId == Auth.auth().currentUser?.uid {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding([.leading, .trailing])
            
            
            HStack {
                Text("\(post.countLike) Likes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(post.countComment) Comments")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding([.leading, .bottom])
            .sheet(isPresented: $showComments) {
                UserCommentsView(post: $post)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Post"),
                    message: Text("Are you sure you want to delete this post?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deletePost()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onAppear {
            fetchUserData()
        }
        .onTapGesture(count: 2) { showEditPostView = true }
        .sheet(isPresented: $showEditPostView) {
            EditPostView(post: post)
        }
    }
    
    func fetchUserData() {
        let ref = Database.database().reference().child("users").child(post.userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.username = userData["username"] as? String ?? "Unknown User"
                self.profileImageUrl = userData["profileImageUrl"] as? String ?? ""
            } else {
                self.username = "Unknown User"
            }
        }
    }
    
    func toggleLike() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        let postRef = ref.child("posts").child(post.id)
        
        if post.isLiked {
            post.likedBy.removeAll { $0 == userId }
            post.countLike -= 1
        } else {
            post.likedBy.append(userId)
            post.countLike += 1
        }
        
        post.isLiked.toggle()
        
        postRef.updateChildValues([
            "likedBy": post.likedBy,
            "count_like": post.countLike
        ])
    }
    
    func deletePost() {
        let ref = Database.database().reference()
        ref.child("posts").child(post.id).removeValue()
        
        if let currentUserId = Auth.auth().currentUser?.uid {
            ref.child("user-feeds").child(currentUserId).child(post.id).removeValue()
        }
    }
}

struct UserCommentsView: View {
    @Binding var post: UserPost
    @State private var newComment = ""
    @State private var comments: [UserComment] = []
    
    var body: some View {
        VStack {
            List {
                ForEach(comments) { comment in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(comment.username)
                                .font(.headline)
                            Spacer()
                            if comment.userId == Auth.auth().currentUser?.uid {
                                Button(action: {
                                    deleteComment(comment)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        Text(comment.content)
                            .font(.body)
                    }
                }
            }
            
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    addComment()
                }) {
                    Text("Post")
                }
            }
            .padding()
        }
        .onAppear {
            fetchComments()
        }
    }
    
    func fetchComments() {
        let ref = Database.database().reference()
        ref.child("comments").child(post.id).observe(.value) { snapshot in
            var newComments: [UserComment] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let commentData = snapshot.value as? [String: Any] {
                    var comment = UserComment(id: snapshot.key, data: commentData)
                    
                    if comment.username.isEmpty {
                        ref.child("users").child(comment.userId).observeSingleEvent(of: .value) { userSnapshot in
                            if let userData = userSnapshot.value as? [String: Any],
                               let fetchedUsername = userData["username"] as? String {
                                comment.username = fetchedUsername
                                
                                if let index = newComments.firstIndex(where: { $0.id == comment.id }) {
                                    newComments[index] = comment
                                }
                            }
                        }
                    }
                    newComments.append(comment)
                }
            }
            self.comments = newComments.sorted(by: { $0.timestamp < $1.timestamp })
        }
    }
    
    func addComment() {
        guard !newComment.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        let commentId = ref.child("comments").child(post.id).childByAutoId().key ?? UUID().uuidString
        
        ref.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any],
               let username = userData["username"] as? String {
                
                let commentData: [String: Any] = [
                    "userId": userId,
                    "username": username,
                    "content": newComment,
                    "timestamp": ServerValue.timestamp()
                ]
                
                ref.child("comments").child(post.id).child(commentId).setValue(commentData)
                newComment = ""
                post.countComment += 1
                ref.child("posts").child(post.id).updateChildValues(["count_comment": post.countComment])
            } else {
                print("User data not found or username missing.")
            }
        }
    }
    
    func deleteComment(_ comment: UserComment) {
        guard comment.userId == Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        ref.child("comments").child(post.id).child(comment.id).removeValue()
        
        post.countComment -= 1
        ref.child("posts").child(post.id).updateChildValues(["count_comment": post.countComment])
    }
}

struct UserLikesView: View {
    let likedBy: [String]
    @State private var users: [AppUser] = []
    
    var body: some View {
        List(users) { user in
            HStack {
                if let url = URL(string: user.profileImageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                }
                Text(user.username)
            }
        }
        .onAppear {
            fetchUsers()
        }
    }
    
    func fetchUsers() {
        let ref = Database.database().reference()
        var fetchedUsers: [AppUser] = []
        
        let group = DispatchGroup()
        for userId in likedBy {
            group.enter()
            ref.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
                if let userData = snapshot.value as? [String: Any] {
                    let user = AppUser(id: userId, data: userData)
                    fetchedUsers.append(user)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.users = fetchedUsers
        }
    }
}

#Preview {
    ProfileView()
}
