//
//  ContentView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//


import SwiftUI

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
            
            NavigationView {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "person.3")
            }
            
            NavigationView {
                CreateView()
            }
            .tabItem {
                Label("Create", systemImage: "plus.square")
            }
            
            NavigationView {
                InboxView()
            }
            .tabItem {
                Label("Inbox", systemImage: "envelope")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}


#Preview {
    ContentView()
}
