//
//  SettingsView.swift
//  bEtre
//
//  Created by Nabeel Shajahan on 2024-10-07.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: EditProfileView(userViewModel: userViewModel)) {
                    Text("Edit Profile")
                }
                NavigationLink(destination: AccountPrivacyView()) {
                    Text("Account & Privacy")
                }
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
                Button(action: {
                    do {
                        try Auth.auth().signOut()
                        dismiss()
                    } catch {
                        print("Logout failed: \(error.localizedDescription)")
                    }
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


#Preview {
    SettingsView()
}
