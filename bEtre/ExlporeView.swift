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
                    
                    if !likedBy.contains(currentUserId) {
                        likedBy.append(currentUserId)
                        countLike += 1
                    }
                } else {
                    
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


