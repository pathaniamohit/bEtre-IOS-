////import SwiftUI
////import Firebase
////import FirebaseAuth
////import FirebaseDatabase
////import SDWebImageSwiftUI
////
////struct UserProfileView: View {
////    let userId: String // ID of the profile being viewed
////    @State private var posts: [UserPost] = []
////    @State private var profileImageUrl: String = ""
////    @State private var username: String = "Loading..."
////    @State private var bio: String = "Loading bio..."
////    @State private var followerCount: Int = 0
////    @State private var followingCount: Int = 0
////    @State private var isFollowing = false // Track if current user is following
////    @State private var isCurrentUser = false // Track if viewing current user's profile
////
////    var body: some View {
////        ScrollView {
////            VStack {
////                profileHeader
////
////                profileStats
////
////                Divider().padding(.vertical)
////
////                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
////                    ForEach(posts) { post in
////                        if let url = URL(string: post.imageUrl) {
////                            WebImage(url: url)
////                                .resizable()
////                                .scaledToFill()
////                                .frame(width: 160, height: 160)
////                                .cornerRadius(10)
////                                .clipped()
////                        } else {
////                            Color.gray.frame(width: 160, height: 160).cornerRadius(10)
////                        }
////                    }
////                }
////                .padding(.horizontal)
////
////                Spacer()
////            }
////            .padding()
////            .onAppear {
////                isCurrentUser = (Auth.auth().currentUser?.uid == userId) // Check if viewing own profile
////                fetchUserProfile()
////                fetchUserPosts()
////                fetchFollowerCount()
////                fetchFollowingCount()
////                if !isCurrentUser { // Only check following status if it's not the current user's profile
////                    checkIfFollowing()
////                }
////            }
////        }
////    }
////
////    private var profileHeader: some View {
////        VStack {
////            if let url = URL(string: profileImageUrl) {
////                WebImage(url: url)
////                    .resizable()
////                    .scaledToFill()
////                    .frame(width: 100, height: 100)
////                    .clipShape(Circle())
////                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
////                    .shadow(radius: 5)
////            } else {
////                Image(systemName: "person.circle.fill")
////                    .resizable()
////                    .frame(width: 100, height: 100)
////                    .clipShape(Circle())
////                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
////                    .shadow(radius: 5)
////            }
////            
////            Text(username)
////                .font(.headline)
////                .bold()
////            
////            // Follow Button - Only visible if not viewing own profile
////            if !isCurrentUser {
////                Button(action: {
////                    toggleFollowStatus()
////                }) {
////                    Text(isFollowing ? "Following" : "Follow")
////                        .font(.subheadline)
////                        .padding()
////                        .frame(maxWidth: .infinity)
////                        .background(isFollowing ? Color.green : Color.blue)
////                        .foregroundColor(.white)
////                        .cornerRadius(10)
////                }
////                .padding(.top, 10)
////            }
////        }
////        .padding(.bottom, 10)
////    }
////
////    private var profileStats: some View {
////        HStack(spacing: 50) {
////            statView(number: posts.count, label: "Photos")
////            statView(number: followerCount, label: "Followers")
////            statView(number: followingCount, label: "Following")
////        }
////        .padding(.horizontal)
////        .padding(.vertical, 10)
////    }
////
////    private func statView(number: Int, label: String) -> some View {
////        VStack {
////            Text("\(number)")
////                .font(.headline)
////            Text(label)
////                .font(.subheadline)
////                .foregroundColor(.secondary)
////        }
////    }
////
////    private func fetchUserProfile() {
////        let ref = Database.database().reference().child("users").child(userId)
////        ref.observeSingleEvent(of: .value) { snapshot in
////            if let userData = snapshot.value as? [String: Any] {
////                self.username = userData["username"] as? String ?? "Unknown User"
////                self.bio = userData["bio"] as? String ?? "No bio available"
////                self.profileImageUrl = userData["profileImageUrl"] as? String ?? ""
////            }
////        }
////    }
////
////    private func fetchUserPosts() {
////        let ref = Database.database().reference().child("posts")
////        ref.queryOrdered(byChild: "userId").queryEqual(toValue: userId).observe(.value) { snapshot in
////            var fetchedPosts: [UserPost] = []
////            for child in snapshot.children {
////                if let snapshot = child as? DataSnapshot,
////                   let postData = snapshot.value as? [String: Any] {
////                    let post = UserPost(id: snapshot.key, data: postData)
////                    fetchedPosts.append(post)
////                }
////            }
////            self.posts = fetchedPosts
////        }
////    }
////
////    private func fetchFollowerCount() {
////        let ref = Database.database().reference().child("followers").child(userId)
////        ref.observe(.value) { snapshot in
////            if let followersDict = snapshot.value as? [String: Any] {
////                self.followerCount = followersDict.count
////            } else {
////                self.followerCount = 0
////            }
////        }
////    }
////
////    private func fetchFollowingCount() {
////        let ref = Database.database().reference().child("following").child(userId)
////        ref.observe(.value) { snapshot in
////            if let followingDict = snapshot.value as? [String: Any] {
////                self.followingCount = followingDict.count
////            } else {
////                self.followingCount = 0
////            }
////        }
////    }
////
////    private func checkIfFollowing() {
////        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
////        let ref = Database.database().reference().child("followers").child(userId).child(currentUserId)
////        ref.observeSingleEvent(of: .value) { snapshot in
////            if let isFollowing = snapshot.value as? Bool {
////                self.isFollowing = isFollowing
////            }
////        }
////    }
////
////    private func toggleFollowStatus() {
////        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
////        let followersRef = Database.database().reference().child("followers").child(userId).child(currentUserId)
////        let followingRef = Database.database().reference().child("following").child(currentUserId).child(userId)
////        
////        if isFollowing {
////            // Unfollow user
////            followersRef.setValue(nil)
////            followingRef.setValue(nil)
////            followerCount -= 1
////        } else {
////            // Follow user
////            followersRef.setValue(true)
////            followingRef.setValue(true)
////            followerCount += 1
////        }
////        
////        isFollowing.toggle()
////    }
////}
////
////#Preview {
////    UserProfileView(userId: "example_user_id")
////}
//
//
////import SwiftUI
////import Firebase
////import FirebaseAuth
////import FirebaseDatabase
////import SDWebImageSwiftUI
////
////// MARK: - Data Model for AppPost
////
////// MARK: - ReportCategory Enum
////enum ReportCategory: String, CaseIterable, Identifiable {
////    case spam = "Spam"
////    case harassment = "Harassment"
////    case inappropriateContent = "Inappropriate Content"
////    case other = "Other"
////    
////    var id: String { self.rawValue }
////}
////
////// MARK: - ReportedProfile Struct (Optional)
////struct ReportedProfile: Identifiable {
////    var id: String
////    var reportedProfileId: String
////    var reportedBy: String
////    var reportedByUsername: String
////    var reason: String
////    var category: String
////    var timestamp: Double
////    var status: String
////}
//
//
//import SwiftUI
//import Firebase
//import FirebaseAuth
//import FirebaseDatabase
//import SDWebImageSwiftUI
//
//import SwiftUI
//import Firebase
//import FirebaseAuth
//import FirebaseDatabase
//
//struct ReportView: View {
//    @Environment(\.presentationMode) var presentationMode
//    
//    // Binding variables to pass data back to UserProfileView
//    @Binding var isSubmitting: Bool
//    @Binding var showConfirmation: Bool
//    @Binding var showError: Bool
//    @Binding var errorMessage: String
//    
//    // Report details
//    @State private var selectedCategory: ReportCategory = .spam
//    @State private var reportReason: String = ""
//    
//    var userId: String // ID of the profile being reported
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                Section(header: Text("Select Category")) {
//                    Picker("Category", selection: $selectedCategory) {
//                        ForEach(ReportCategory.allCases) { category in
//                            Text(category.rawValue).tag(category)
//                        }
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                }
//                
//                Section(header: Text("Reason")) {
//                    TextEditor(text: $reportReason)
//                        .frame(height: 150)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                        )
//                        .padding(.vertical, 4)
//                    
//                    Text("\(reportReason.count)/500")
//                        .font(.caption)
//                        .foregroundColor(reportReason.count > 500 ? .red : .gray)
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                }
//            }
//            .navigationTitle("Report Profile")
//            .navigationBarItems(
//                leading:
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    },
//                trailing:
//                    Button("Submit") {
//                        submitReport()
//                    }
//                    .disabled(reportReason.trimmingCharacters(in: .whitespaces).isEmpty || reportReason.count > 500 || isSubmitting)
//            )
//            .alert(isPresented: $showError) {
//                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
//            }
//            .alert(isPresented: $showConfirmation) {
//                Alert(title: Text("Report Submitted"), message: Text("Thank you for your report. Our team will review it shortly."), dismissButton: .default(Text("OK")) {
//                    presentationMode.wrappedValue.dismiss()
//                })
//            }
//        }
//    }
//    
//    // MARK: - Submit Report Function
//    private func submitReport() {
//        guard let reporterId = Auth.auth().currentUser?.uid else {
//            self.errorMessage = "You must be logged in to report profiles."
//            self.showError = true
//            return
//        }
//        
//        // Fetch reporter's username
//        let userRef = Database.database().reference().child("users").child(reporterId)
//        userRef.observeSingleEvent(of: .value) { snapshot in
//            guard let userData = snapshot.value as? [String: Any],
//                  let reporterUsername = userData["username"] as? String else {
//                self.errorMessage = "Failed to fetch your information."
//                self.showError = true
//                return
//            }
//            
//            // Prepare report data
//            let reportRef = Database.database().reference().child("reported_profiles").childByAutoId()
//            let timestamp = Date().timeIntervalSince1970
//            
//            let reportData: [String: Any] = [
//                "reportedProfileId": userId,
//                "reportedBy": reporterId,
//                "reportedByUsername": reporterUsername,
//                "reason": reportReason.trimmingCharacters(in: .whitespacesAndNewlines),
//                "category": selectedCategory.rawValue,
//                "timestamp": timestamp,
//                "status": "pending"
//            ]
//            
//            // Submit report
//            self.isSubmitting = true
//            reportRef.setValue(reportData) { error, _ in
//                self.isSubmitting = false
//                if let error = error {
//                    self.errorMessage = "Failed to submit report: \(error.localizedDescription)"
//                    self.showError = true
//                } else {
//                    self.showConfirmation = true
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Data Model for AppPost
//
//// MARK: - ReportCategory Enum
//enum ReportCategory: String, CaseIterable, Identifiable {
//    case spam = "Spam"
//    case harassment = "Harassment"
//    case inappropriateContent = "Inappropriate Content"
//    case other = "Other"
//    
//    var id: String { self.rawValue }
//}
//
//// MARK: - ReportedProfile Struct (Optional)
//struct ReportedProfile: Identifiable {
//    var id: String
//    var reportedProfileId: String
//    var reportedBy: String
//    var reportedByUsername: String
//    var reason: String
//    var category: String
//    var timestamp: Double
//    var status: String
//}
//
//struct UserProfileView: View {
//    let userId: String // ID of the profile being viewed
//    
//    // Profile Data States
//    @State private var user: AppUser?
//    @State private var posts: [AppPost] = []
//    @State private var followerCount: Int = 0
//    @State private var followingCount: Int = 0
//    @State private var isFollowing: Bool = false
//    @State private var isCurrentUser: Bool = false
//    
//    // Reporting States
//    @State private var showReportSheet: Bool = false
//    @State private var showConfirmationAlert: Bool = false
//    @State private var showErrorAlert: Bool = false
//    @State private var errorMessage: String = ""
//    @State private var hasReported: Bool = false
//    @State private var isSubmittingReport: Bool = false
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                // Profile Header
//                profileHeader
//                
//                // Profile Stats
//                profileStats
//                
//                Divider()
//                
//                // User Bio
//                
//                Divider()
//                
//                // User Posts
//                if posts.isEmpty {
//                    Text("No posts available.")
//                        .foregroundColor(.gray)
//                        .padding()
//                } else {
//                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
//                        ForEach(posts) { post in
//                            NavigationLink(destination: PostDetailView(post: post)) {
//                                AsyncImage(url: URL(string: post.imageUrl)) { phase in
//                                    switch phase {
//                                    case .empty:
//                                        ProgressView()
//                                            .frame(width: 160, height: 160)
//                                    case .success(let image):
//                                        image
//                                            .resizable()
//                                            .scaledToFill()
//                                            .frame(width: 160, height: 160)
//                                            .cornerRadius(10)
//                                            .clipped()
//                                    case .failure:
//                                        Image(systemName: "photo")
//                                            .resizable()
//                                            .scaledToFill()
//                                            .frame(width: 160, height: 160)
//                                            .foregroundColor(.gray)
//                                    @unknown default:
//                                        EmptyView()
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .onAppear {
//                checkIfCurrentUser()
//                fetchUserProfile()
//                fetchUserPosts()
//                fetchFollowerCount()
//                fetchFollowingCount()
//                if !isCurrentUser {
//                    checkIfFollowing()
//                    checkIfReported()
//                }
//            }
//            .sheet(isPresented: $showReportSheet) {
//                ReportView(
//                    isSubmitting: $isSubmittingReport,
//                    showConfirmation: $showConfirmationAlert,
//                    showError: $showErrorAlert,
//                    errorMessage: $errorMessage,
//                    userId: userId
//                )
//            }
//            .alert("Report Submitted", isPresented: $showConfirmationAlert, actions: {
//                Button("OK", role: .cancel) {}
//            }, message: {
//                Text("Thank you for your report. Our team will review it shortly.")
//            })
//            .alert("Error", isPresented: $showErrorAlert, actions: {
//                Button("OK", role: .cancel) {}
//            }, message: {
//                Text(errorMessage)
//            })
//        }
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // MARK: - Profile Header View
//    private var profileHeader: some View {
//        VStack(alignment: .center, spacing: 8) {
//            // Profile Image
//            AsyncImage(url: URL(string: user?.profileImageUrl ?? "")) { phase in
//                switch phase {
//                case .empty:
//                    ProgressView()
//                        .frame(width: 100, height: 100)
//                case .success(let image):
//                    image
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 100, height: 100)
//                        .clipShape(Circle())
//                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
//                        .shadow(radius: 5)
//                case .failure:
//                    Image(systemName: "person.circle.fill")
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 100, height: 100)
//                        .foregroundColor(.gray)
//                        .clipShape(Circle())
//                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
//                        .shadow(radius: 5)
//                @unknown default:
//                    EmptyView()
//                }
//            }
//            
//            // Username
//            Text(user?.username ?? "Unknown User")
//                .font(.headline)
//                .bold()
//            
//            // Follow and Report Buttons
//            if !isCurrentUser {
//                HStack(spacing: 16) {
//                    // Follow/Unfollow Button
//                    Button(action: {
//                        toggleFollowStatus()
//                    }) {
//                        Text(isFollowing ? "Unfollow" : "Follow")
//                            .font(.subheadline)
//                            .frame(minWidth: 0, maxWidth: .infinity)
//                            .padding()
//                            .background(isFollowing ? Color.red : Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    
//                    // Report Profile Button
//                    Button(action: {
//                        showReportSheet = true
//                    }) {
//                        Text("Report")
//                            .font(.subheadline)
//                            .frame(minWidth: 0, maxWidth: .infinity)
//                            .padding()
//                            .background(hasReported ? Color.gray : Color.red)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .disabled(hasReported)
//                }
//                .padding(.horizontal)
//                
//                // Reported Confirmation
//                if hasReported {
//                    Text("You have already reported this profile.")
//                        .font(.caption)
//                        .foregroundColor(.red)
//                        .padding(.top, 2)
//                        .padding(.horizontal)
//                }
//            }
//        }
//    }
//    
//    // MARK: - Profile Stats View
//    private var profileStats: some View {
//        HStack(spacing: 50) {
//            statView(number: posts.count, label: "Photos")
//            statView(number: followerCount, label: "Followers")
//            statView(number: followingCount, label: "Following")
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 10)
//    }
//    
//    private func statView(number: Int, label: String) -> some View {
//        VStack {
//            Text("\(number)")
//                .font(.headline)
//            Text(label)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//        }
//    }
//    
//    // MARK: - Fetch User Profile
//    private func fetchUserProfile() {
//        let ref = Database.database().reference().child("users").child(userId)
//        ref.observeSingleEvent(of: .value) { snapshot in
//            if let userData = snapshot.value as? [String: Any] {
//                let fetchedUser = AppUser(id: userId, data: userData)
//                self.user = fetchedUser
//            }
//        }
//    }
//    
//    // MARK: - Fetch User Posts
//    private func fetchUserPosts() {
//        let ref = Database.database().reference().child("posts")
//        ref.queryOrdered(byChild: "userId").queryEqual(toValue: userId).observe(.value) { snapshot in
//            var fetchedPosts: [AppPost] = []
//            for child in snapshot.children {
//                if let childSnapshot = child as? DataSnapshot,
//                   let postData = childSnapshot.value as? [String: Any] {
//                    let post = AppPost(id: childSnapshot.key, data: postData)
//                    fetchedPosts.append(post)
//                }
//            }
//            self.posts = fetchedPosts
//        }
//    }
//    
//    // MARK: - Fetch Follower Count
//    private func fetchFollowerCount() {
//        let ref = Database.database().reference().child("followers").child(userId)
//        ref.observe(.value) { snapshot in
//            if let followersDict = snapshot.value as? [String: Any] {
//                self.followerCount = followersDict.count
//            } else {
//                self.followerCount = 0
//            }
//        }
//    }
//    
//    // MARK: - Fetch Following Count
//    private func fetchFollowingCount() {
//        let ref = Database.database().reference().child("following").child(userId)
//        ref.observe(.value) { snapshot in
//            if let followingDict = snapshot.value as? [String: Any] {
//                self.followingCount = followingDict.count
//            } else {
//                self.followingCount = 0
//            }
//        }
//    }
//    
//    // MARK: - Check If Current User
//    private func checkIfCurrentUser() {
//        if let currentUserId = Auth.auth().currentUser?.uid {
//            self.isCurrentUser = (currentUserId == userId)
//        } else {
//            self.isCurrentUser = false
//        }
//    }
//    
//    // MARK: - Check If Following
//    private func checkIfFollowing() {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        let ref = Database.database().reference().child("followers").child(userId).child(currentUserId)
//        ref.observeSingleEvent(of: .value) { snapshot in
//            if let isFollowing = snapshot.value as? Bool {
//                self.isFollowing = isFollowing
//            }
//        }
//    }
//    
//    // MARK: - Toggle Follow Status
//    private func toggleFollowStatus() {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        let followersRef = Database.database().reference().child("followers").child(userId).child(currentUserId)
//        let followingRef = Database.database().reference().child("following").child(currentUserId).child(userId)
//        
//        if isFollowing {
//            // Unfollow user
//            followersRef.setValue(nil)
//            followingRef.setValue(nil)
//            followerCount = max(followerCount - 1, 0)
//        } else {
//            // Follow user
//            followersRef.setValue(true)
//            followingRef.setValue(true)
//            followerCount += 1
//        }
//        
//        isFollowing.toggle()
//    }
//    
//    // MARK: - Check If Already Reported
//    private func checkIfReported() {
//        guard let reporterId = Auth.auth().currentUser?.uid else { return }
//        let ref = Database.database().reference().child("reported_profiles")
//        ref.queryOrdered(byChild: "reportedProfileId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
//            for child in snapshot.children {
//                if let childSnapshot = child as? DataSnapshot,
//                   let reportData = childSnapshot.value as? [String: Any],
//                   let reportedBy = reportData["reportedBy"] as? String,
//                   reportedBy == reporterId {
//                    self.hasReported = true
//                    return
//                }
//            }
//            self.hasReported = false
//        }
//    }
//
//
//    // MARK: - Check If Already Reported
//    private func checkIfAlreadyReported(completion: @escaping (Bool) -> Void) {
//        guard let reporterId = Auth.auth().currentUser?.uid else {
//            completion(false)
//            return
//        }
//        
//        let ref = Database.database().reference().child("reported_profiles")
//        ref.queryOrdered(byChild: "reportedProfileId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
//            for child in snapshot.children {
//                if let childSnapshot = child as? DataSnapshot,
//                   let reportData = childSnapshot.value as? [String: Any],
//                   let reportedBy = reportData["reportedBy"] as? String,
//                   reportedBy == reporterId {
//                    self.hasReported = true
//                    completion(true)
//                    return
//                }
//            }
//            self.hasReported = false
//            completion(false)
//        }
//    }
//}
//
//
//// MARK: - Preview
//
//struct UserProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserProfileView(userId: "example_user_id")
//    }
//}


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImageSwiftUI

// MARK: - Data Model for AppPost



struct ReportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Binding variables to pass data back to UserProfileView
    @Binding var isSubmitting: Bool
    @Binding var showConfirmation: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    // Report details
    @State private var reportReason: String = ""
    
    var userId: String // ID of the profile being reported
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason")) {
                    TextEditor(text: $reportReason)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.vertical, 4)
                    
                    Text("\(reportReason.count)/500")
                        .font(.caption)
                        .foregroundColor(reportReason.count > 500 ? .red : .gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("Report Profile")
            .navigationBarItems(
                leading:
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                trailing:
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(reportReason.trimmingCharacters(in: .whitespaces).isEmpty || reportReason.count > 500 || isSubmitting)
            )
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Report Submitted"), message: Text("Thank you for your report. Our team will review it shortly."), dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    // MARK: - Submit Report Function
    private func submitReport() {
        guard let reporterId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "You must be logged in to report profiles."
            self.showError = true
            return
        }
        
        // Fetch reporter's username
        let userRef = Database.database().reference().child("users").child(reporterId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let reporterUsername = userData["username"] as? String else {
                self.errorMessage = "Failed to fetch your information."
                self.showError = true
                return
            }
            
            // Prepare report data
            let reportRef = Database.database().reference().child("reported_profiles").childByAutoId()
            let timestamp = Date().timeIntervalSince1970
            
            let reportData: [String: Any] = [
                "reportedProfileId": userId,
                "reportedBy": reporterId,
                "reportedByUsername": reporterUsername,
                "reason": reportReason.trimmingCharacters(in: .whitespacesAndNewlines),
                "timestamp": timestamp,
                "status": "pending"
            ]
            
            // Submit report
            self.isSubmitting = true
            reportRef.setValue(reportData) { error, _ in
                self.isSubmitting = false
                if let error = error {
                    self.errorMessage = "Failed to submit report: \(error.localizedDescription)"
                    self.showError = true
                } else {
                    self.showConfirmation = true
                }
            }
        }
    }
}


// MARK: - ReportedProfile Struct (Optional)
struct ReportedProfile: Identifiable {
    var id: String
    var reportedProfileId: String
    var reportedBy: String
    var reportedByUsername: String
    var reason: String
    var timestamp: Double
    var status: String
}

struct UserProfileView: View {
    let userId: String // ID of the profile being viewed
    
    // Profile Data States
    @State private var user: AppUser?
    @State private var posts: [AppPost] = []
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isFollowing: Bool = false
    @State private var isCurrentUser: Bool = false
    
    // Reporting States
    @State private var showReportSheet: Bool = false
    @State private var showConfirmationAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var hasReported: Bool = false
    @State private var isSubmittingReport: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Profile Header
                profileHeader
                
                // Profile Stats
                profileStats
                
                Divider()
                
                // User Bio
                
                Divider()
                
                // User Posts
                if posts.isEmpty {
                    Text("No posts available.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                AsyncImage(url: URL(string: post.imageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 160, height: 160)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 160, height: 160)
                                            .cornerRadius(10)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 160, height: 160)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                checkIfCurrentUser()
                fetchUserProfile()
                fetchUserPosts()
                fetchFollowerCount()
                fetchFollowingCount()
                if !isCurrentUser {
                    checkIfFollowing()
                    checkIfReported()
                }
            }
            .sheet(isPresented: $showReportSheet) {
                ReportView(
                    isSubmitting: $isSubmittingReport,
                    showConfirmation: $showConfirmationAlert,
                    showError: $showErrorAlert,
                    errorMessage: $errorMessage,
                    userId: userId
                )
            }
            .alert("Report Submitted", isPresented: $showConfirmationAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text("Thank you for your report. Our team will review it shortly.")
            })
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage)
            })
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Profile Header View
    private var profileHeader: some View {
        VStack(alignment: .center, spacing: 8) {
            // Profile Image
            AsyncImage(url: URL(string: user?.profileImageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Username
            Text(user?.username ?? "Unknown User")
                .font(.headline)
                .bold()
            
            // Follow and Report Buttons
            if !isCurrentUser {
                HStack(spacing: 16) {
                    // Follow/Unfollow Button
                    Button(action: {
                        toggleFollowStatus()
                    }) {
                        Text(isFollowing ? "Unfollow" : "Follow")
                            .font(.subheadline)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(isFollowing ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Report Profile Button
                    Button(action: {
                        showReportSheet = true
                    }) {
                        Text("Report")
                            .font(.subheadline)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(hasReported ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(hasReported)
                }
                .padding(.horizontal)
                
                // Reported Confirmation
                if hasReported {
                    Text("You have already reported this profile.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Profile Stats View
    private var profileStats: some View {
        HStack(spacing: 50) {
            statView(number: posts.count, label: "Photos")
            statView(number: followerCount, label: "Followers")
            statView(number: followingCount, label: "Following")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private func statView(number: Int, label: String) -> some View {
        VStack {
            Text("\(number)")
                .font(.headline)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Fetch User Profile
    private func fetchUserProfile() {
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                let fetchedUser = AppUser(id: userId, data: userData)
                self.user = fetchedUser
            }
        }
    }
    
    // MARK: - Fetch User Posts
    private func fetchUserPosts() {
        let ref = Database.database().reference().child("posts")
        ref.queryOrdered(byChild: "userId").queryEqual(toValue: userId).observe(.value) { snapshot in
            var fetchedPosts: [AppPost] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let postData = childSnapshot.value as? [String: Any] {
                    let post = AppPost(id: childSnapshot.key, data: postData)
                    fetchedPosts.append(post)
                }
            }
            self.posts = fetchedPosts
        }
    }
    
    // MARK: - Fetch Follower Count
    private func fetchFollowerCount() {
        let ref = Database.database().reference().child("followers").child(userId)
        ref.observe(.value) { snapshot in
            if let followersDict = snapshot.value as? [String: Any] {
                self.followerCount = followersDict.count
            } else {
                self.followerCount = 0
            }
        }
    }
    
    // MARK: - Fetch Following Count
    private func fetchFollowingCount() {
        let ref = Database.database().reference().child("following").child(userId)
        ref.observe(.value) { snapshot in
            if let followingDict = snapshot.value as? [String: Any] {
                self.followingCount = followingDict.count
            } else {
                self.followingCount = 0
            }
        }
    }
    
    // MARK: - Check If Current User
    private func checkIfCurrentUser() {
        if let currentUserId = Auth.auth().currentUser?.uid {
            self.isCurrentUser = (currentUserId == userId)
        } else {
            self.isCurrentUser = false
        }
    }
    
    // MARK: - Check If Following
    private func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("followers").child(userId).child(currentUserId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let isFollowing = snapshot.value as? Bool {
                self.isFollowing = isFollowing
            }
        }
    }
    
    // MARK: - Toggle Follow Status
    private func toggleFollowStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let followersRef = Database.database().reference().child("followers").child(userId).child(currentUserId)
        let followingRef = Database.database().reference().child("following").child(currentUserId).child(userId)
        
        if isFollowing {
            // Unfollow user
            followersRef.setValue(nil)
            followingRef.setValue(nil)
            followerCount = max(followerCount - 1, 0)
        } else {
            // Follow user
            followersRef.setValue(true)
            followingRef.setValue(true)
            followerCount += 1
        }
        
        isFollowing.toggle()
    }
    
    // MARK: - Check If Already Reported
    private func checkIfReported() {
        guard let reporterId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("reported_profiles")
        ref.queryOrdered(byChild: "reportedProfileId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any],
                   let reportedBy = reportData["reportedBy"] as? String,
                   reportedBy == reporterId {
                    self.hasReported = true
                    return
                }
            }
            self.hasReported = false
        }
    }
    
    // MARK: - Check If Already Reported Helper
    private func checkIfAlreadyReported(completion: @escaping (Bool) -> Void) {
        guard let reporterId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let ref = Database.database().reference().child("reported_profiles")
        ref.queryOrdered(byChild: "reportedProfileId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any],
                   let reportedBy = reportData["reportedBy"] as? String,
                   reportedBy == reporterId {
                    self.hasReported = true
                    completion(true)
                    return
                }
            }
            self.hasReported = false
            completion(false)
        }
    }
}

// MARK: - PostDetailView Implementation Example

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(userId: "example_user_id")
    }
}
