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
                observeReportedComments()
            }
            .navigationDestination(for: String.self) { userId in
                UserProfileView(userId: userId)
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
    
    private func observeReportedComments() {
        databaseRef.child("report_comments").observe(.value) { snapshot in
            var newReports: [ReportData] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any] {
                    
                    let commentId = childSnapshot.key
                    let postId = reportData["postId"] as? String ?? "Unknown Post"
                    let content = reportData["content"] as? String ?? "No content"
                    let reportedById = reportData["reportedBy"] as? String ?? "Unknown Reporter"
                    let reportedCommentUserId = reportData["reportedCommentUserId"] as? String ?? "Unknown User"
                    let reason = reportData["reason"] as? String ?? "No reason provided"
                    
                    let report = ReportData(
                        id: commentId,
                        postId: postId,
                        content: content,
                        reportedById: reportedById,
                        reportedCommentUserId: reportedCommentUserId,
                        reason: reason
                    )
                    newReports.append(report)
                }
            }
            self.reports = newReports
        }
    }
    
    private func removeReport(reportId: String) {
        databaseRef.child("report_comments").child(reportId).removeValue { error, _ in
            if let error = error {
                print("Error deleting report: \(error)")
            } else {
                print("Report \(reportId) successfully removed.")
                self.reports.removeAll { $0.id == reportId }
            }
        }
    }
}

// Data model for each report
struct ReportData: Identifiable {
    var id: String
    var postId: String
    var content: String
    var reportedById: String
    var reportedCommentUserId: String
    var reason: String
}

// Custom view for each report row with admin options
struct ReportRowView: View {
    var report: ReportData
    @Binding var navigationPath: NavigationPath
    @State private var showWarningDialog = false
    @State private var warningMessage = ""
    private let databaseRef = Database.database().reference()
    var adminUserId: String?
    var onRemoveReport: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Comment Owner: \(report.reportedCommentUserId)")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Reported By: \(report.reportedById)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Content: \(report.content)")
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 10)
            
            Text("Reason: \(report.reason)")
                .font(.footnote)
                .foregroundColor(.red)
                .padding(.top, 5)
            
            HStack {
                Spacer()
                Menu {
                    Button("Suspend User") {
                        suspendUser(userId: report.reportedCommentUserId)
                        onRemoveReport(report.id)
                    }
                    Button("Give Warning", action: { showWarningDialog = true })
                    Button("Reviewed") {
                        markCommentAsReviewed(report)
                    }
                    Button("Delete Comment") {
                        deleteComment(report)
                    }
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
        .sheet(isPresented: $showWarningDialog) {
            WarningDialog(
                warningMessage: $warningMessage,
                onSend: {
                    giveWarning(message: warningMessage, commentOwnerId: report.reportedCommentUserId)
                    onRemoveReport(report.id)
                    showWarningDialog = false
                }
            )
        }
    }
    
    private func suspendUser(userId: String) {
        databaseRef.child("users").child(userId).updateChildValues(["role": "suspended"]) { error, _ in
            if let error = error {
                print("Error suspending user: \(error)")
            } else {
                print("User \(userId) suspended.")
            }
        }
    }
    
    private func giveWarning(message: String, commentOwnerId: String) {
        let warningRef = databaseRef.child("warnings").child(commentOwnerId).childByAutoId()
        let warningData: [String: Any] = [
            "userId": commentOwnerId,
            "reason": message,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        warningRef.setValue(warningData) { error, _ in
            if let error = error {
                print("Failed to issue warning: \(error.localizedDescription)")
            } else {
                print("Warning issued to user \(commentOwnerId)")
            }
        }
    }
    
    private func markCommentAsReviewed(_ report: ReportData) {
        databaseRef.child("report_comments").child(report.id).removeValue { error, _ in
            if let error = error {
                print("Error removing report: \(error.localizedDescription)")
            } else {
                onRemoveReport(report.id)
                print("Report \(report.id) marked as reviewed.")
            }
        }
    }
    
    private func deleteComment(_ report: ReportData) {
        let commentsRef = databaseRef.child("comments").child(report.postId).child(report.id)
        commentsRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting comment: \(error.localizedDescription)")
            } else {
                onRemoveReport(report.id)
                print("Comment \(report.id) deleted.")
            }
        }
    }
}

// Warning Dialog View
struct WarningDialog: View {
    @Binding var warningMessage: String
    var onSend: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Send Warning")
                .font(.headline)
            
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

// Preview structure for testing
struct InboxAdminView_Previews: PreviewProvider {
    static var previews: some View {
        InboxAdminView()
    }
}
