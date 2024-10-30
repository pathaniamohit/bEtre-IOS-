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
    var isLiked: Bool = false
    var warningCount: Int = 0
}

struct ActivityView: View {
    @State private var posts: [AdminPost] = []
    @State private var currentUserId = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        ScrollView {
            Text("Activity")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            ForEach(posts) { post in
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
                    }
                    
                    if let url = URL(string: post.imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.gray)
                        Text("\(post.countLike)")
                        
                        Image(systemName: "message")
                        Text("\(post.countComment)")
                    }
                    .foregroundColor(.gray)
                    
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
                                .stroke(getBorderColor(for: post.warningCount), lineWidth: 5)
                        )
                )
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .onAppear(perform: loadPosts)
    }
    
    // Load all posts and include warning count data
    func loadPosts() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var loadedPosts: [AdminPost] = []
            
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
                    
                    fetchUserData(for: userId) { username, email, profileImageUrl, warningCount in
                        post.username = username
                        post.email = email
                        post.profileImageUrl = profileImageUrl
                        post.warningCount = warningCount
                        loadedPosts.append(post)
                        self.posts = loadedPosts
                    }
                }
            }
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


struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
