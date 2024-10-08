//
//  SettingsView.swift
//  bEtre
//
//  Created by Nabeel Shajahan on 2024-10-07.
//

import SwiftUI

import SwiftUI
import Firebase
import FirebaseAuth

struct SettingsView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: EditProfileView(userViewModel: userViewModel)) {
                    Text("Edit Profile")
                }
                
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("Confirm Logout"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Yes")) {
                        logoutUser()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            dismiss() 
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let mockUserViewModel = UserViewModel() 
    return SettingsView(userViewModel: mockUserViewModel)
}

