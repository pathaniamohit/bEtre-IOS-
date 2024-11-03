import SwiftUI
import FirebaseDatabase
import Charts
import FirebaseAuth

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: String
    let count: Int
}

struct TrendChart: View {
    var data: [TrendDataPoint]
    var title: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .padding(.bottom, 5)
            
            Chart(data) {
                LineMark(
                    x: .value("Date", $0.date),
                    y: .value("Count", $0.count)
                )
            }
            .frame(height: 150)
        }
    }
}

struct DashboardView: View {
    @State private var totalUsers: Int = 0
    @State private var totalReports: Int = 0
    @State private var totalReportedUsers: Int = 0
    @State private var totalModerators: Int = 0
    @State private var malePercentage: Double = 0
    @State private var femalePercentage: Double = 0
    @State private var locationData: [LocationData] = []
    @State private var commentsDisplayData: [CommentDisplayData] = []
    @State private var searchText: String = ""
    @State private var suggestions: [AdminUser] = []
    @State private var showSuggestions: Bool = false
    @State private var selectedUserId: String?
    @State private var navigationPath = NavigationPath()
    @State private var isAdmin = false
    @State private var totalPosts: Int = 0
    @State private var totalLikes: Int = 0
    @State private var totalComments: Int = 0

    
    private let databaseRef = Database.database().reference()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Dashboard")
                        .font(.custom("RobotoSerif-Bold", size: 28))
                        .foregroundColor(.black)
                        .padding(.top, 10)
                    
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            // Search Bar
                            HStack {
                                TextField("Search", text: $searchText, onEditingChanged: { isEditing in
                                    self.showSuggestions = !searchText.isEmpty
                                }, onCommit: {
                                    searchUsers()
                                })
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: searchText, perform: { text in
                                    self.showSuggestions = !text.isEmpty
                                    if text.isEmpty {
                                        self.suggestions = []
                                    } else {
                                        searchUsers()
                                    }
                                })
                                
                                Button(action: {
                                    searchUsers()
                                }) {
                                    Text("Search")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .padding([.leading, .trailing], 20)
                            
                            // Stats Cards
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    NavigationLink(destination: AllUsersView()) {
                                        StatsCard(title: "Total Users", value: totalUsers, color: .blue)
                                    }
                                    NavigationLink(destination: ReportedUsersView()) {
                                        StatsCard(title: "Reported Users", value: totalReportedUsers, color: .orange)
                                    }
                                    if isAdmin {
                                        NavigationLink(destination: ViewModerator()) {
                                            StatsCard(title: "Moderators", value: totalModerators, color: .purple)
                                        }
                                    }
                                    // New Analytics Cards
                                            StatsCard(title: "Total Posts", value: totalPosts, color: .blue)
                                            StatsCard(title: "Total Likes", value: totalLikes, color: .green)
                                            StatsCard(title: "Total Comments", value: totalComments, color: .orange)
                                            
                                }
                                .padding(.bottom, 20)
                                
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .onAppear {
                                checkAdminStatus()
                                fetchTotalUsers()
                                fetchTotalReports()
                                fetchTotalReportedUsers()
                                fetchTotalModerators()
                                fetchGenderData()
                                fetchLocationData()
                                fetchCommentsData()
                                fetchTotalPosts()
                                fetchTotalLikes()
                                fetchTotalComments()
                            }
                        }
                        
                        // Suggestions list, overlapping below the search bar
                        if showSuggestions && !suggestions.isEmpty {
                            VStack {
                                Spacer().frame(height: 60)
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(suggestions) { user in
                                            Button(action: {
                                                navigateToUserProfile(user: user)
                                            }) {
                                                HStack {
                                                    Text(user.username)
                                                        .padding()
                                                    Spacer()
                                                }
                                                .background(Color.white)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .padding(.horizontal, 28)
                                    .shadow(radius: 5)
                                }
                                .frame(maxHeight: 200)
                                .padding(.bottom)
                            }
                            .background(Color.white.opacity(0.01))
                            .onTapGesture {
                                showSuggestions = false
                            }
                        }
                    }
                    .zIndex(1)
                    
                    // Gender Distribution Chart
                    GenderPieChart(malePercentage: malePercentage, femalePercentage: femalePercentage)
                        .padding(.top, 20)
                    
                    // Horizontal Scrollable Location Distribution Chart
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            BarChart(title: "Posts by Location", data: locationData, barColor: .orange)
                                .frame(width: CGFloat(locationData.count * 80))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Comments")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        ForEach(commentsDisplayData, id: \.id) { commentData in
                            CommentAdminView(commentData: commentData)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationDestination(for: String.self) { userId in
                AdminEditUser(userId: userId)
            }
        }
    }
    
    private func fetchTotalUsers() {
        databaseRef.child("users").observeSingleEvent(of: .value) { snapshot in
            var userCount = 0
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let userData = snapshot.value as? [String: Any],
                   let role = userData["role"] as? String,
                   role != "admin", role != "moderator" { // Exclude admin and moderator roles
                    userCount += 1
                }
            }
            self.totalUsers = userCount
        }
    }

    
    private func fetchTotalReports() {
        databaseRef.child("reports").observeSingleEvent(of: .value) { snapshot in
            self.totalReports = Int(snapshot.childrenCount)
        }
    }
    
    private func fetchTotalPosts() {
        databaseRef.child("posts").observeSingleEvent(of: .value) { snapshot in
            self.totalPosts = Int(snapshot.childrenCount)
        }
    }

    private func fetchTotalLikes() {
        databaseRef.child("likes").observeSingleEvent(of: .value) { snapshot in
            var likesCount = 0
            for postSnapshot in snapshot.children {
                if let post = postSnapshot as? DataSnapshot {
                    likesCount += Int(post.childrenCount)
                }
            }
            self.totalLikes = likesCount
        }
    }

    private func fetchTotalComments() {
        databaseRef.child("comments").observeSingleEvent(of: .value) { snapshot in
            var commentsCount = 0
            for case let postSnapshot as DataSnapshot in snapshot.children {
                commentsCount += Int(postSnapshot.childrenCount)
            }
            self.totalComments = commentsCount
        }
    }


    
    private func fetchTotalReportedUsers() {
        var uniqueReportedUserIds = Set<String>()
        
        // Fetch unique reported users from the "reports" node
        databaseRef.child("reports").observeSingleEvent(of: .value) { snapshot in
            for postSnapshot in snapshot.children {
                if let postSnapshot = postSnapshot as? DataSnapshot {
                    for userSnapshot in postSnapshot.children {
                        if let userSnapshot = userSnapshot as? DataSnapshot {
                            uniqueReportedUserIds.insert(userSnapshot.key)
                        }
                    }
                }
            }
            
            // Fetch reported users from the "comments" node
            databaseRef.child("comments").observeSingleEvent(of: .value) { commentsSnapshot in
                for postSnapshot in commentsSnapshot.children {
                    if let postSnapshot = postSnapshot as? DataSnapshot {
                        for commentSnapshot in postSnapshot.children {
                            if let commentData = (commentSnapshot as? DataSnapshot)?.value as? [String: Any],
                               let reportedUserId = commentData["reportedCommentUserId"] as? String {
                                uniqueReportedUserIds.insert(reportedUserId)
                            }
                        }
                    }
                }
                
                // Confirm each ID in uniqueReportedUserIds with the "users" node
                self.validateUserIds(Array(uniqueReportedUserIds))
            }
        }
    }
    
    private func checkAdminStatus() {
            guard let currentUser = Auth.auth().currentUser else { return }
            databaseRef.child("users").child(currentUser.uid).observeSingleEvent(of: .value) { snapshot in
                if let data = snapshot.value as? [String: Any],
                   let role = data["role"] as? String {
                    isAdmin = (role == "admin")
                }
            }
        }
        
        private func fetchTotalModerators() {
            databaseRef.child("users").observeSingleEvent(of: .value) { snapshot in
                var moderatorCount = 0
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let userData = snapshot.value as? [String: Any],
                       let role = userData["role"] as? String,
                       role == "moderator" {
                        moderatorCount += 1
                    }
                }
                self.totalModerators = moderatorCount
            }
        }
    
    // Helper function to validate user IDs
    private func validateUserIds(_ reportedUserIds: [String]) {
        var validUserIds = Set<String>()
        let userRef = databaseRef.child("users")
        
        let dispatchGroup = DispatchGroup()
        
        for userId in reportedUserIds {
            dispatchGroup.enter()
            userRef.child(userId).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    validUserIds.insert(userId)
                    print("Confirmed valid user ID: \(userId)")
                } else {
                    print("Invalid user ID, not found in 'users' node: \(userId)")
                }
                dispatchGroup.leave()
            }
        }
        
        // Update the count after all checks are completed
        dispatchGroup.notify(queue: .main) {
            self.totalReportedUsers = validUserIds.count
            print("Total valid reported users count: \(self.totalReportedUsers)")
        }
    }
    
    
    private func fetchGenderData() {
        databaseRef.child("users").observeSingleEvent(of: .value) { snapshot in
            var maleCount = 0
            var femaleCount = 0
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let data = childSnapshot.value as? [String: Any],
                   let gender = data["gender"] as? String {
                    if gender.lowercased() == "male" {
                        maleCount += 1
                    } else if gender.lowercased() == "female" {
                        femaleCount += 1
                    }
                }
            }
            let total = maleCount + femaleCount
            self.malePercentage = total > 0 ? (Double(maleCount) / Double(total)) * 100 : 0
            self.femalePercentage = total > 0 ? (Double(femaleCount) / Double(total)) * 100 : 0
        }
    }
    
    private func fetchLocationData() {
        databaseRef.child("posts").observeSingleEvent(of: .value) { snapshot in
            var locationCounts: [String: Int] = [:]
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let data = childSnapshot.value as? [String: Any],
                   let location = data["location"] as? String {
                    
                    locationCounts[location, default: 0] += 1
                }
            }
            
            self.locationData = locationCounts.map { LocationData(location: $0.key, count: $0.value) }
        }
    }
    
    private func fetchCommentsData() {
        databaseRef.child("posts").observeSingleEvent(of: .value) { postsSnapshot in
            var postOwnerMapping: [String: String] = [:]
            var commentsList: [CommentDisplayData] = []
            
            for postChild in postsSnapshot.children {
                if let postSnapshot = postChild as? DataSnapshot,
                   let postData = postSnapshot.value as? [String: Any],
                   let postOwnerId = postData["userId"] as? String {
                    postOwnerMapping[postSnapshot.key] = postOwnerId
                }
            }
            
            databaseRef.child("comments").observeSingleEvent(of: .value) { commentsSnapshot in
                for postCommentChild in commentsSnapshot.children {
                    if let postSnapshot = postCommentChild as? DataSnapshot {
                        let postId = postSnapshot.key
                        guard let postOwnerId = postOwnerMapping[postId] else { continue }
                        
                        for commentChild in postSnapshot.children {
                            if let commentSnapshot = commentChild as? DataSnapshot,
                               let commentData = commentSnapshot.value as? [String: Any],
                               let content = commentData["content"] as? String,
                               let commenterId = commentData["userId"] as? String {
                                
                                fetchUsernames(commenterId: commenterId, postOwnerId: postOwnerId) { commenterName, postOwnerName in
                                    let formattedComment = CommentDisplayData(
                                        id: commentSnapshot.key,
                                        commenterName: commenterName,
                                        content: content,
                                        postOwnerName: postOwnerName
                                    )
                                    commentsList.append(formattedComment)
                                    self.commentsDisplayData = commentsList
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchUsernames(commenterId: String, postOwnerId: String, completion: @escaping (String, String) -> Void) {
        let userRef = databaseRef.child("users")
        
        userRef.child(commenterId).observeSingleEvent(of: .value) { commenterSnapshot in
            let commenterName = (commenterSnapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
            
            userRef.child(postOwnerId).observeSingleEvent(of: .value) { ownerSnapshot in
                let postOwnerName = (ownerSnapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
                completion(commenterName, postOwnerName)
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else {
            self.suggestions = []
            return
        }
        
        databaseRef.child("users").queryOrdered(byChild: "username").queryStarting(atValue: searchText).queryEnding(atValue: searchText + "\u{f8ff}").observeSingleEvent(of: .value) { snapshot in
            var foundUsers: [AdminUser] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let data = childSnapshot.value as? [String: Any],
                   let username = data["username"] as? String {
                    let user = AdminUser(id: childSnapshot.key, username: username)
                    foundUsers.append(user)
                }
            }
            self.suggestions = foundUsers
        }
    }
    
    private func navigateToUserProfile(user: AdminUser) {
        self.suggestions = []
        self.searchText = ""
        self.navigationPath.append(user.id) 
    }
}

// Bar Chart View for Location Data
struct BarChart: View {
    var title: String
    var data: [LocationData]
    var barColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .padding(.bottom, 5)
            
            Chart(data) {
                BarMark(
                    x: .value("Location", $0.location),
                    y: .value("Count", $0.count)
                )
                .foregroundStyle(barColor)
            }
            .frame(height: 150)
        }
    }
}

// Comment View for Displaying Each Comment Nicely
struct CommentAdminView: View {
    var commentData: CommentDisplayData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(commentData.commenterName) commented to \(commentData.postOwnerName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\"\(commentData.content)\"")
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 10)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Model
struct LocationData: Identifiable {
    var id = UUID()
    var location: String
    var count: Int
}

struct CommentDisplayData: Identifiable {
    var id: String
    var commenterName: String
    var content: String
    var postOwnerName: String
}
// Gender Pie Chart View
struct GenderPieChart: View {
    var malePercentage: Double
    var femalePercentage: Double
    
    var body: some View {
        VStack {
            Text("Reached Audience")
                .font(.headline)
                .padding(.bottom, 10)
            
            ZStack {
                Circle()
                    .trim(from: 0, to: CGFloat(malePercentage / 100))
                    .stroke(Color.blue, lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: CGFloat(malePercentage / 100), to: 1)
                    .stroke(Color.green, lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("Total Audience")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(malePercentage + femalePercentage))")
                        .font(.title)
                        .bold()
                }
            }
            .frame(width: 150, height: 150)
            
            HStack {
                Label("Men", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                Text(String(format: "%.2f%%", malePercentage))
                
                Label("Women", systemImage: "circle.fill")
                    .foregroundColor(.green)
                Text(String(format: "%.2f%%", femalePercentage))
            }
            .font(.subheadline)
            .padding(.top, 10)
        }
    }
}

// Reusable Stats Card View
struct StatsCard: View {
    var title: String
    var value: Int
    var color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text("\(value)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(width: 150, height: 100)
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct AdminUser: Identifiable, Hashable {
    var id: String
    var username: String
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
