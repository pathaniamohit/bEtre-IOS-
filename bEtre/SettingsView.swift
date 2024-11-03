import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import  FirebaseDatabase

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false
    @State private var isLoggedOut = false
    @State private var bio: String = "Your bio here"
    private var databaseRef: DatabaseReference = Database.database().reference()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    NavigationLink(destination: EditProfileView(bio: $bio)) {
                        Label("Edit Profile", systemImage: "pencil.circle")
                    }
                    .listRowBackground(Color.clear)

                    NavigationLink(destination: PrivacyScreen()) {
                        Label("Account and Privacy", systemImage: "lock.circle")
                    }
                    .listRowBackground(Color.clear)

                    NavigationLink(destination: AboutScreen()) {
                        Label("About", systemImage: "info.circle")
                    }
                    .listRowBackground(Color.clear)

                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss() 
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.custom("RobotoSerif-Regular", size: 24))
                        .foregroundColor(.primary)
                }
            }
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
            .fullScreenCover(isPresented: $isLoggedOut) {
                LoginView()
            }
        }
    }

    private func logoutUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Explicitly set the user as offline in Firebase
        let userRef = databaseRef.child("users").child(userId)
        userRef.child("isOnline").setValue(false)
        userRef.child("lastActive").setValue(ServerValue.timestamp())
        
        // Proceed with signing out
        do {
            try Auth.auth().signOut()
            isLoggedOut = true
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }

}

struct PrivacyScreen: View {
    var body: some View {
        Text("Account and Privacy Settings")
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutScreen: View {
    var body: some View {
        Text("About the App")
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
