//
//  CreateView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI

struct CreateView: View {
    @State private var postTitle: String = ""
    @State private var postDescription: String = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Post Title Input
                TextField("Enter Post Title", text: $postTitle)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // Post Description Input
                TextEditor(text: $postDescription)
                    .frame(height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Spacer()
                
                // Submit Button
                Button(action: {
                    // Action for creating a post
                    createPost()
                }) {
                    Text("Create Post")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Create Post")
        }
    }
    
    func createPost() {
        // Logic to create a post (save to database, etc.)
        print("Post created: \(postTitle) - \(postDescription)")
    }
}

#Preview {
    CreateView()
}
