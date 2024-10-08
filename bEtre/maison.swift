//
//  maison.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-07.
//

import SwiftUI

struct MaisonView: View {
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
        .accentColor(.blue)
        .tabViewStyle(DefaultTabViewStyle())
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all)) // Light background color
        .font(.custom("roboto_serif_regular", size: 16)) // Apply Roboto Serif font globally in MaisonView
    }
}

struct MaisonView_Previews: PreviewProvider {
    static var previews: some View {
        MaisonView()
    }
}

