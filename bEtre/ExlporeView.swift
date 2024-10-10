//
//  ExlporeView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//


import SwiftUI
import Foundation
import FirebaseDatabase
import FirebaseAuth
import SDWebImageSwiftUI

struct UserPost: Identifiable {
    var id: String
    var content: String
    var imageUrl: String
    var location: String
    var timestamp: TimeInterval
    var userId: String
    var isLiked: Bool = false
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.content = data["content"] as? String ?? ""
        self.imageUrl = data["imageUrl"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.timestamp = data["timestamp"] as? TimeInterval ?? 0
        self.userId = data["userId"] as? String ?? ""
    }
}

//struct ExploreView: View {
//    @State private var posts: [UserPost] = []
//    private var ref: DatabaseReference = Database.database().reference()
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                LazyVStack(spacing: 16) {
//                    ForEach($posts) { $post in
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(post.userId)
//                                    .font(.headline)
//                                    .padding(.leading)
//                                
//                                Spacer()
//                            }
//                            .padding(.top)
//                            
//                            WebImage(url: URL(string: post.imageUrl))
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .frame(maxWidth: .infinity, maxHeight: 300)
//                                .clipped()
//                            
//                           
//                            HStack(spacing: 24) {
//                                Button(action: {
//                                    post.isLiked.toggle()
//                                    updateLikeStatus(postId: post.id, isLiked: post.isLiked)
//                                }) {
//                                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
//                                        .foregroundColor(post.isLiked ? .red : .primary)
//                                }
//                                
//                                Button(action: {
//                                    
//                                }) {
//                                    Image(systemName: "message")
//                                }
//                                
//                                Button(action: {
//                                }) {
//                                    Image(systemName: "square.and.arrow.up")
//                                }
//                                
//                                Spacer()
//                            }
//                            .padding(.leading)
//                            .padding(.vertical, 8)
//                            
//                            VStack(alignment: .leading) {
//                                Text(post.userId)
//                                    .font(.subheadline)
//                                    .bold() +
//                                Text(" \(post.content)")
//                                    .font(.subheadline)
//                            }
//                            .padding(.leading)
//                        }
//                        .background(Color(.systemBackground))
//                        .cornerRadius(10)
//                        .shadow(radius: 5)
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .navigationTitle("Explore")
//            .onAppear(perform: fetchPosts)
//        }
//    }
//    
//    func fetchPosts() {
//        ref.child("posts").observe(.value) { snapshot in
//            var newPosts: [UserPost] = []
//            for child in snapshot.children {
//                if let childSnapshot = child as? DataSnapshot,
//                   let postData = childSnapshot.value as? [String: Any] {
//                    let post = UserPost(id: childSnapshot.key, data: postData)
//                    newPosts.append(post)
//                }
//            }
//            self.posts = newPosts
//        }
//    }
//    
//    func updateLikeStatus(postId: String, isLiked: Bool) {
//        ref.child("posts/\(postId)/isLiked").setValue(isLiked)
//    }
//}

//struct ExploreView: View {
//    @State private var posts: [Post] = []
//    private var ref: DatabaseReference = Database.database().reference()
//
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                LazyVStack(spacing: 16) {
//                    ForEach($posts) { $post in
//                        PostView(post: $post)
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .navigationTitle("Explore")
//            .onAppear(perform: fetchPosts)
//        }
//    }
//
//    func fetchPosts() {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        let ref = Database.database().reference()
//
//        // First, fetch the list of users the current user is following
//        ref.child("following").child(currentUserId).observeSingleEvent(of: .value) { snapshot in
//            var followedUserIds: [String] = []
//            if let followingDict = snapshot.value as? [String: Bool] {
//                followedUserIds = Array(followingDict.keys)
//            }
//
//            // Now fetch posts from the followed users
//            ref.child("posts").observe(.value) { snapshot in
//                var newPosts: [Post] = []
//                for child in snapshot.children {
//                    if let childSnapshot = child as? DataSnapshot,
//                       let postData = childSnapshot.value as? [String: Any] {
//                        let post = Post(id: childSnapshot.key, data: postData)
//                        if followedUserIds.contains(post.userId) {
//                            newPosts.append(post)
//                        }
//                    }
//                }
//                self.posts = newPosts
//            }
//        }
//    }

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImageSwiftUI

struct ExploreView: View {
    @State private var posts: [Post] = []
    private var ref: DatabaseReference = Database.database().reference()

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach($posts) { $post in
                        PostView(post: $post)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Explore")
            .onAppear(perform: fetchPosts)
        }
    }

    func fetchPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()

        // Fetch post IDs from the user's feed
        ref.child("user-feeds").child(currentUserId).observeSingleEvent(of: .value) { snapshot in
            var postIds: [String] = []
            if let feedDict = snapshot.value as? [String: Any] {
                postIds = Array(feedDict.keys)
            }

            var newPosts: [Post] = []
            let group = DispatchGroup()

            for postId in postIds {
                group.enter()
                ref.child("posts").child(postId).observeSingleEvent(of: .value) { snapshot in
                    if let postData = snapshot.value as? [String: Any] {
                        let post = Post(id: snapshot.key, data: postData)
                        newPosts.append(post)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                // Sort posts by timestamp if needed
                self.posts = newPosts.sorted(by: { $0.timestamp > $1.timestamp })
            }
        }
    }


    
    func updateLikeStatus(postId: String, isLiked: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let postRef = ref.child("posts").child(postId)
        
        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject] {
                var likedBy = post["likedBy"] as? [String] ?? []
                var countLike = post["count_like"] as? Int ?? 0
                if isLiked {
                    // Add currentUserId to likedBy
                    if !likedBy.contains(currentUserId) {
                        likedBy.append(currentUserId)
                        countLike += 1
                    }
                } else {
                    // Remove currentUserId from likedBy
                    if let index = likedBy.firstIndex(of: currentUserId) {
                        likedBy.remove(at: index)
                        countLike -= 1
                    }
                }
                post["likedBy"] = likedBy as AnyObject
                post["count_like"] = countLike as AnyObject
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        })
    }

    
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}


