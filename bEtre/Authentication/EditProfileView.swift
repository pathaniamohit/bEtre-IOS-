//
//  EditProfileView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-10-03.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var bio: String
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingPasswordChangeSheet = false
    @State private var username = ""
    @State private var phoneNumber = ""
    @State private var email = Auth.auth().currentUser?.email ?? ""
    @State private var gender = "Male"
    @State private var profileImageUrl = ""
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var phoneNumberError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    if !profileImageUrl.isEmpty {
                        AsyncImage(url: URL(string: profileImageUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }

                Text("Change Picture")
                    .font(.subheadline)

                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .onChange(of: phoneNumber) { newValue in
                            phoneNumberError = validatePhoneNumber(newValue)
                        }

                    if let phoneNumberError = phoneNumberError {
                        Text(phoneNumberError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    TextField("Bio", text: $bio)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding(.horizontal)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)

                    TextField("Email", text: $email)
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)

                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                
                

                Button(action: {
                    if phoneNumberError == nil {
                        saveProfile()
                        dismiss()
                    }
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.top, 20)

                Button(action: {
                    showingPasswordChangeSheet = true
                }) {
                    Text("Change Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 50)
                        .background(Color.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ProfileImagePicker(image: $inputImage)
            }
            .sheet(isPresented: $showingPasswordChangeSheet) {
                passwordChangePopupContent()
                    .padding()
            }
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }

        if let imageData = inputImage.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("profile_images/\(Auth.auth().currentUser?.uid ?? UUID().uuidString).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Failed to upload image: \(error!.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, error in
                    if let url = url {
                        profileImageUrl = url.absoluteString
                        saveProfile()
                    }
                }
            }
        }
    }

    func validatePhoneNumber(_ phoneNumber: String) -> String? {
        let phoneRegex = "^[0-9+\\-() ]{10,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phoneTest.evaluate(with: phoneNumber) {
            return "Invalid phone number"
        }
        return nil
    }

    func passwordChangePopupContent() -> some View {
        VStack(spacing: 16) {
            SecureField("Old Password", text: $oldPassword)
            SecureField("New Password", text: $newPassword)
            SecureField("Confirm New Password", text: $confirmPassword)

            Button(action: {
                changePassword()
            }) {
                Text("Save Password")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 280, height: 50)
                    .background(Color.green)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .padding()
    }

    func changePassword() {
        guard newPassword == confirmPassword else {
            print("Passwords do not match")
            return
        }
        guard !oldPassword.isEmpty else {
            print("Please enter the old password")
            return
        }

        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user?.reauthenticate(with: credential, completion: { result, error in
            if let error = error {
                print("Re-authentication failed: \(error.localizedDescription)")
                return
            }
            user?.updatePassword(to: newPassword, completion: { error in
                if let error = error {
                    print("Failed to change password: \(error.localizedDescription)")
                } else {
                    print("Password changed successfully")
                }
            })
        })
    }

    func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = Database.database().reference().child("users/\(userId)")
        let userData: [String: Any] = [
            "username": username,
            "phoneNumber": phoneNumber,
            "email": email,
            "gender": gender,
            "profileImageUrl": profileImageUrl,
            "bio": bio
        ]
        userRef.updateChildValues(userData) { error, ref in
            if let error = error {
                print("Failed to update profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully")
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    @State static var bio: String = "Sample bio"
    
    static var previews: some View {
        EditProfileView( bio: $bio)
    }
}
