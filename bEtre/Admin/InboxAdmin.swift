import SwiftUI
import FirebaseDatabase

struct InboxAdminView: View {
    @State private var reports: [ReportData] = []
    @State private var navigationPath = NavigationPath()
    private let databaseRef = Database.database().reference()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Reports Inbox")
                    .font(.custom("RobotoSerif-Bold", size: 28))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                
                List(reports, id: \.id) { report in
                    ReportRowView(report: report, navigationPath: $navigationPath)
                }
                .listStyle(PlainListStyle())
            }
            .onAppear {
                observeReports()
            }
            .navigationDestination(for: String.self) { postOwnerId in
                UserProfileView(userId: postOwnerId)
            }
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
                            
                            fetchUsernames(postId: postId, reporterId: reporterId) { postOwnerName, reporterName, postOwnerId in
                                let report = ReportData(
                                    id: "\(postId)-\(reporterId)",
                                    postId: postId,
                                    content: content,
                                    postOwnerId: postOwnerId,
                                    postOwnerName: postOwnerName,
                                    reporterName: reporterName
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

    private func fetchUsernames(postId: String, reporterId: String, completion: @escaping (String, String, String) -> Void) {
        // Get the post owner's userId
        databaseRef.child("posts").child(postId).observeSingleEvent(of: .value) { snapshot in
            let postOwnerId = (snapshot.value as? [String: Any])?["userId"] as? String ?? "Unknown User"
            
            // Fetch usernames of post owner and reporter
            let userRef = databaseRef.child("users")
            userRef.child(postOwnerId).observeSingleEvent(of: .value) { ownerSnapshot in
                let postOwnerName = (ownerSnapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
                
                userRef.child(reporterId).observeSingleEvent(of: .value) { reporterSnapshot in
                    let reporterName = (reporterSnapshot.value as? [String: Any])?["username"] as? String ?? "Unknown User"
                    completion(postOwnerName, reporterName, postOwnerId)
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
}

// Custom view for each report row
struct ReportRowView: View {
    var report: ReportData
    @Binding var navigationPath: NavigationPath
    @State private var showOptions = false
    
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
                        navigationPath.append(report.postOwnerId) // Navigate to UserProfileView
                    }
                    Button("See Post") { /* Handle view post */ }
                    Button("Suspend User") { /* Handle suspend user */ }
                    Button("Give Warning") { /* Handle give warning */ }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(.trailing, 10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 2)
        )
    }
}

// Preview structure for testing
struct InboxAdminView_Previews: PreviewProvider {
    static var previews: some View {
        InboxAdminView()
    }
}
