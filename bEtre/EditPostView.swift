//
//  EditPostView.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-28.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct EditPostView: View {
    @State var post: Post
    @Environment(\.dismiss) var dismiss // To close the view after saving
    @State private var isUpdating = false // For showing loading state during save

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Content")) {
                    TextField("Update your post content", text: $post.content)
                }
                
                Section(header: Text("Location")) {
                    TextField("Location", text: $post.location)
                }
                
                // Display the existing image without allowing updates
                Section(header: Text("Image")) {
                    if let imageUrl = URL(string: post.imageUrl) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .foregroundColor(.gray)
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Post")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePost()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func savePost() {
        isUpdating = true
        
        // Save post data with the existing image URL, without modifying the image
        savePostData()
    }

    private func savePostData() {
        guard let userId = Auth.auth().currentUser?.uid, userId == post.userId else {
            print("User is not authorized to edit this post.")
            isUpdating = false
            return
        }

        let ref = Database.database().reference().child("posts").child(post.id)
        let updatedData: [String: Any] = [
            "content": post.content,
            "location": post.location,
            "imageUrl": post.imageUrl // Ensure the existing image URL is kept as is
        ]

        ref.updateChildValues(updatedData) { error, _ in
            if let error = error {
                print("Failed to save changes: \(error.localizedDescription)")
            } else {
                print("Post updated successfully.")
                dismiss()
            }
            isUpdating = false
        }
    }
}
