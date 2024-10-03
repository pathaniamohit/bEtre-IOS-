//
//  ProfileView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI

struct ProfileView: View {
    // Sample data
    let username = "username123"
    let profileImage = Image(systemName: "person.circle.fill") // Replace with your actual profile image
    let posts = Array(repeating: "post", count: 12) // Sample posts array
    let followers = 1000
    let following = 500
    
    let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                // Profile Info
                HStack {
                    // Profile image
                    profileImage
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(posts.count)")
                                .font(.headline)
                            Text("Posts")
                                .font(.subheadline)
                        }
                        VStack {
                            Text("\(followers)")
                                .font(.headline)
                            Text("Followers")
                                .font(.subheadline)
                        }
                        VStack {
                            Text("\(following)")
                                .font(.headline)
                            Text("Following")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                // Username and Bio
                VStack(alignment: .leading) {
                    Text(username)
                        .font(.title2)
                        .bold()
                    Text("This is a bio description.")
                        .font(.subheadline)
                        .padding(.top, 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .trailing])
                
                // Edit Profile Button
                Button(action: {
                    // Action for editing profile
                }) {
                    Text("Edit Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding([.leading, .trailing])
                
                // Grid of Posts
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(posts.indices, id: \.self) { index in
                        Rectangle()
                            .foregroundColor(.gray)
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(Text("Post \(index + 1)"))
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
