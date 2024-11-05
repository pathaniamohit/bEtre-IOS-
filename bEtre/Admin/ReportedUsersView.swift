import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct ReportedUsersView: View {
    @State private var reportedUsers: [AllReportedUser] = []
    @State private var showDeleteDialog: Bool = false
    @State private var showSuspendDialog: Bool = false
    @State private var selectedUser: AllReportedUser? = nil
    @State private var isAdmin: Bool = false // Track if current user is admin
    
    private let databaseRef = Database.database().reference()
    
    var body: some View {
        VStack {
            Text("Reported Users")
                .font(.largeTitle)
                .padding()
            
            List {
                ForEach(reportedUsers) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Conditionally display Delete Button if the current user is an admin
                        if isAdmin {
                            Button(action: {
                                selectedUser = user
                                showDeleteDialog = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.trailing, 10)
                        }
                        // Suspend/Unsuspend Button
                        Button(action: {
                            selectedUser = user
                            showSuspendDialog = true
                        }) {
                            Image(systemName: user.role == "suspended" ? "lock.open" : "lock")
                                .foregroundColor(user.role == "suspended" ? .green : .orange)
                        }
                    }
                    .padding()
                    .background(user.role == "suspended" ? Color.gray.opacity(0.2) : Color.white)
                    .cornerRadius(8)
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            checkIfAdmin() 
            fetchReportedUsers()
        }
        .alert(isPresented: $showDeleteDialog) {
            Alert(
                title: Text("Delete User"),
                message: Text("Are you sure you want to delete this user?"),
                primaryButton: .destructive(Text("Delete"), action: deleteUser),
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showSuspendDialog) {
            Alert(
                title: Text("Suspend/Unsuspend User"),
                message: Text("Do you want to suspend/unsuspend this user?"),
                primaryButton: .default(Text("Confirm"), action: toggleSuspendUser),
                secondaryButton: .cancel()
            )
        }
    }
    
    private func checkIfAdmin() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        databaseRef.child("users").child(currentUserId).child("role").observeSingleEvent(of: .value) { snapshot in
            if let role = snapshot.value as? String, role == "admin" {
                self.isAdmin = true // Set to true if current user is an admin
            }
        }
    }
    
    private func fetchReportedUsers() {
            fetchFromReports { reportedUserIds in
                fetchFromReportComments(existingUserIds: reportedUserIds) { updatedUserIds in
                    fetchFromReportedProfiles(existingUserIds: updatedUserIds) { finalUserIds in
                        print("Unique user IDs before fetching user data: \(finalUserIds)")
                        fetchUserData(for: Array(finalUserIds))
                    }
                }
            }
        }
        
        private func fetchFromReports(completion: @escaping (Set<String>) -> Void) {
            var reportedUserIds = Set<String>()
            
            databaseRef.child("reports").observeSingleEvent(of: .value) { snapshot in
                for report in snapshot.children {
                    if let reportSnapshot = report as? DataSnapshot,
                       let reportData = reportSnapshot.value as? [String: Any],
                       let reportedUserId = reportData["reportedBy"] as? String {
                        reportedUserIds.insert(reportedUserId)
                    }
                }
                print("User IDs from reports node: \(reportedUserIds)")
                completion(reportedUserIds)
            }
        }
        
        private func fetchFromReportComments(existingUserIds: Set<String>, completion: @escaping (Set<String>) -> Void) {
            var reportedUserIds = existingUserIds
            
            databaseRef.child("report_comments").observeSingleEvent(of: .value) { snapshot in
                for reportComment in snapshot.children {
                    if let reportData = (reportComment as? DataSnapshot)?.value as? [String: Any],
                       let reportedUserId = reportData["reportedCommentUserId"] as? String {
                        reportedUserIds.insert(reportedUserId)
                    }
                }
                print("User IDs after adding from report_comments node: \(reportedUserIds)")
                completion(reportedUserIds)
            }
        }
        
        private func fetchFromReportedProfiles(existingUserIds: Set<String>, completion: @escaping (Set<String>) -> Void) {
            var reportedUserIds = existingUserIds
            
            databaseRef.child("reported_profiles").observeSingleEvent(of: .value) { snapshot in
                for reportProfile in snapshot.children {
                    if let reportData = (reportProfile as? DataSnapshot)?.value as? [String: Any],
                       let reportedUserId = reportData["reportedUserId"] as? String {
                        reportedUserIds.insert(reportedUserId)
                    }
                }
                print("Final user IDs after adding from reported_profiles node: \(reportedUserIds)")
                completion(reportedUserIds)
            }
        }
        
        private func fetchUserData(for userIds: [String]) {
            var loadedUsers: [AllReportedUser] = []
            let userGroup = DispatchGroup()
            
            for userId in userIds {
                userGroup.enter()
                databaseRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
                    print("Fetching data for userId: \(userId)")
                    if let userData = snapshot.value as? [String: Any],
                       let username = userData["username"] as? String,
                       let email = userData["email"] as? String,
                       let role = userData["role"] as? String {
                        let user = AllReportedUser(id: userId, username: username, email: email, role: role)
                        loadedUsers.append(user)
                    } else {
                        print("User does not exist in 'users' node: \(userId)")
                    }
                    userGroup.leave()
                }
            }
            
            userGroup.notify(queue: .main) {
                self.reportedUsers = loadedUsers.sorted { $0.role == "suspended" && $1.role != "suspended" }
                print("Total valid reported users displayed: \(self.reportedUsers.count)")
            }
        }
    
    private func deleteUser() {
        guard let user = selectedUser else { return }
        
        databaseRef.child("users").child(user.id).removeValue { error, _ in
            if error == nil {
                fetchReportedUsers() // Refresh user list
            }
        }
    }
    
    private func toggleSuspendUser() {
        guard let user = selectedUser else { return }
        
        let newRole = user.role == "suspended" ? "user" : "suspended"
        databaseRef.child("users").child(user.id).child("role").setValue(newRole) { error, _ in
            if error == nil {
                fetchReportedUsers() // Refresh user list
            }
        }
    }
}

struct AllReportedUser: Identifiable {
    var id: String
    var username: String
    var email: String
    var role: String
}
