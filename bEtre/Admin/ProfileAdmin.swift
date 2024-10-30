import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import UIKit

struct AdminProfileView: View {
    @State private var profileName: String = "Username"
    @State private var profileEmail: String = "email@example.com"
    @State private var profileImage: UIImage? = UIImage(systemName: "person.circle.fill")
    @State private var isImagePickerPresented = false
    @State private var imageData: Data?
    @State private var showLogoutAlert = false
    @Environment(\.presentationMode) var presentationMode // Dismiss environment variable
    
    private let storageRef = Storage.storage().reference()
    private let databaseRef = Database.database().reference()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("My Profile")
                    .font(.custom("RobotoSerif-Bold", size: 30))
                
                VStack(spacing: 10) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .onTapGesture {
                                isImagePickerPresented = true
                            }
                    }

                    Text(profileName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(profileEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onAppear {
                    loadUserProfile()
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ProfileImagePicker(image: $profileImage)
                        .onDisappear {
                            if let newImage = profileImage {
                                if let newImageData = newImage.jpegData(compressionQuality: 0.8) {
                                    self.imageData = newImageData
                                    uploadImageToFirebase()
                                }
                            }
                        }
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    ProfileActionRow(icon: "person.crop.circle", title: "Edit Profile") {
                        print("Edit Profile tapped")
                    }
                    Divider()

                    ProfileActionRow(icon: "lock.circle", title: "Account and Privacy") {
                        print("Account and Privacy tapped")
                    }
                    Divider()

                    ProfileActionRow(icon: "info.circle", title: "About") {
                        print("About tapped")
                    }
                    Divider()

                    ProfileActionRow(icon: "arrowshape.turn.up.left.circle", title: "Logout") {
                        showLogoutAlert = true
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(title: Text("Logout"), message: Text("Are you sure you want to logout?"),
                              primaryButton: .destructive(Text("Logout")) {
                                  logoutUser()
                              },
                              secondaryButton: .cancel())
                    }
                    Divider()
                }
                .padding()

                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("My Profile")
    }

    private func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        databaseRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any] {
                self.profileName = data["username"] as? String ?? "Username"
                self.profileEmail = data["email"] as? String ?? "email@example.com"
                if let imageUrl = data["profileImageUrl"] as? String {
                    loadImageFromFirebase(imageUrl: imageUrl)
                }
            } else {
                print("User data not found")
            }
        }
    }

    private func loadImageFromFirebase(imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = uiImage
                }
            } else {
                print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }

    private func uploadImageToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid, let imageData = imageData else { return }

        let storagePath = storageRef.child("users/\(userId)/profile.jpg")
        storagePath.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Image upload failed: \(error.localizedDescription)")
            } else {
                storagePath.downloadURL { url, error in
                    if let url = url {
                        self.saveImageUrlToDatabase(imageUrl: url.absoluteString)
                    }
                }
            }
        }
    }

    private func saveImageUrlToDatabase(imageUrl: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        databaseRef.child("users").child(userId).updateChildValues(["profileImageUrl": imageUrl]) { error, _ in
            if let error = error {
                print("Failed to update profile image URL: \(error.localizedDescription)")
            } else {
                print("Profile image URL updated successfully")
            }
        }
    }

    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            print("User logged out")
            self.presentationMode.wrappedValue.dismiss() // Dismiss view after logout
        } catch let error {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}

struct ProfileActionRow: View {
    var icon: String
    var title: String
    var action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.custom("RobotoSerif-Regular", size: 16))
            
            Spacer()
        }
        .padding(.vertical, 8)
        .onTapGesture {
            action()
        }
    }
}

struct AdminProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AdminProfileView()
    }
}
