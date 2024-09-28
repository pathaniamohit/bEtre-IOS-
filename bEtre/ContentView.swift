//
//  ContentView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            CreateView()
                .tabItem {
                    Image(systemName: "plus.app")
                    Text("Create")
                }
            
            InboxView()
                .tabItem {
                    Image(systemName: "envelope")
                    Text("Inbox")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .accentColor(.purple) // Customize the tab color
    }
}

// Explore View
struct ExploreView: View {
    var body: some View {
        VStack {
            Text("Explore")
                .font(.largeTitle)
                .padding()
            // Add your explore content here
        }
    }
}

// Search View
struct SearchView: View {
    var body: some View {
        VStack {
            Text("Search")
                .font(.largeTitle)
                .padding()
            // Add your search content here
        }
    }
}

// Create View
struct CreateView: View {
    var body: some View {
        VStack {
            Text("Create")
                .font(.largeTitle)
                .padding()
            // Add your create content here
        }
    }
}

// Inbox View
struct InboxView: View {
    var body: some View {
        VStack {
            Text("Inbox")
                .font(.largeTitle)
                .padding()
            // Add your inbox content here
        }
    }
}

// Profile View
struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
                .padding()
            // Add your profile content here
        }
    }
}

#Preview {
    ContentView()
}

