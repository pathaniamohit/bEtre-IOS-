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
    @StateObject var userViewModel = UserViewModel()
    @State private var isLoggedOut = false
    @State private var posts: [Post] = []
    @State private var isLoading = true
    
    let profileImage = Image(systemName: "person.circle.fill")
    
    let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView("Loading posts...")
                } else {
                    VStack {
                        HStack {
                            profileImage
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            
                            Spacer()
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(posts.count)")
                                        .font(.headline)
                                    Text("Posts")
                                        .font(.subheadline)
                                }
                                VStack {
                                    Text("\(userViewModel.followers)")
                                        .font(.headline)
                                    Text("Followers")
                                        .font(.subheadline)
                                }
                                VStack {
                                    Text("\(userViewModel.following)")
                                        .font(.headline)
                                    Text("Following")
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        
                        VStack(alignment: .leading) {
                            Text(userViewModel.username.isEmpty ? "username123" : userViewModel.username) .font(.title2)
                                .bold()
                            Text(userViewModel.bio.isEmpty ? "This is a bio description." : userViewModel.bio)
                                .font(.subheadline)
                                .padding(.top, 1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading, .trailing])
                        
                        LazyVGrid(columns: gridColumns, spacing: 2) {
                            ForEach(posts) { post in
                                PostView(post: post)
                            }
                        }
                    }
                    .navigationTitle("Profile")
                    .navigationBarItems(trailing: settingsButton)
                }
            }
            .onAppear {
                fetchPostsForLoggedInUser()
            }
            .fullScreenCover(isPresented: $isLoggedOut) {
                LoginView()
            }
        }
    }
    
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
                    let post = Post(id: snapshot.key, data: postData) // Create Post model
                    fetchedPosts.append(post)
                }
            }
            self.posts = fetchedPosts
            self.isLoading = false
        }
    }
    
    private var settingsButton: some View {
        Menu {
            Button(action: {
                let editProfileView = EditProfileView(userViewModel: userViewModel)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(UIHostingController(rootView: editProfileView), animated: true)
                }
            }) {
                Text("Edit Profile")
            }
            
            Button(action: {
            }) {
                Text("Account and Privacy")
            }
            
            Button(action: {
            }) {
                Text("About")
            }
            
            Button(action: {
                do {
                    try Auth.auth().signOut()
                    isLoggedOut = true
                } catch {
                    print("Logout failed: \(error.localizedDescription)")
                }
            }) {
                Text("Logout")
                    .foregroundColor(.red)             }
        } label: {
            Image(systemName: "gear")
                .font(.title)
                .foregroundColor(.primary)
        }
    }
}

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
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .clipped()
            }
            Text(post.content)
                .font(.caption)
            Text(post.location)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 100, height: 130)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    ProfileView()
}
