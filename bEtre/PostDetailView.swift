//
//  PostDetailView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-11-04.
//

import SwiftUI

struct PostDetailView: View {
    let post: AppPost
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: post.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 300)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 300)
            .padding()
            
            Text(post.content)
                .font(.body)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Post Detail")
    }
}

struct PostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PostDetailView(post: AppPost(id: "post1", data: [
            "location": "New York",
            "userId": "user1",
            "imageUrl": "https://example.com/image1.jpg",
            "content": "Enjoying the city vibes!"
        ]))
    }
}
