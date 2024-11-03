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
}

struct ActivityView: View {
    @State private var posts: [AdminPost] = []
    @State private var filteredPosts: [AdminPost] = []  // Filtered posts based on search
    @State private var uniqueLocations: [String] = [] // List of unique post locations for suggestions
    @State private var filteredLocations: [String] = [] // Filtered location suggestions
    @State private var selectedPostID: String? = nil // Track selected post ID
    @State private var isCommentSheetPresented: Bool = false // Track if comment sheet is presented
    @State private var currentUserId = Auth.auth().currentUser?.uid ?? ""
    @State private var searchText: String = "" // Search text for location
    @State private var showDeletePostDialog: Bool = false
    @State private var postToDelete: AdminPost? = nil
    @State private var commentToDelete: AdminComment? = nil
    
    var body: some View {
        VStack {
            // Search bar with suggestions for filtering posts by location
            VStack {
                HStack {
                    TextField("Search by location", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: searchText) { _ in
                            applyLocationFilter() // Filter posts each time the search text changes
                            updateLocationSuggestions() // Update location suggestions
                        }
                    
                    Button("Search") {
                        applyLocationFilter() // Trigger search when button is pressed
                    }
                    .padding(.leading, 10)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Display location suggestions when searchText is non-empty
                if !filteredLocations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredLocations, id: \.self) { location in
                                Button(action: {
                                    searchText = location // Set searchText to selected location
                                    applyLocationFilter() // Filter posts immediately
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
                            
                            // Delete Post Button
                            Button(action: {
                                postToDelete = post
                                showDeletePostDialog = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.trailing, 10)
                        }
                        
                        if let url = URL(string: post.imageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: .infinity, height: 200)
                                .clipped()
                        }
                        
                        HStack {
                            Image(systemName: "heart")
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20) // Set a definite frame size
                            Text("\(post.countLike)")
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                selectedPostID = post.id
                                isCommentSheetPresented = true // Show comment sheet
                            }) {
                                Image(systemName: "message")
                                    .frame(width: 20, height: 20) // Set a definite frame size
                            }
                            Text("\(post.countComment)")
                                .foregroundColor(.gray)
                        }
                        
                        Text(post.content)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        Text(post.location)
                            .font(.caption)
                            .foregroundColor(.gray)
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
            .sheet(isPresented: $isCommentSheetPresented) {
                if let postId = selectedPostID {
                    AdminCommentView(postId: postId, onDeleteComment: deleteComment)
                }
            }
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
    
    private func deleteComment(_ comment: AdminComment, postId: String) {
        let ref = Database.database().reference().child("comments").child(postId).child(comment.id)
        ref.removeValue { error, _ in
            if let error = error {
                print("Failed to delete comment: \(error.localizedDescription)")
            } else {
                // Reload comments or update comments list to reflect deletion
            }
        }
    }
    
    // Load all posts and prepare initial filtered list
    private func loadPosts() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var loadedPosts: [AdminPost] = []
            var uniqueLocationSet: Set<String> = [] // Set to collect unique locations
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postDict = snapshot.value as? [String: Any],
                   let userId = postDict["userId"] as? String {
                    
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
                    
                    uniqueLocationSet.insert(post.location) // Add location to set
                    fetchUserData(for: userId) { username, email, profileImageUrl, warningCount in
                        post.username = username
                        post.email = email
                        post.profileImageUrl = profileImageUrl
                        post.warningCount = warningCount
                        loadedPosts.append(post)
                        
                        self.posts = loadedPosts
                        self.filteredPosts = loadedPosts
                        self.uniqueLocations = Array(uniqueLocationSet).sorted() // Prepare sorted list of unique locations
                    }
                }
            }
        }
    }
    
    // Apply location filter based on searchText
    private func applyLocationFilter() {
        if searchText.isEmpty {
            // If search is empty, show all posts
            filteredPosts = posts
        } else {
            // Filter posts by location containing the search text
            filteredPosts = posts.filter { $0.location.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // Update location suggestions based on searchText
    private func updateLocationSuggestions() {
        if searchText.isEmpty {
            filteredLocations = [] // Clear suggestions if search is empty
        } else {
            filteredLocations = uniqueLocations.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // Fetch user data including warning count
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
    
    // Determine border color based on warning count
    func getBorderColor(for warningCount: Int) -> Color {
        switch warningCount {
        case 2:
            return .red
        case 1:
            return .orange
        default:
            return .yellow
        }
    }
}

// Comment View for displaying comments
struct AdminCommentView: View {
    let postId: String
    @State private var comments: [AdminComment] = []
    var onDeleteComment: ((AdminComment, String) -> Void)?
    @State private var showDeleteCommentDialog: Bool = false
    @State private var commentToDelete: AdminComment? = nil
    
    var body: some View {
        VStack {
            Text("Comments")
                .font(.headline)
                .padding()
            
            ScrollView {
                ForEach(comments) { comment in
                    HStack(alignment: .top, spacing: 10) {
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
                        
                        Spacer()
                        
                        // Delete Comment Button
                        Button(action: {
                            commentToDelete = comment
                            showDeleteCommentDialog = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal)
                    // Apply red border for reported comments
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(comment.userId == postId ? Color.red : Color.clear, lineWidth: 5)
                    )
                }
            }
        }
        .onAppear(perform: loadComments)
        .alert(isPresented: $showDeleteCommentDialog) {
            Alert(
                title: Text("Delete Comment"),
                message: Text("Are you sure you want to delete this comment?"),
                primaryButton: .destructive(Text("Delete"), action: confirmDeleteComment),
                secondaryButton: .cancel()
            )
        }
    }
    
    // Load Comments for the Post
    func loadComments() {
        let commentsRef = Database.database().reference().child("comments").child(postId)
        commentsRef.observe(.value) { snapshot in
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
            
            self.comments = loadedComments.sorted { $0.timestamp < $1.timestamp }
        }
    }
    private func confirmDeleteComment() {
        if let comment = commentToDelete {
            onDeleteComment?(comment, postId)
            commentToDelete = nil
        }
    }
}

// Comment model for displaying comments
struct AdminComment: Identifiable {
    var id: String
    var content: String
    var timestamp: TimeInterval
    var userId: String
    var username: String
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
