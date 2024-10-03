//
//  SearchView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI

struct User: Identifiable {
    var id = UUID()
    var username: String
    var isViral: Bool
}

struct Post: Identifiable {
    var id = UUID()
    var image: String // Replace with actual image
    var isViral: Bool
}

struct SearchView: View {
    @State private var searchText = ""
    
    // Sample data for users and posts
    let users = [
        User(username: "User123", isViral: false),
        User(username: "User456", isViral: true),
        User(username: "CoolUser", isViral: false),
        User(username: "ViralStar", isViral: true)
    ]
    
    let posts = [
        Post(image: "post1", isViral: true), // Replace with actual image asset
        Post(image: "post2", isViral: false),
        Post(image: "post3", isViral: true),
        Post(image: "post4", isViral: false)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search users...", text: $searchText)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                ScrollView {
                    // Viral / Latest Posts Section
                    VStack(alignment: .leading) {
                        Text("Viral & Latest Posts")
                            .font(.headline)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(posts.filter { $0.isViral || searchText.isEmpty }, id: \.id) { post in
                                    Rectangle()
                                        .foregroundColor(.gray)
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(8)
                                        .overlay(Text(post.image)) // Replace with post image
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    Divider().padding(.vertical)
                    
                    // User Profiles Section
                    VStack(alignment: .leading) {
                        Text("Users")
                            .font(.headline)
                            .padding(.leading)
                        
                        ForEach(users.filter { searchText.isEmpty || $0.username.contains(searchText) }, id: \.id) { user in
                            HStack {
                                // Username
                                Text(user.username)
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                
                                Spacer()
                                
                                // Show if user is viral
                                if user.isViral {
                                    Text("Viral")
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}

#Preview {
    SearchView()
}
