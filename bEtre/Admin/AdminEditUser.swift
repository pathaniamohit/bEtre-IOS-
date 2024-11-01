//
//  AdminEditUser.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-31.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImageSwiftUI

struct AdminEditUser: View {
    let userId: String
    @State private var posts: [UserPost] = []
    @State private var profileImageUrl: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    
    @State private var isEditingUsername = false
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false

    private let storageRef = Storage.storage().reference()
    private let databaseRef = Database.database().reference()

    var body: some View {
        ScrollView {
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
            .sheet(isPresented: $showImagePicker, onDismiss: uploadProfileImage) {
                ProfileImagePicker(image: $selectedImage) // Use ProfileImagePicker here
            }
        }
    }

    private var profileHeader: some View {
        VStack {
            if let url = URL(string: profileImageUrl), selectedImage == nil {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 5)
                    .onTapGesture {
                        showImagePicker = true // Open image picker on tap
                    }
            } else if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 5)
                    .onTapGesture {
                        showImagePicker = true
                    }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 5)
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
            
            if isEditingUsername {
                TextField("Enter Username", text: $username, onCommit: {
                    updateUsername()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 10)
            } else {
                Text(username)
                    .font(.headline)
                    .bold()
                    .onTapGesture {
                        isEditingUsername = true
                    }
            }

            Text(bio)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)
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
        let ref = databaseRef.child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.username = userData["username"] as? String ?? "Unknown User"
                self.bio = userData["bio"] as? String ?? "No bio available"
                self.profileImageUrl = userData["profileImageUrl"] as? String ?? ""
            }
        }
    }

    private func fetchUserPosts() {
        let ref = databaseRef.child("posts")
        ref.queryOrdered(byChild: "userId").queryEqual(toValue: userId).observe(.value) { snapshot in
            var fetchedPosts: [UserPost] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postData = snapshot.value as? [String: Any] {
                    let post = UserPost(id: snapshot.key, data: postData)
                    fetchedPosts.append(post)
                }
            }
            self.posts = fetchedPosts
        }
    }

    private func fetchFollowerCount() {
        let ref = databaseRef.child("followers").child(userId)
        ref.observe(.value) { snapshot in
            if let followersDict = snapshot.value as? [String: Any] {
                self.followerCount = followersDict.count
            } else {
                self.followerCount = 0
            }
        }
    }

    private func fetchFollowingCount() {
        let ref = databaseRef.child("following").child(userId)
        ref.observe(.value) { snapshot in
            if let followingDict = snapshot.value as? [String: Any] {
                self.followingCount = followingDict.count
            } else {
                self.followingCount = 0
            }
        }
    }
    
    private func updateUsername() {
        let ref = databaseRef.child("users").child(userId).child("username")
        ref.setValue(username) { error, _ in
            if let error = error {
                print("Failed to update username: \(error.localizedDescription)")
            } else {
                isEditingUsername = false
            }
        }
    }

    private func uploadProfileImage() {
        guard let selectedImage = selectedImage else { return }
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else { return }

        let storagePath = "users/\(userId)/profile.jpg"
        let storageRef = Storage.storage().reference().child(storagePath)

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload image: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }

                if let url = url {
                    self.profileImageUrl = url.absoluteString
                    self.updateProfileImageUrlInDatabase(url.absoluteString)
                }
            }
        }
    }

    
    private func updateProfileImageUrlInDatabase(_ url: String) {
        let ref = databaseRef.child("users").child(userId).child("profileImageUrl")
        ref.setValue(url) { error, _ in
            if let error = error {
                print("Failed to update profile image URL: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    AdminEditUser(userId: "example_user_id")
}
