import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct ReportedUsersView: View {
    @State private var reportedUsers: [AllReportedUser] = []
    @State private var showDeleteDialog: Bool = false
    @State private var showSuspendDialog: Bool = false
    @State private var selectedUser: AllReportedUser? = nil
    
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
                        
                        // Delete Button
                        Button(action: {
                            selectedUser = user
                            showDeleteDialog = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding(.trailing, 10)
                        
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
        .onAppear(perform: fetchReportedUsers)
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
    
    private func fetchReportedUsers() {
        databaseRef.child("reports").observeSingleEvent(of: .value) { snapshot in
            var reportedUserIds: Set<String> = []
            
            // Iterate through reports to gather all unique reported user IDs
            for report in snapshot.children {
                if let reportSnapshot = report as? DataSnapshot {
                    for child in reportSnapshot.children {
                        if let userSnapshot = child as? DataSnapshot {
                            reportedUserIds.insert(userSnapshot.key)
                        }
                    }
                }
            }
            
            // Fetch user data for each reported user
            fetchUserData(for: Array(reportedUserIds))
        }
    }
    
    private func fetchUserData(for userIds: [String]) {
        var loadedUsers: [AllReportedUser] = []
        
        let userGroup = DispatchGroup() // To manage asynchronous fetch completion
        
        for userId in userIds {
            userGroup.enter()
            databaseRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
                if let userData = snapshot.value as? [String: Any],
                   let username = userData["username"] as? String,
                   let email = userData["email"] as? String,
                   let role = userData["role"] as? String {
                    
                    let user = AllReportedUser(id: userId, username: username, email: email, role: role)
                    loadedUsers.append(user)
                }
                userGroup.leave()
            }
        }
        
        userGroup.notify(queue: .main) {
            // Sort suspended users to the top and update the state
            self.reportedUsers = loadedUsers.sorted { $0.role == "suspended" && $1.role != "suspended" }
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
