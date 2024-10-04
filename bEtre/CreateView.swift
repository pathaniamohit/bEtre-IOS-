//
//  CreateView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import CoreLocation

struct CreateView: View {
    @State private var postText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var imageUrl: String? = nil
    @State private var location: String? = nil
    @State private var showingImagePicker = false
    @State private var showingLocationInput = false
    @State private var isPosting = false
    @State private var userName: String = ""
    @State private var profileImageUrl: String? = nil
    @State private var userInputLocation: String = ""
    
    let userId = Auth.auth().currentUser?.uid ?? "default_user"
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    if let profileImageUrl = profileImageUrl, let url = URL(string: profileImageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    }
                    Text(userName.isEmpty ? "Loading..." : userName)
                        .font(.headline)
                }
                .padding()
                
                TextField("Write something...", text: $postText)
                    .padding()
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                VStack {
                    Button(action: {
                        showingImagePicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(selectedImage == nil ? "Select Image" : "Image Selected")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showingLocationInput.toggle()
                    }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(location == nil ? "Add Location" : location!)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        clearPostData()
                    }) {
                        Text("Discard")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        createPost()
                    }) {
                        Text("Post")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(isPosting ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    .disabled(isPosting)
                }
                .padding(.bottom)
            }
            .navigationTitle("Create Post")
            .sheet(isPresented: $showingImagePicker, content: {
                ImagePicker(image: $selectedImage)
            })
            .alert("Enter Location", isPresented: $showingLocationInput) {
                TextField("Enter location", text: $userInputLocation)
                Button("Save", action: {
                    location = userInputLocation 
                })
                Button("Cancel", role: .cancel, action: {})
            } message: {
                Text("Please enter your location")
            }
            .onAppear {
                fetchUserInfo()
            }
        }
    }
    
    // MARK: - Fetch User Info Method
    private func fetchUserInfo() {
        let ref = Database.database().reference().child("users").child(userId)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.userName = userData["userName"] as? String ?? "Unknown User"
                self.profileImageUrl = userData["profileImageUrl"] as? String
            }
        }
    }
    
    // MARK: - Clear Data
    private func clearPostData() {
        postText = ""
        selectedImage = nil
        location = nil
        userInputLocation = ""
    }
    
    // MARK: - Create Post Method
    private func createPost() {
        isPosting = true
        
        guard !postText.isEmpty || selectedImage != nil else {
            print("Post content or image must be provided")
            isPosting = false
            return
        }
        
        let postId = UUID().uuidString
        let ref = Database.database().reference().child("posts").child(postId)
        var postData: [String: Any] = [
            "postId": postId,
            "userId": userId,
            "userName": userName,
            "text": postText,
            "timestamp": ServerValue.timestamp(),
            "location": location ?? ""
        ]
        
        if let image = selectedImage {
            uploadImageToStorage(image: image) { imageUrl in
                postData["imageUrl"] = imageUrl
                ref.setValue(postData) { error, _ in
                    if let error = error {
                        print("Error posting: \(error.localizedDescription)")
                    } else {
                        clearPostData()
                    }
                    isPosting = false
                }
            }
        } else {
            ref.setValue(postData) { error, _ in
                if let error = error {
                    print("Error posting: \(error.localizedDescription)")
                } else {
                    clearPostData()
                }
                isPosting = false
            }
        }
    }
    
    // MARK: - Upload Image Method
    private func uploadImageToStorage(image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if error == nil {
                    storageRef.downloadURL { url, error in
                        completion(url?.absoluteString)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    CreateView()
}
