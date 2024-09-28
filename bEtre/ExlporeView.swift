//
//  ExlporeView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI

struct ExploreView: View {
    @State private var posts: [String] = ["Post 1", "Post 2", "Post 3"] // Sample posts

    var body: some View {
        VStack {
            Text("Explore")
                .font(.largeTitle)
                .padding()

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(posts, id: \.self) { post in
                        Text(post)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Explore")
    }
}


#Preview {
    ExploreView()
}
