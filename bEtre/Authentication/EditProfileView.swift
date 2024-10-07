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
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss 
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isShowingPasswordChangePopup = false
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
                    if !userViewModel.profileImageUrl.isEmpty, let url = URL(string: userViewModel.profileImageUrl) {
                        AsyncImage(url: url) { image in
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
                    TextField("Username", text: $userViewModel.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    TextField("Phone Number", text: $userViewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .onChange(of: userViewModel.phoneNumber) { newValue in
                            phoneNumberError = validatePhoneNumber(newValue)
                        }

                    if let phoneNumberError = phoneNumberError {
                        Text(phoneNumberError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    TextField("Email", text: $userViewModel.email)
                        .disabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)

                    Picker("Gender", selection: $userViewModel.gender) {
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
                        userViewModel.saveProfile()
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
                    isShowingPasswordChangePopup = true
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
                ImagePicker(image: $inputImage)
            }
            .alert(isPresented: $isShowingPasswordChangePopup) {
                Alert(
                    title: Text("Change Password"),
                    message: passwordChangePopupContent(),
                    primaryButton: .default(Text("Save"), action: changePassword),
                    secondaryButton: .cancel()
                )
            }
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }

        if let imageData = inputImage.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("profile_images/\(userViewModel.userId).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Failed to upload image: \(error!.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, error in
                    if let url = url {
                        userViewModel.profileImageUrl = url.absoluteString
                        userViewModel.saveProfile() // Save the image URL in Realtime Database
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
        let credential = EmailAuthProvider.credential(withEmail: userViewModel.email, password: oldPassword)
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

    func passwordChangePopupContent() -> some View {
        VStack(spacing: 16) {
            SecureField("Old Password", text: $oldPassword)
            SecureField("New Password", text: $newPassword)
            SecureField("Confirm New Password", text: $confirmPassword)
        }
        .padding()
    }
}




struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ProfileImagePicker

        init(parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let userViewModel = UserViewModel()
        EditProfileView(userViewModel: userViewModel)
    }
}
