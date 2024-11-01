import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct AllUsersView: View {
    @State private var users: [AllUser] = []
    @State private var showDeleteDialog: Bool = false
    @State private var showSuspendDialog: Bool = false
    @State private var selectedUser: AllUser? = nil
    @State private var isAdmin: Bool = false // Track if current user is admin
    
    private let databaseRef = Database.database().reference()
    
    var body: some View {
        VStack {
            Text("All Registered Users")
                .font(.largeTitle)
                .padding()
            
            List {
                ForEach(users) { user in
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
            fetchUsers()
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
    
    private func fetchUsers() {
        databaseRef.child("users").observe(.value) { snapshot in
            var loadedUsers: [AllUser] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let userData = snapshot.value as? [String: Any],
                   let username = userData["username"] as? String,
                   let email = userData["email"] as? String,
                   let role = userData["role"] as? String {
                    
                    let user = AllUser(id: snapshot.key, username: username, email: email, role: role)
                    loadedUsers.append(user)
                }
            }
            
            // Sort users: Suspended users at the top
            self.users = loadedUsers.sorted { $0.role == "suspended" && $1.role != "suspended" }
        }
    }
    
    private func deleteUser() {
        guard let user = selectedUser else { return }
        
        databaseRef.child("users").child(user.id).removeValue { error, _ in
            if error == nil {
                fetchUsers() // Refresh user list
            }
        }
    }
    
    private func toggleSuspendUser() {
        guard let user = selectedUser else { return }
        
        let newRole = user.role == "suspended" ? "user" : "suspended"
        databaseRef.child("users").child(user.id).child("role").setValue(newRole) { error, _ in
            if error == nil {
                fetchUsers() // Refresh user list
            }
        }
    }
}

struct AllUser: Identifiable {
    var id: String
    var username: String
    var email: String
    var role: String
}

