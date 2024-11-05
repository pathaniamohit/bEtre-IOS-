import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct InboxAdminView: View {
    @State private var reports: [ReportData] = []
    @State private var navigationPath = NavigationPath()
    private let databaseRef = Database.database().reference()
    @State private var adminUserId: String? = nil

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Reports Inbox")
                    .font(.custom("RobotoSerif-Bold", size: 28))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                List(reports, id: \.id) { report in
                    ReportRowView(report: report, navigationPath: $navigationPath, adminUserId: adminUserId, onRemoveReport: removeReport)
                }
                .listStyle(PlainListStyle())
            }
            .onAppear {
                fetchAdminUserId()
                observeReports()
            }
            .navigationDestination(for: String.self) { postOwnerId in
                UserProfileView(userId: postOwnerId)
            }
        }
    }
    
    private func fetchAdminUserId() {
        if let currentUser = Auth.auth().currentUser {
            adminUserId = currentUser.uid
        } else {
            print("Error: Admin not logged in")
        }
    }
    
    private func observeReports() {
        databaseRef.child("reports").observe(.value) { snapshot in
            var newReports: [ReportData] = []
            
            for postSnapshot in snapshot.children {
                if let postSnapshot = postSnapshot as? DataSnapshot {
                    let postId = postSnapshot.key
                    
                    for reportSnapshot in postSnapshot.children {
                        if let reportSnapshot = reportSnapshot as? DataSnapshot,
                           let content = reportSnapshot.value as? String {
                            let reporterId = reportSnapshot.key
                            
                            fetchUsernames(postId: postId, reporterId: reporterId) { postOwnerName, reporterName, postOwnerId, warningCount in
                                let report = ReportData(
                                    id: "\(postId)-\(reporterId)",
                                    postId: postId,
                                    content: content,
                                    postOwnerId: postOwnerId,
                                    postOwnerName: postOwnerName,
                                    reporterName: reporterName,
                                    warningCount: warningCount
                                )
                                newReports.append(report)
                                self.reports = newReports
                            }
                        }
                    }
                }
            }
        }
    }

    private func fetchUsernames(postId: String, reporterId: String, completion: @escaping (String, String, String, Int) -> Void) {
        databaseRef.child("posts").child(postId).observeSingleEvent(of: .value) { snapshot in
            let postOwnerId = (snapshot.value as? [String: Any])?["userId"] as? String ?? "Unknown User"
            let userRef = databaseRef.child("users")
            
            userRef.child(postOwnerId).observeSingleEvent(of: .value) { ownerSnapshot in
                let postOwnerName = (ownerSnapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
                let warningCount = (ownerSnapshot.value as? [String: Any])?["count_warning"] as? Int ?? 0
                
                userRef.child(reporterId).observeSingleEvent(of: .value) { reporterSnapshot in
                    let reporterName = (reporterSnapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
                    completion(postOwnerName, reporterName, postOwnerId, warningCount)
                }
            }
        }
    }
    
    private func removeReport(reportId: String) {
        self.reports.removeAll { $0.id == reportId }
        
        // Delete report entry from Firebase
        let ids = reportId.split(separator: "-")
        if ids.count == 2 {
            let postId = String(ids[0])
            let reporterId = String(ids[1])
            databaseRef.child("reports").child(postId).child(reporterId).removeValue { error, _ in
                if let error = error {
                    print("Error deleting report: \(error)")
                } else {
                    print("Report \(reportId) successfully removed.")
                }
            }
        }
    }
}

// Data model for each report
struct ReportData: Identifiable {
    var id: String
    var postId: String
    var content: String
    var postOwnerId: String
    var postOwnerName: String
    var reporterName: String
    var warningCount: Int
}

// Custom view for each report row with warning dialog
struct ReportRowView: View {
    var report: ReportData
    @Binding var navigationPath: NavigationPath
    @State private var showOptions = false
    @State private var showWarningDialog = false
    @State private var warningMessage = ""
    var adminUserId: String?
    var onRemoveReport: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Post Owner: \(report.postOwnerName)")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Reporter: \(report.reporterName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Content: \(report.content)")
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 10)
            
            HStack {
                Spacer()
                Menu {
                    Button("See Profile") {
                        navigationPath.append(report.postOwnerId)
                    }
                    Button("See Post") { /* Handle view post */ }
                    Button("Suspend User") {
                        suspendUser(userId: report.postOwnerId)// Remove report after suspension
                    }
                    Button("Give Warning", action: { showWarningDialog = true })
                        .disabled(report.warningCount >= 2)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(.trailing, 10)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(getBorderColor(for: report.warningCount), lineWidth: 2)
        )
        .sheet(isPresented: $showWarningDialog) {
            WarningDialog(
                warningMessage: $warningMessage,
                onSend: {
                    giveWarning(message: warningMessage)
                    onRemoveReport(report.id) // Remove report after sending a warning
                    showWarningDialog = false
                }
            )
        }
    }
    
    private func getBorderColor(for warningCount: Int) -> Color {
        switch warningCount {
        case 2:
            return .red
        case 1:
            return .orange
        default:
            return .yellow
        }
    }
    
    private func suspendUser(userId: String) {
        let userRef = Database.database().reference().child("users").child(userId)
        userRef.updateChildValues(["role": "suspended"]) { error, _ in
            if let error = error {
                print("Error suspending user: \(error)")
            } else {
                print("User \(userId) suspended.")
            }
        }
    }
    
    private func giveWarning(message: String) {
        guard let adminId = adminUserId else {
            print("Error: Admin ID is missing.")
            return
        }
        
        let userRef = Database.database().reference().child("users").child(report.postOwnerId)
        
        // Increment the warning count
        userRef.runTransactionBlock { currentData in
            var user = currentData.value as? [String: Any] ?? [:]
            let currentWarningCount = user["count_warning"] as? Int ?? 0
            user["count_warning"] = currentWarningCount + 1
            currentData.value = user
            return .success(withValue: currentData)
        }
        
        // Save the warning message in notifications
        let notificationRef = Database.database().reference().child("notifications").child(report.postOwnerId).childByAutoId()
        notificationRef.setValue([
            "postId": report.postId,
            "userId": adminId,
            "type": "report",
            "timestamp": Date().timeIntervalSince1970,
            "content": message
        ])
    }
}
// Warning Dialog View
struct WarningDialog: View {
    @Binding var warningMessage: String
    var onSend: () -> Void
    
    @State private var isGuideline1Checked = false
    @State private var isGuideline2Checked = false
    @State private var isGuideline3Checked = false
    
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Send Warning")
                .font(.headline)
            
            
                Text("Guidelines : ")
                    .font(.headline)
                    .font(.system(size: 18))
                
                VStack(alignment: .leading) {
                    Toggle("Respect community standards", isOn: $isGuideline1Checked)
                        .toggleStyle(CheckboxToggleStyle())
                    
                    Toggle("Avoid offensive language", isOn: $isGuideline2Checked)
                        .toggleStyle(CheckboxToggleStyle())
                    
                    Toggle("No spam or irrelevant content", isOn: $isGuideline3Checked)
                        .toggleStyle(CheckboxToggleStyle())
                }
                .padding()
                
                TextField("Enter warning message", text: $warningMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                HStack {
                    Button("Cancel") {
                        warningMessage = ""
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Send") {
                        if isGuideline1Checked {
                            warningMessage += "\n- Respect community standards"
                        }
                        if isGuideline2Checked {
                            warningMessage += "\n- Avoid offensive language"
                        }
                        if isGuideline3Checked {
                            warningMessage += "\n- No spam or irrelevant content"
                        }
                        onSend()
                    }
                   .disabled(warningMessage.isEmpty)
                }
                .padding()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
        }
    }
struct CheckboxToggleStyle: ToggleStyle {
       func makeBody(configuration: Configuration) -> some View {
           Button(action: {
               configuration.isOn.toggle()
           }) {
               HStack {
                   Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                       .foregroundColor(configuration.isOn ? .blue : .gray)
                   configuration.label
               }
           }
           .buttonStyle(PlainButtonStyle())
       }
   }

// Preview structure for testing
struct InboxAdminView_Previews: PreviewProvider {
    static var previews: some View {
        InboxAdminView()
    }
}
