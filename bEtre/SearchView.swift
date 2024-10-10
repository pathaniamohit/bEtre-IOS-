//
//  SearchView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI
import Firebase
import FirebaseDatabase



struct User: Identifiable {
    var id: String
    var username: String
    var profileImageUrl: String
    var isViral: Bool

    init(id: String, data: [String: Any]) {
        self.id = id
        self.username = data["username"] as? String ?? "Unknown"
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.isViral = data["isViral"] as? Bool ?? false
    }
}


struct SearchView: View {
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var posts: [Post] = []
    
    var body: some View {
        NavigationView {
            VStack {
                
                TextField("Search users...", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onChange(of: searchText) { _ in
                        searchUsers()
                    }
                
                ScrollView {
                    // Viral / Latest Posts Section
                    VStack(alignment: .leading) {
//                        Text("Viral & Latest Posts")
//                            .font(.headline)
//                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(posts.filter { $0.isViral || searchText.isEmpty }) { post in
                                    VStack {
                                        if let url = URL(string: post.imageUrl) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Color.gray
                                            }
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(8)
                                            .clipped()
                                        } else {
                                            Rectangle()
                                                .foregroundColor(.gray)
                                                .frame(width: 120, height: 120)
                                                .cornerRadius(8)
                                        }
                                        Text(post.content)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    Divider().padding(.vertical)
                    
                    
                    VStack(alignment: .leading) {
                        Text("Users")
                            .font(.headline)
                            .padding(.leading)
                        
                        
                        ForEach(users.filter { searchText.isEmpty || $0.username.lowercased().contains(searchText.lowercased()) }) { user in
                            NavigationLink(destination: UserProfileView(userId: user.id)) {
                                HStack {
                                    
                                    if let url = URL(string: user.profileImageUrl) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .frame(width: 40, height: 40)
                                        }
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    
                                    Text(user.username)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                    
                                    Spacer()
                                    
                                    
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
                .onAppear {
                    fetchViralPosts()
                    fetchAllUsers()
                }
            }
        }
    }
        
        
        
        func fetchAllUsers() {
            let ref = Database.database().reference().child("users")
            ref.observe(.value) { snapshot in
                var fetchedUsers: [User] = []
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let userData = snapshot.value as? [String: Any] {
                        let user = User(id: snapshot.key, data: userData)
                        fetchedUsers.append(user)
                    }
                }
                self.users = fetchedUsers
            }
        }
        
        
        func searchUsers() {
            if searchText.isEmpty {
                fetchAllUsers()
            } else {
                self.users = self.users.filter { $0.username.lowercased().contains(searchText.lowercased()) }
            }
        }
        
       
        func fetchViralPosts() {
            let ref = Database.database().reference().child("posts")
            ref.queryOrdered(byChild: "isViral").queryEqual(toValue: true).observe(.value) { snapshot in
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

    #Preview {
        SearchView()
    }
    

