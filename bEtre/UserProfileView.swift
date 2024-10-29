import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImageSwiftUI

struct UserProfileView: View {
    let userId: String // Passing user ID of specific user

    @State private var posts: [Post] = []
    @State private var profileImageUrl: String = ""
    @State private var username: String = "Loading..."
    @State private var bio: String = "Loading bio..."
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0

    var body: some View {
        ScrollView { // Make the entire view scrollable
            VStack {
                profileHeader

                profileStats

                Divider().padding(.vertical)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(posts) { post in
                        if let url = URL(string: post.imageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160, height: 160)
                                .cornerRadius(10)
                                .clipped()
                        } else {
                            Color.gray.frame(width: 160, height: 160).cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .onAppear {
                fetchUserProfile()
                fetchUserPosts()
                fetchFollowerCount()
                fetchFollowingCount()
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
            statView(number: followingCount, label: "Following")
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

    private func fetchUserProfile() {
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.username = userData["username"] as? String ?? "Unknown User"
                self.bio = userData["bio"] as? String ?? "No bio available"
                self.profileImageUrl = userData["profileImageUrl"] as? String ?? ""
            }
        }
    }

    private func fetchUserPosts() {
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

    private func fetchFollowerCount() {
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

#Preview {
    UserProfileView(userId: "example_user_id")
}
