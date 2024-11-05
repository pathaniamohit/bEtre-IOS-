import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImageSwiftUI
import FirebaseStorage

struct AdminPost: Identifiable {
    var id: String
    var content: String
    var timestamp: TimeInterval
    var userId: String
    var location: String
    var imageUrl: String
    var countLike: Int
    var countComment: Int
    var username: String
    var email: String
    var profileImageUrl: String
    var comments: [AdminComment] = []
}

struct AdminComment: Identifiable {
    var id: String
    var content: String
    var timestamp: TimeInterval
    var userId: String
    var username: String
    var postId: String
}

struct ActivityView: View {
    @State private var posts: [AdminPost] = []
    @State private var filteredPosts: [AdminPost] = []
    @State private var uniqueLocations: [String] = []
    @State private var filteredLocations: [String] = []
    @State private var selectedPostID: String? = nil
    @State private var searchText: String = ""
    @State private var showDeleteDialog: Bool = false
    @State private var postToDelete: AdminPost?
    @State private var showCommentsSheet = false
    @State private var selectedPostId: String?
    @State private var commentToDelete: AdminComment?
    @State private var showDeleteCommentDialog: Bool = false
    
    var body: some View {
        VStack {
            // Search bar with location suggestions
            VStack {
                HStack {
                    TextField("Search by location", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: searchText) { _ in
                            applyLocationFilter()
                            updateLocationSuggestions()
                        }
                    
                    Button("Search") {
                        applyLocationFilter()
                    }
                    .padding(.leading, 10)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if !filteredLocations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredLocations, id: \.self) { location in
                                Button(action: {
                                    searchText = location
                                    applyLocationFilter()
                                }) {
                                    Text(location)
                                        .padding(8)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(5)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                }
            }
            
            // Displaying posts with double-tap delete option
            ScrollView {
                ForEach(filteredPosts) { post in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
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
                            
                            VStack(alignment: .leading) {
                                Text(post.username)
                                    .font(.headline)
                                Text(post.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            // Delete icon
                            Button(action: {
                                self.postToDelete = post
                                self.showDeleteDialog = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(post.content)
                            .font(.subheadline)
                        
                        if let url = URL(string: post.imageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        }
                        
                        Text("Location: \(post.location)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "heart")
                            Text("\(post.countLike)")
                            Image(systemName: "message")
                        }
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                        // Display Comments
                        // Display Comments with Delete Icon
                        ForEach(post.comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.username)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text(Date(timeIntervalSince1970: comment.timestamp), style: .time)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Button(action: {
                                        self.commentToDelete = comment
                                        self.showDeleteCommentDialog = true
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                Text(comment.content)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(radius: 5)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onTapGesture(count: 2) {
                        self.postToDelete = post
                        self.showDeleteDialog = true
                    }
                }
            }
            .onAppear(perform: loadPosts)
            .alert(isPresented: $showDeleteDialog) {
                Alert(
                    title: Text("Delete Post"),
                    message: Text("Are you sure you want to delete this post and its image?"),
                    primaryButton: .destructive(Text("Delete"), action: deletePost),
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $showDeleteCommentDialog) {
                Alert(
                    title: Text("Delete Comment"),
                    message: Text("Are you sure you want to delete this comment?"),
                    primaryButton: .destructive(Text("Delete"), action: deleteComment),
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func loadPosts() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var loadedPosts: [AdminPost] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postDict = snapshot.value as? [String: Any],
                   let userId = postDict["userId"] as? String {
                    
                    fetchUserData(for: userId) { username, email, profileImageUrl in
                        var post = AdminPost(
                            id: snapshot.key,
                            content: postDict["content"] as? String ?? "",
                            timestamp: postDict["timestamp"] as? TimeInterval ?? 0,
                            userId: userId,
                            location: postDict["location"] as? String ?? "",
                            imageUrl: postDict["imageUrl"] as? String ?? "",
                            countLike: postDict["count_like"] as? Int ?? 0,
                            countComment: postDict["count_comment"] as? Int ?? 0,
                            username: username,
                            email: email,
                            profileImageUrl: profileImageUrl
                        )
                        
                        // Load comments for each post
                        fetchComments(for: post.id) { comments in
                            post.comments = comments
                            loadedPosts.append(post)
                            self.posts = loadedPosts.sorted { $0.timestamp > $1.timestamp }
                            self.filteredPosts = self.posts
                        }
                    }
                }
            }
        }
    }
    
    private func fetchComments(for postId: String, completion: @escaping ([AdminComment]) -> Void) {
        let commentsRef = Database.database().reference().child("comments")
        commentsRef.observeSingleEvent(of: .value) { snapshot in
            var loadedComments: [AdminComment] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let commentData = snapshot.value as? [String: Any],
                   let commentPostId = commentData["post_Id"] as? String,
                   commentPostId == postId {
                    
                    let comment = AdminComment(
                        id: snapshot.key,
                        content: commentData["content"] as? String ?? "",
                        timestamp: commentData["timestamp"] as? TimeInterval ?? 0,
                        userId: commentData["userId"] as? String ?? "",
                        username: commentData["username"] as? String ?? "Anonymous",
                        postId: postId
                    )
                    loadedComments.append(comment)
                }
            }
            completion(loadedComments.sorted { $0.timestamp < $1.timestamp })
        }
    }
    
    private func deleteComment() {
        guard let comment = commentToDelete else { return }
        let ref = Database.database().reference().child("comments").child(comment.id)
        
        ref.removeValue { error, _ in
            if let error = error {
                print("Failed to delete comment: \(error.localizedDescription)")
            } else {
                if let postIndex = self.posts.firstIndex(where: { $0.id == comment.postId }) {
                    self.posts[postIndex].comments.removeAll { $0.id == comment.id }
                    self.filteredPosts = self.posts
                }
            }
            commentToDelete = nil
        }
    }
    
    private func deletePost() {
        guard let post = postToDelete else { return }
        let postRef = Database.database().reference().child("posts").child(post.id)
        let storageRef = Storage.storage().reference(forURL: post.imageUrl)
        
        postRef.removeValue { error, _ in
            if let error = error {
                print("Failed to delete post: \(error.localizedDescription)")
            } else {
                storageRef.delete { error in
                    if let error = error {
                        print("Failed to delete image: \(error.localizedDescription)")
                    }
                }
                self.posts.removeAll { $0.id == post.id }
                self.filteredPosts = self.posts
            }
            postToDelete = nil
        }
    }
    
    
    private func applyLocationFilter() {
        if searchText.isEmpty {
            filteredPosts = posts
        } else {
            filteredPosts = posts.filter { $0.location.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func updateLocationSuggestions() {
        if searchText.isEmpty {
            filteredLocations = []
        } else {
            filteredLocations = uniqueLocations.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func fetchUserData(for userId: String, completion: @escaping (String, String, String) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                let username = userData["username"] as? String ?? "Unknown User"
                let email = userData["email"] as? String ?? "No Email"
                
                let profileImageRef = Storage.storage().reference().child("users/\(userId)/profile.jpg")
                profileImageRef.downloadURL { url, _ in
                    completion(username, email, url?.absoluteString ?? "")
                }
            } else {
                completion("Unknown User", "No Email", "")
            }
        }
    }
}
