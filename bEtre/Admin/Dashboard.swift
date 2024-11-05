import SwiftUI
import FirebaseDatabase
import Charts
import FirebaseAuth

struct Violation: Identifiable {
    let id: String
    let reason: String
    let timestamp: TimeInterval
    let userId: String
    var username: String
}

struct SuspendedUsersPieChart: View {
    @State private var suspendedCount: Int = 0
    @State private var activeCount: Int = 0
    private let databaseRef = Database.database().reference()
    
    var body: some View {
        VStack {
            Text("User Suspension Status")
                .font(.headline)
                .padding(.bottom, 20)
            
            ZStack {
                // Suspended Users Segment
                Circle()
                    .trim(from: 0, to: CGFloat(suspendedPercentage / 100))
                    .stroke(Color.red, lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                
                // Active Users Segment
                Circle()
                    .trim(from: CGFloat(suspendedPercentage / 100), to: 1)
                    .stroke(Color.green, lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                
                
            }
            .frame(width: 150, height: 150)
            
            HStack {
                Label("Suspended", systemImage: "circle.fill")
                    .foregroundColor(.red)
                Text(String(format: "%.2f%%", suspendedPercentage))
                
                Label("Active", systemImage: "circle.fill")
                    .foregroundColor(.green)
                Text(String(format: "%.2f%%", activePercentage))
            }
            .font(.subheadline)
            .padding(.top, 10)
        }
        .onAppear {
            fetchUserSuspensionData()
        }
    }
    
    private var suspendedPercentage: Double {
        let total = suspendedCount + activeCount
        return total > 0 ? (Double(suspendedCount) / Double(total)) * 100 : 0
    }
    
    private var activePercentage: Double {
        100 - suspendedPercentage
    }
    
    private func fetchUserSuspensionData() {
        databaseRef.child("users").observeSingleEvent(of: .value) { snapshot in
            var suspended = 0
            var active = 0
            
            for child in snapshot.children {
                if let userSnapshot = child as? DataSnapshot,
                   let userData = userSnapshot.value as? [String: Any] {
                    
                    let role = userData["role"] as? String ?? ""
                    let isSuspended = userData["suspended"] as? Bool ?? false
                    
                    if role == "suspended" || isSuspended {
                        suspended += 1
                    } else {
                        active += 1
                    }
                }
            }
            
            self.suspendedCount = suspended
            self.activeCount = active
        }
    }
}


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

struct ReportDataPoint: Identifiable {
    let id = UUID()
    let date: String  // Formatted date string
    let count: Int
    let type: ReportType
}

enum ReportType: String {
    case comments = "Comments reported"
    case posts = "Posts reported"
    case profiles = "Profiles reported"
}

struct ReportsBarChart: View {
    var data: [ReportDataPoint]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Reported Data")
                .font(.subheadline)
                .padding(.bottom, 5)
            
            Chart {
                ForEach(data) { dataPoint in
                    BarMark(
                        x: .value("Type", dataPoint.type.rawValue),
                        y: .value("Count", dataPoint.count)
                    )
                    .foregroundStyle(by: .value("Type", dataPoint.type.rawValue))
                    .symbol(by: .value("Type", dataPoint.type.rawValue))
                }
            }
            .frame(height: 300)
            .padding()
        }
        .padding(.leading, 20)
        .padding(.top, 20)
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
    @State private var reportedComments: [CommentDisplayData] = []
    
    @State private var reportDataPoints: [ReportDataPoint] = []
    private let databaseRef = Database.database().reference()
    
    @State private var violations: [Violation] = []
    
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
                    
                    ReportsBarChart(data: reportDataPoints)
                        .onAppear {
                            fetchReportData()
                        }
                    SuspendedUsersPieChart()
                        .padding(.top, 20)

                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Violation History")
                            .font(.headline)
                            .padding(.top)
                        
                        if violations.isEmpty {
                            Text("No recent violations")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(violations) { violation in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Username: \(violation.username)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Reason: \(violation.reason)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text("Date: \(Date(timeIntervalSince1970: violation.timestamp), formatter: dateFormatter)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onAppear(perform: fetchViolations)
                    
                    Spacer()
                    
                    
                }
            }
            .navigationDestination(for: String.self) { userId in
                AdminEditUser(userId: userId)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private func fetchViolations() {
        databaseRef.child("warnings").observeSingleEvent(of: .value) { snapshot in
            var loadedViolations: [Violation] = []
            let dispatchGroup = DispatchGroup() // Use DispatchGroup to wait for all username fetches to complete

            for userSnapshot in snapshot.children {
                if let userSnapshot = userSnapshot as? DataSnapshot {
                    for warningSnapshot in userSnapshot.children {
                        if let warningData = warningSnapshot as? DataSnapshot,
                           let data = warningData.value as? [String: Any],
                           let reason = data["reason"] as? String,
                           let timestamp = data["timestamp"] as? TimeInterval,
                           let userId = data["userId"] as? String {
                               
                            // Start fetching username for this userId
                            dispatchGroup.enter()
                            fetchUsername(for: userId) { username in
                                let violation = Violation(
                                    id: warningData.key,
                                    reason: reason,
                                    timestamp: timestamp,
                                    userId: userId,
                                    username: username // Assign fetched username
                                )
                                loadedViolations.append(violation)
                                dispatchGroup.leave()
                            }
                        }
                    }
                }
            }

            // Once all usernames are fetched, update the violations list on the main thread
            dispatchGroup.notify(queue: .main) {
                self.violations = loadedViolations.sorted(by: { $0.timestamp > $1.timestamp })
            }
        }
    }
    
    private func fetchUsername(for userId: String, completion: @escaping (String) -> Void) {
        let userRef = databaseRef.child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { snapshot in
            let username = (snapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
            completion(username)
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
    
    private func fetchReportData() {
        // Clear previous data points
        self.reportDataPoints = []
        
        // Fetch data for each report type
        fetchReportComments()
        fetchReportPosts()
        fetchReportProfiles()
    }
    
    private func fetchReportComments() {
        databaseRef.child("report_comments").observe(.value) { snapshot in
            var commentReportsByDate: [String: Int] = [:]
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any],
                   let timestamp = reportData["timestamp"] as? Double {
                    
                    let dateString = formattedDate(from: timestamp)
                    commentReportsByDate[dateString, default: 0] += 1
                }
            }
            
            // Convert to data points
            for (date, count) in commentReportsByDate {
                self.reportDataPoints.append(ReportDataPoint(date: date, count: count, type: .comments))
            }
        }
    }
    
    private func fetchReportPosts() {
        databaseRef.child("reports").observe(.value) { snapshot in
            var postReportsByDate: [String: Int] = [:]
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any],
                   let timestamp = reportData["timestamp"] as? Double {
                    
                    let dateString = formattedDate(from: timestamp)
                    postReportsByDate[dateString, default: 0] += 1
                }
            }
            
            // Convert to data points
            for (date, count) in postReportsByDate {
                self.reportDataPoints.append(ReportDataPoint(date: date, count: count, type: .posts))
            }
        }
    }
    
    
    private func fetchReportProfiles() {
        databaseRef.child("reported_profiles").observe(.value) { snapshot in
            var profileReportsByDate: [String: Int] = [:]
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any],
                   let timestamp = reportData["timestamp"] as? Double {
                    
                    let dateString = formattedDate(from: timestamp)
                    profileReportsByDate[dateString, default: 0] += 1
                }
            }
            
            // Convert to data points
            for (date, count) in profileReportsByDate {
                self.reportDataPoints.append(ReportDataPoint(date: date, count: count, type: .profiles))
            }
        }
    }
    
    // Helper function to format timestamp to date string
    private func formattedDate(from timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)  // Convert milliseconds to seconds
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"  // Example date format
        return dateFormatter.string(from: date)
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
                if let postSnapshot = postSnapshot as? DataSnapshot {
                    let usersSnapshot = postSnapshot.childSnapshot(forPath: "users")
                    likesCount += Int(usersSnapshot.childrenCount)
                }
            }
            self.totalLikes = likesCount
        }
    }
    
    
    private func fetchTotalComments() {
        databaseRef.child("comments").observeSingleEvent(of: .value) { snapshot in
            self.totalComments = Int(snapshot.childrenCount)
        }
    }
    
    private func fetchTotalReportedUsers() {
        var uniqueReportedUserIds = Set<String>()
        let dispatchGroup = DispatchGroup()
        
        // Fetch reported users from "reports" node (for reported posts)
        databaseRef.child("reports").observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let reportSnapshot = child as? DataSnapshot,
                   let reportData = reportSnapshot.value as? [String: Any],
                   let reportedUserId = reportData["reportedBy"] as? String {
                    uniqueReportedUserIds.insert(reportedUserId)
                }
            }
            
            // Fetch reported users from "report_comments" node (for reported comments)
            self.databaseRef.child("report_comments").observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let reportSnapshot = child as? DataSnapshot,
                       let reportData = reportSnapshot.value as? [String: Any],
                       let reportedUserId = reportData["reportedCommentUserId"] as? String {
                        uniqueReportedUserIds.insert(reportedUserId)
                    }
                }
                
                // Fetch reported users from "reported_profiles" node
                self.databaseRef.child("reported_profiles").observeSingleEvent(of: .value) { snapshot in
                    for child in snapshot.children {
                        if let reportProfile = child as? DataSnapshot,
                           let reportData = reportProfile.value as? [String: Any],
                           let reportedUserId = reportData["reportedUserId"] as? String {
                            uniqueReportedUserIds.insert(reportedUserId)
                        }
                    }
                    
                    // Validate existence of each unique user ID in the "users" node
                    var validReportedUserCount = 0
                    for userId in uniqueReportedUserIds {
                        dispatchGroup.enter()
                        self.databaseRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
                            // Log the current user ID being checked for debugging
                            print("Checking userId: \(userId)")
                            if snapshot.exists() {
                                print("User exists: \(userId)")
                                validReportedUserCount += 1
                            } else {
                                print("User does not exist: \(userId)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    // Update totalReportedUsers after all checks are complete
                    dispatchGroup.notify(queue: .main) {
                        self.totalReportedUsers = validReportedUserCount
                        print("Total valid reported users: \(self.totalReportedUsers)")
                    }
                }
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
    
    private func fetchReportedComments() {
        databaseRef.child("report_comments").observeSingleEvent(of: .value) { snapshot in
            var commentsList: [CommentDisplayData] = []
            let dispatchGroup = DispatchGroup()
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any] {
                    
                    let commentId = reportData["commentId"] as? String ?? "Missing commentId"
                    let postId = reportData["postId"] as? String ?? "Missing postId"
                    let content = reportData["content"] as? String ?? "Missing content"
                    let reportedById = reportData["reportedBy"] as? String ?? "Missing reportedBy"
                    let reportedCommentUserId = reportData["reportedCommentUserId"] as? String ?? "Missing reportedCommentUserId"
                    let reason = reportData["reason"] as? String ?? "Missing reason"
                    
                    print("Debug Reported Comment - ID: \(commentId), Post ID: \(postId), Content: \(content), Reason: \(reason)")
                    
                    // Continue with fetching usernames, assuming all fields exist
                    dispatchGroup.enter()
                    
                    fetchUsernames(commenterId: reportedCommentUserId, postOwnerId: reportedById) { commenterName, postOwnerName in
                        let comment = CommentDisplayData(
                            id: commentId,
                            commenterName: commenterName,
                            content: content,
                            postOwnerName: postOwnerName,
                            reason: reason
                        )
                        commentsList.append(comment)
                        dispatchGroup.leave()
                    }
                }
            }
            
            // Update reportedComments only after all usernames are fetched
            dispatchGroup.notify(queue: .main) {
                self.reportedComments = commentsList
                print("Total reported comments fetched: \(self.reportedComments.count)")
            }
        }
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
    var reason: String = ""
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
