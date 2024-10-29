import SwiftUI
import Firebase
import FirebaseDatabase

struct User: Identifiable {
    var id: String
    var username: String
    var profileImageUrl: String

    init(id: String, data: [String: Any]) {
        self.id = id
        self.username = data["username"] as? String ?? "Unknown"
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    }
}

struct Suggestion: Identifiable {
    var id = UUID()
    var text: String
    var type: SuggestionType
}

enum SuggestionType {
    case username, location
}

struct SearchView: View {
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var posts: [Post] = []
    @State private var suggestions: [Suggestion] = []
    @State private var userIdToUsernameMap: [String: String] = [:]
    @State private var tags: [String] = ["All"] // Start with "All" and add locations dynamically

    var body: some View {
        VStack {
            // Search Field
            TextField("Search users or locations...", text: $searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: searchText) { newValue in
                    if newValue.isEmpty {
                        users.removeAll()
                        suggestions.removeAll()
                    } else {
                        searchUsersAndLocations()
                    }
                }

            // Tag Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Button(action: {
                            searchText = tag == "All" ? "" : tag
                            fetchPosts(query: tag == "All" ? "" : tag)
                        }) {
                            Text(tag.uppercased())
                                .padding(8)
                                .background(searchText == tag ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(searchText == tag ? .white : .black)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider().padding(.vertical)

            // Grid of Posts with increased size
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(posts) { post in
                        VStack {
                            if let url = URL(string: post.imageUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 160, height: 160)
                                .cornerRadius(10)
                                .clipped()
                            }
                        }
                        .onTapGesture {
                            // Code to open the post's detail view goes here
                        }
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .onAppear {
            fetchAllPosts() // Fetch all posts on view load
            fetchUsers() // Populate userIdToUsernameMap on view load
            fetchUniqueLocations() // Load dynamic tags based on locations
        }
    }

    func fetchUsers() {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedUsers: [User] = []
            var fetchedUsernames: [String: String] = [:] // Temporary map to hold usernames

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let userData = snapshot.value as? [String: Any],
                   let username = userData["username"] as? String {
                    let userId = snapshot.key
                    fetchedUsernames[userId] = username.lowercased() // Populate the map in lowercase
                    let user = User(id: userId, data: userData)
                    fetchedUsers.append(user)
                }
            }

            self.users = fetchedUsers
            self.userIdToUsernameMap = fetchedUsernames // Update the state variable
        }
    }

    func searchUsersAndLocations() {
        searchUsers()
        filterSuggestions(for: searchText)
    }

    func searchUsers() {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedUsers: [User] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let userData = snapshot.value as? [String: Any],
                   let username = userData["username"] as? String,
                   username.lowercased().contains(searchText.lowercased()) {
                    let user = User(id: snapshot.key, data: userData)
                    fetchedUsers.append(user)
                }
            }
            self.users = fetchedUsers
        }
    }

    func filterSuggestions(for query: String) {
        suggestions.removeAll()
        
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var locationSuggestions: [Suggestion] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let location = snapshot.childSnapshot(forPath: "location").value as? String,
                   location.lowercased().contains(query.lowercased()) {
                    locationSuggestions.append(Suggestion(text: location, type: .location))
                }
            }
            suggestions = locationSuggestions
        }
    }

    func fetchPosts(query: String) {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let postData = snapshot.value as? [String: Any] {
                    let post = Post(id: snapshot.key, data: postData)

                    if query.isEmpty || post.location.lowercased().contains(query.lowercased()) ||
                        (userIdToUsernameMap[post.userId]?.contains(query.lowercased()) ?? false) {
                        fetchedPosts.append(post)
                    }
                }
            }
            self.posts = fetchedPosts
        }
    }

    func fetchAllPosts() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot, let postData = snapshot.value as? [String: Any] {
                    let post = Post(id: snapshot.key, data: postData)
                    fetchedPosts.append(post)
                }
            }
            self.posts = fetchedPosts
        }
    }

    func fetchUniqueLocations() {
        let ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            var uniqueLocations = Set<String>()
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let location = snapshot.childSnapshot(forPath: "location").value as? String {
                    uniqueLocations.insert(location)
                }
            }
            // Convert set to array, shuffle, and limit to a few locations for display
            let shuffledLocations = Array(uniqueLocations).shuffled().prefix(5)
            tags = ["All"] + shuffledLocations
        }
    }
}
