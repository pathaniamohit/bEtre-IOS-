//
//  ContentView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "magnifyingglass")
            }
            .navigationBarTitle("Explore", displayMode: .inline)
            .accentColor(.blue)
            
            NavigationView {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "person.3")
            }
            .navigationBarTitle("Search Users", displayMode: .inline)
            .accentColor(.green)
            
            NavigationView {
                CreateView()
            }
            .tabItem {
                Label("Create", systemImage: "plus.square")
            }
            .navigationBarTitle("Create Post", displayMode: .inline)
            .accentColor(.purple)
            
            NavigationView {
                InboxView()
            }
            .tabItem {
                Label("Inbox", systemImage: "envelope")
            }
            .navigationBarTitle("Messages", displayMode: .inline)
            .accentColor(.red)
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .navigationBarTitle("Your Profile", displayMode: .inline)
            .accentColor(.orange)
        }
        .accentColor(.blue)  // Main accent color for the selected tab
        .tabViewStyle(DefaultTabViewStyle())
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all)) // Light background color
    }
}

#Preview {
    ContentView()
}
