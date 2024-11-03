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
import MapKit

struct CreateView: View {
    @State private var postText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var imageUrl: String? = nil
    @State private var location: String? = nil
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false
    @State private var isPosting = false
    @State private var userName: String = ""
    @State private var profileImageUrl: String? = nil
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    let userId = Auth.auth().currentUser?.uid ?? "default_user"
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Post")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, -55)
                    .padding(.bottom, 20)
                
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
                    
                    Spacer()
                }
                .padding()
                .padding(.top, -40)
                
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
                        showingLocationPicker.toggle()
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
            .sheet(isPresented: $showingImagePicker, content: {
                ImagePicker(image: $selectedImage)
            })
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedCoordinate: $selectedCoordinate, locationName: $location)
            }
            .onAppear {
                fetchUserInfo()
            }
        }
    }
    
    private func fetchUserInfo() {
        let ref = Database.database().reference().child("users").child(userId)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.userName = userData["username"] as? String ?? "Unknown User"
                self.profileImageUrl = userData["profileImageUrl"] as? String
            }
        }
    }
    
    private func clearPostData() {
        postText = ""
        selectedImage = nil
        location = nil
        selectedCoordinate = nil
    }
    
    private func createPost() {
        isPosting = true
        
        guard !postText.isEmpty || selectedImage != nil else {
            print("Post content or image must be provided")
            isPosting = false
            return
        }
        
        if let image = selectedImage {
            uploadImageToStorage(image: image) { imageUrl in
                guard let imageUrl = imageUrl else {
                    print("Failed to upload image")
                    self.isPosting = false
                    return
                }
                self.savePostData(imageUrl: imageUrl)
            }
        } else {
            savePostData(imageUrl: nil)
        }
    }
    
    private func savePostData(imageUrl: String?) {
        let postId = UUID().uuidString
        let ref = Database.database().reference().child("posts").child(postId)
        
        var postData: [String: Any] = [
            "postId": postId,
            "userId": userId,
            "userName": userName,
            "content": postText,
            "timestamp": ServerValue.timestamp(),
            "location": location ?? ""
        ]
        
        if let imageUrl = imageUrl {
            postData["imageUrl"] = imageUrl
        }
        
        ref.setValue(postData) { error, _ in
            if let error = error {
                print("Error posting: \(error.localizedDescription)")
            } else {
                clearPostData()
            }
            isPosting = false
        }
    }
    
    func uploadImageToStorage(image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("post_images/\(UUID().uuidString).jpg")
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.customMetadata = ["userId": userId]
            
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if error == nil {
                    storageRef.downloadURL { url, error in
                        if let url = url {
                            print("Image uploaded successfully: \(url.absoluteString)")
                            completion(url.absoluteString)
                        } else {
                            print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
                            completion(nil)
                        }
                    }
                } else {
                    print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        } else {
            print("Error converting image to data.")
            completion(nil)
        }
    }
}

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var locationName: String?
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search for a location", text: $searchText, onCommit: performSearch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Search", action: performSearch)
                    .padding(.trailing)
            }
            
            UserLocationMapView(coordinateRegion: $mapRegion, annotations: createAnnotations())
                .edgesIgnoringSafeArea(.all)
            
            List(searchResults, id: \.self) { item in
                Button(action: {
                    mapRegion.center = item.placemark.coordinate
                    locationName = item.name ?? "Selected Location"
                    selectedCoordinate = item.placemark.coordinate
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(item.name ?? "Unknown Location")
                }
            }
        }
    }
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = mapRegion
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            searchResults = response.mapItems
        }
    }
    
    private func createAnnotations() -> [MKPointAnnotation] {
        return searchResults.map { item in
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.placemark.coordinate
            annotation.title = item.name
            return annotation
        }
    }
}

struct UserLocationMapView: UIViewRepresentable {
    @Binding var coordinateRegion: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotations(annotations)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(coordinateRegion, animated: true)
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UserLocationMapView
        
        init(_ parent: UserLocationMapView) {
            self.parent = parent
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
