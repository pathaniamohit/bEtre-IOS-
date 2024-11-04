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
    var isReported: Bool
    var countLike: Int
    var countComment: Int
    var username: String = ""
    var email: String = ""
    var profileImageUrl: String = ""
    var warningCount: Int = 0
    var comments: [AdminComment] = []  // Embedded comments within the post model
}

struct ActivityView: View {
    @State private var posts: [AdminPost] = []
    @State private var filteredPosts: [AdminPost] = []
    @State private var uniqueLocations: [String] = []
    @State private var filteredLocations: [String] = []
    @State private var selectedPostID: String? = nil
    @State private var searchText: String = ""
    @State private var showDeletePostDialog: Bool = false
    @State private var postToDelete: AdminPost? = nil

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
            
            ScrollView {
                ForEach(filteredPosts) { post in
                    VStack(alignment: .leading) {
                        PostView(post: post)
                        
                        ForEach(post.comments) { comment in
                            AdminCommentView(comment: comment)
                                .padding(.leading, 16)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(post.isReported ? Color.red : Color.clear, lineWidth: 5)
                            )
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .onAppear(perform: loadPosts)
            .alert(isPresented: $showDeletePostDialog) {
                Alert(
                    title: Text("Delete Post"),
                    message: Text("Are you sure you want to delete this post?"),
                    primaryButton: .destructive(Text("Delete"), action: deletePost),
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func deletePost() {
        guard let post = postToDelete else { return }
        let ref = Database.database().reference().child("posts").child(post.id)
        ref.removeValue { error, _ in
            if let error = error {
                print("Failed to delete post: \(error.localizedDescription)")
            } else {
                self.posts.removeAll { $0.id == post.id }
            }
            postToDelete = nil
        }
    }

    private func loadPosts() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var loadedPosts: [AdminPost] = []
            var uniqueLocationSet: Set<String> = []

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postDict = snapshot.value as? [String: Any],
                   let userId = postDict["userId"] as? String {
                    
                    checkUserExists(userId: userId) { exists in
                        if exists {
                            var post = AdminPost(
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

                            uniqueLocationSet.insert(post.location)
                            
                            fetchUserData(for: userId) { username, email, profileImageUrl, warningCount in
                                post.username = username
                                post.email = email
                                post.profileImageUrl = profileImageUrl
                                post.warningCount = warningCount

                                fetchComments(for: post.id) { comments in
                                    post.comments = comments
                                    
                                    // Determine latest timestamp
                                    let latestTimestamp = comments.map { $0.timestamp }.max() ?? post.timestamp
                                    post.timestamp = latestTimestamp  // Update post's timestamp to latest comment

                                    loadedPosts.append(post)
                                    
                                    // After fetching all posts, sort them by updated timestamps
                                    if loadedPosts.count == snapshot.childrenCount {
                                        self.posts = loadedPosts.sorted { $0.timestamp > $1.timestamp }
                                        self.filteredPosts = self.posts
                                        self.uniqueLocations = Array(uniqueLocationSet).sorted()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Function to check if a user exists in the database
    private func checkUserExists(userId: String, completion: @escaping (Bool) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.exists())
        }
    }

    
    private func fetchComments(for postId: String, completion: @escaping ([AdminComment]) -> Void) {
        let commentsRef = Database.database().reference().child("comments").child(postId)
        commentsRef.observeSingleEvent(of: .value) { snapshot in
            var loadedComments: [AdminComment] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let commentData = snapshot.value as? [String: Any] {
                    let comment = AdminComment(
                        id: snapshot.key,
                        content: commentData["content"] as? String ?? "",
                        timestamp: commentData["timestamp"] as? TimeInterval ?? 0,
                        userId: commentData["userId"] as? String ?? "",
                        username: commentData["username"] as? String ?? "Anonymous"
                    )
                    loadedComments.append(comment)
                }
            }
            completion(loadedComments.sorted { $0.timestamp < $1.timestamp })
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
    
    func fetchUserData(for userId: String, completion: @escaping (String, String, String, Int) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                let username = userData["username"] as? String ?? "Unknown User"
                let email = userData["email"] as? String ?? "No Email"
                let warningCount = userData["count_warning"] as? Int ?? 0
                
                let profileImageRef = Storage.storage().reference().child("users/\(userId)/profile.jpg")
                profileImageRef.downloadURL { url, _ in
                    completion(username, email, url?.absoluteString ?? "", warningCount)
                }
            } else {
                completion("Unknown User", "No Email", "", 0)
            }
        }
    }
}

// Post View for displaying individual posts
struct PostView: View {
    var post: AdminPost

    var body: some View {
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
            }

            if let url = URL(string: post.imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            }

            HStack {
                Image(systemName: "heart")
                    .foregroundColor(.gray)
                Text("\(post.countLike)")
                    .foregroundColor(.gray)
                
                Image(systemName: "message")
                Text("\(post.countComment)")
                    .foregroundColor(.gray)
            }

            Text(post.content)
                .font(.subheadline)
            Text(post.location)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// Comment View for displaying individual comments
struct AdminCommentView: View {
    var comment: AdminComment

    var body: some View {
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
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Comment model
struct AdminComment: Identifiable {
    var id: String
    var content: String
    var timestamp: TimeInterval
    var userId: String
    var username: String
}
