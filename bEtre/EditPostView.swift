import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth
import MapKit

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}

struct EditPostView: View {
    @State var post: UserPost
    @Environment(\.dismiss) var dismiss
    @State private var isUpdating = false
    @State private var showingLocationSearch = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var locationName: String? = nil
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText = ""
    @State private var searchResults: [IdentifiableMapItem] = []

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Post Content")) {
                    TextField("Update your post content", text: $post.content)
                }
                
                Section(header: Text("Location")) {
                    HStack {
                        Text(locationName ?? post.location)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            showingLocationSearch.toggle()
                        }) {
                            Text("Select Location")
                        }
                    }
                }
                
                Section(header: Text("Image")) {
                    if let imageUrl = URL(string: post.imageUrl) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .foregroundColor(.gray)
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Post")
            
            if showingLocationSearch {
                ScrollView {
                    locationSearchView()
                }
                .background(Color.white)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Button("Save") {
                    savePost()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func locationSearchView() -> some View {
        VStack {
            // Search bar
            HStack {
                TextField("Search for a location", text: $searchText, onCommit: performSearch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Search", action: performSearch)
                    .padding(.trailing)
            }
            
            // Map view with scrollable content
            Map(coordinateRegion: $mapRegion, annotationItems: searchResults) { item in
                MapPin(coordinate: item.mapItem.placemark.coordinate)
            }
            .frame(height: 300)
            .cornerRadius(10)
            .padding()
            
            // Search results list
            List(searchResults) { item in
                Button(action: {
                    let coordinate = item.mapItem.placemark.coordinate
                    locationName = item.mapItem.name ?? "Selected Location"
                    selectedCoordinate = coordinate
                    zoomToRegion(coordinate)  // Zoom to selected location
                    showingLocationSearch = false // Dismiss search view
                }) {
                    Text(item.mapItem.name ?? "Unknown Location")
                }
            }
            .frame(height: 200) // Limit the list height for better scrolling
        }
        .background(Color.white)
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
            searchResults = response.mapItems.map { IdentifiableMapItem(mapItem: $0) }
        }
    }
    
    // Center and zoom in on the selected location
    private func zoomToRegion(_ coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    private func savePost() {
        isUpdating = true
        savePostData()
    }

    private func savePostData() {
        guard let userId = Auth.auth().currentUser?.uid, userId == post.userId else {
            print("User is not authorized to edit this post.")
            isUpdating = false
            return
        }

        let ref = Database.database().reference().child("posts").child(post.id)
        let updatedData: [String: Any] = [
            "content": post.content,
            "location": locationName ?? post.location,
            "imageUrl": post.imageUrl
        ]

        ref.updateChildValues(updatedData) { error, _ in
            if let error = error {
                print("Failed to save changes: \(error.localizedDescription)")
            } else {
                print("Post updated successfully.")
                dismiss()
            }
            isUpdating = false
        }
    }
}
