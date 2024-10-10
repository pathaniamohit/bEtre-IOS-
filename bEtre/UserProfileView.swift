//
//  UserProfileView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-10-10.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth
import SDWebImageSwiftUI

struct UserProfileView: View {
    let userId: String
    @State private var user: User? = nil
    @State private var posts: [Post] = []
    @State private var isFollowing: Bool = false

    var body: some View {
        VStack {
            if let user = user {
                VStack {
                    if let url = URL(string: user.profileImageUrl) {
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
                    Text(user.username)
                        .font(.headline)
                        .bold()
                    
                    // Follow/Unfollow Button
//                    Button(action: {
//                        toggleFollow()
//                    }) {
//                        Text(isFollowing ? "Unfollow" : "Follow")
//                            .font(.headline)
//                            .padding()
//                            .background(isFollowing ? Color.gray : Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .padding(.top, 10)
                    Button(action: {
                                    if isFollowing {
                                        unfollowUser(unfollowedUserId: userId)
                                    } else {
                                        followUser(followedUserId: userId)
                                    }
                                    isFollowing.toggle()
                                }) {
                                    Text(isFollowing ? "Unfollow" : "Follow")
                                        .font(.headline)
                                        .padding()
                                        .background(isFollowing ? Color.gray : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 10)
                }
                .padding(.bottom, 10)
                
                // Display user's posts
                ScrollView {
                    LazyVStack {
                        ForEach($posts) { $post in
                            PostView(post: $post)
                        }
                    }
                }
                .onAppear {
                    fetchUserPosts()
                }
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            fetchUserData()
            checkIfFollowing()
        }
    }
    
    
    func fetchUserData() {
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.user = User(id: snapshot.key, data: userData)
            }
        }
    }
    
    func fetchUserPosts() {
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
    
    func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("following").child(currentUserId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let following = snapshot.value as? [String: Bool] {
                self.isFollowing = following[userId] ?? false
            } else {
                self.isFollowing = false
            }
        }
    }
    
    func toggleFollow() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        let followingRef = ref.child("following").child(currentUserId)
        let followersRef = ref.child("followers").child(userId)
        
        if isFollowing {
            // Unfollow
            followingRef.child(userId).removeValue()
            followersRef.child(currentUserId).removeValue()
            isFollowing = false
        } else {
            // Follow
            followingRef.child(userId).setValue(true)
            followersRef.child(currentUserId).setValue(true)
            isFollowing = true
        }
    }
    
    func followUser(followedUserId: String) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let ref = Database.database().reference()

            // Add to following and followers nodes
            ref.child("following").child(currentUserId).child(followedUserId).setValue(true)
            ref.child("followers").child(followedUserId).child(currentUserId).setValue(true)

            // Fetch posts of the followed user and add to user's feed
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: followedUserId).observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        // Add each post ID to the user's feed
                        ref.child("user-feeds").child(currentUserId).child(childSnapshot.key).setValue(true)
                    }
                }
            }
        }

        // MARK: - Unfollow User
        func unfollowUser(unfollowedUserId: String) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let ref = Database.database().reference()

            // Remove from following and followers nodes
            ref.child("following").child(currentUserId).child(unfollowedUserId).removeValue()
            ref.child("followers").child(unfollowedUserId).child(currentUserId).removeValue()

            // Remove posts of the unfollowed user from the user's feed
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: unfollowedUserId).observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        // Remove each post ID from the user's feed
                        ref.child("user-feeds").child(currentUserId).child(childSnapshot.key).removeValue()
                    }
                }
            }
        }
}


#Preview {
    UserProfileView(userId: "exampleUserId")
}

