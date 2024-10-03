//
//  ExlporeView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI

struct UserPost: Identifiable {
    var id = UUID()
    var username: String
    var imageName: String // Assume posts have an image
    var caption: String
    var isLiked: Bool
}

struct ExploreView: View {
    // Sample data
    @State private var posts = [
        UserPost(username: "friend1", imageName: "photo1", caption: "Beautiful sunset!", isLiked: false),
        UserPost(username: "friend2", imageName: "photo2", caption: "At the beach 🏖️", isLiked: true),
        UserPost(username: "user123", imageName: "photo3", caption: "Mountain vibes", isLiked: false),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach($posts) { $post in
                        VStack(alignment: .leading) {
                            // Post header with username
                            HStack {
                                Text(post.username)
                                    .font(.headline)
                                    .padding(.leading)
                                
                                Spacer()
                            }
                            .padding(.top)
                            
                            // Post image
                            Image(post.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 300)
                                .clipped()
                            
                            // Like, Comment, Share buttons
                            HStack(spacing: 24) {
                                // Like button
                                Button(action: {
                                    post.isLiked.toggle()
                                }) {
                                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(post.isLiked ? .red : .primary)
                                }
                                
                                // Comment button
                                Button(action: {
                                    // Navigate to comment section
                                }) {
                                    Image(systemName: "message")
                                }
                                
                                // Share button
                                Button(action: {
                                    // Share action
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.vertical, 8)
                            
                            // Post caption
                            VStack(alignment: .leading) {
                                Text(post.username)
                                    .font(.subheadline)
                                    .bold() +
                                Text(" \(post.caption)")
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
        }
    }
}

#Preview {
    ExploreView()
}

