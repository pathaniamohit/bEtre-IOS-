import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Foundation

struct Post: Identifiable {
    var id: String
    var content: String
    var countComment: Int
    var countLike: Int
    var imageUrl: String
    var isReported: Bool
    var location: String
    var userId: String
    var timestamp: TimeInterval

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
    }
}

struct ProfileView: View {
    @StateObject var userViewModel = UserViewModel() // Assumed UserViewModel handles followers/following
    @State private var posts: [Post] = []
    @State private var isShowingSettings = false // State to control SettingsView presentation
    
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
                        .font(.custom("RobotoSerif-Regular", size: 24))
                        .bold()
                        .padding(.leading, 50)
                    Spacer()
                    Button(action: {
                        isShowingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 30))
                            .foregroundColor(.primary)
                            .padding(.trailing, 16)
                    }

                }
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader // Profile Image, Name, Email
                        profileStats // Photos, Followers, Following counts
                        
                        LazyVGrid(columns: gridColumns, spacing: 10) { // 2-column grid for posts
                            ForEach(posts) { post in
                                PostView(post: post)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .onAppear {
                        fetchPostsForLoggedInUser()
                    }
                }
                .navigationBarHidden(true) // Hide the default navigation bar
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView(userViewModel: userViewModel)
            }
        }
    }
    
    // Profile header for profile image, name, and email
    private var profileHeader: some View {
        VStack {
            // Profile image
            if !userViewModel.profileImageUrl.isEmpty, let url = URL(string: userViewModel.profileImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            }
            
            // User name and email
            Text(userViewModel.username.isEmpty ? "Kathrine Mils" : userViewModel.username)
                .font(.custom("RobotoSerif-Regular", size: 18))
                .bold()
            
            Text(userViewModel.email.isEmpty ? "kathrine@gmail.com" : userViewModel.email)
                .font(.custom("RobotoSerif-Regular", size: 14))
                .foregroundColor(.gray)
        }
        .padding(.bottom, 10)
    }
    
    // Profile statistics (Photos, Followers, Follows)
    private var profileStats: some View {
        HStack(spacing: 50) { // Adjusted spacing between stats
            statView(number: posts.count, label: "Photos")
            statView(number: userViewModel.followers, label: "Followers")
            statView(number: userViewModel.following, label: "Follows")
        }
        .padding(.horizontal)
        .padding(.vertical, 10) // Add some padding around the stats section
    }
    
    private func statView(number: Int, label: String) -> some View {
        VStack {
            Text("\(number)")
                .font(.custom("RobotoSerif-Regular", size: 16))
            Text(label)
                .font(.custom("RobotoSerif-Regular", size: 12))
                .foregroundColor(.gray)
        }
    }
    
    // Fetch posts of the logged-in user from Firebase
    private func fetchPostsForLoggedInUser() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }
        
        let ref = Database.database().reference().child("posts")
        ref.queryOrdered(byChild: "userId").queryEqual(toValue: userId).observe(.value) { snapshot in
            var fetchedPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postData = snapshot.value as? [String: Any] {
                    let post = Post(id: snapshot.key, data: postData)
                    fetchedPosts.append(post)
                }
            }
            self.posts = fetchedPosts
        }
    }
}

// PostView for individual post grid cell
struct PostView: View {
    let post: Post
    
    var body: some View {
        VStack {
            if let url = URL(string: post.imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 150, height: 150) // Adjusted size for grid view
                .clipped()
            }
            Text(post.content)
                .font(.custom("RobotoSerif-Regular", size: 12))
                .lineLimit(1)
            Text(post.location)
                .font(.custom("RobotoSerif-Regular", size: 12))
                .foregroundColor(.gray)
        }
        .frame(width: 150, height: 180)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    ProfileView()
}
