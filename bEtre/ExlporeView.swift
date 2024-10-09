//
//  ExlporeView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//


import SwiftUI
import Foundation
import FirebaseDatabase
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
    @State private var posts: [UserPost] = []
    private var ref: DatabaseReference = Database.database().reference()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach($posts) { $post in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(post.userId)
                                    .font(.headline)
                                    .padding(.leading)
                                
                                Spacer()
                            }
                            .padding(.top)
                            
                            WebImage(url: URL(string: post.imageUrl))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 300)
                                .clipped()
                            
                           
                            HStack(spacing: 24) {
                                Button(action: {
                                    post.isLiked.toggle()
                                    updateLikeStatus(postId: post.id, isLiked: post.isLiked)
                                }) {
                                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(post.isLiked ? .red : .primary)
                                }
                                
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "message")
                                }
                                
                                Button(action: {
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.vertical, 8)
                            
                            VStack(alignment: .leading) {
                                Text(post.userId)
                                    .font(.subheadline)
                                    .bold() +
                                Text(" \(post.content)")
                                    .font(.subheadline)
                            }
                            .padding(.leading)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Explore")
            .onAppear(perform: fetchPosts)
        }
    }
    
    func fetchPosts() {
        ref.child("posts").observe(.value) { snapshot in
            var newPosts: [UserPost] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let postData = childSnapshot.value as? [String: Any] {
                    let post = UserPost(id: childSnapshot.key, data: postData)
                    newPosts.append(post)
                }
            }
            self.posts = newPosts
        }
    }
    
    func updateLikeStatus(postId: String, isLiked: Bool) {
        ref.child("posts/\(postId)/isLiked").setValue(isLiked)
    }
}
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}


