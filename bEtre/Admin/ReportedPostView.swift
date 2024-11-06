//
//  ReportedPostView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-11-04.
//

import SwiftUI
import FirebaseDatabase
import FirebaseStorage
import SDWebImageSwiftUI

struct Report: Identifiable {
    var id: String // Unique identifier for the report
    var postId: String
    var reportedBy: String
    var reason: String
    var timestamp: TimeInterval
    var status: String
    var content: String
    var imageUrl: String? // Add an optional image URL field
}

struct ReportedPostsView: View {
    @State private var reports: [Report] = []
    @State private var isLoading: Bool = true
    @State private var showActionSheet: Bool = false
    @State private var selectedReport: Report?
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
    
    private let databaseRef = Database.database().reference().child("reports")
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Reports...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                } else if reports.isEmpty {
                    Text("No Reports Found")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(reports) { report in
                        reportRow(for: report) // Use a helper function for each row
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Reported Posts")
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Report Actions"),
                    message: Text("Choose an action for this report."),
                    buttons: [
                        .default(Text("Dismiss Report")) {
                            if let report = selectedReport {
                                dismissReport(report: report)
                            }
                        },
                        .destructive(Text("Issue Warning")) {
                            if let report = selectedReport {
                                issueWarning(for: report)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .onAppear(perform: fetchReports)
        }
    }
    
    // MARK: - Report Row View Helper Function
    @ViewBuilder
    private func reportRow(for report: Report) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Post ID: \(report.postId)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("Reported By: \(report.reportedBy)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(report.status.capitalized)
                    .font(.caption)
                    .padding(6)
                    .background(reportStatusColor(for: report.status))
                    .cornerRadius(8)
            }
            
            if let imageUrl = report.imageUrl, !imageUrl.isEmpty {
                WebImage(url: URL(string: imageUrl))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .cornerRadius(8)
            }

            
            Text("Reason: \(report.reason)")
                .font(.body)
                .foregroundColor(.black)
            
            Text("Content: \(report.content)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Reported At: \(Date(timeIntervalSince1970: report.timestamp), formatter: dateFormatter)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .onTapGesture {
            self.selectedReport = report
            self.showActionSheet = true
        }
    }
    
    // MARK: - Fetch Reports from Firebase
    func fetchReports() {
        databaseRef.observe(.value) { snapshot in
            var loadedReports: [Report] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let reportData = childSnapshot.value as? [String: Any],
                   let postId = reportData["postId"] as? String,
                   let reportedBy = reportData["reportedBy"] as? String,
                   let reason = reportData["reason"] as? String,
                   let timestamp = reportData["timestamp"] as? TimeInterval,
                   let status = reportData["status"] as? String,
                   let content = reportData["content"] as? String {
                    
                    fetchPostImage(postId: postId) { imageUrl in
                        let report = Report(
                            id: childSnapshot.key,
                            postId: postId,
                            reportedBy: reportedBy,
                            reason: reason,
                            timestamp: timestamp,
                            status: status,
                            content: content,
                            imageUrl: imageUrl
                        )
                        loadedReports.append(report)
                        
                        self.reports = loadedReports.sorted { $0.timestamp > $1.timestamp }
                        self.isLoading = false
                    }
                }
            }
        } withCancel: { error in
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
            self.isLoading = false
        }
    }
    
    // MARK: - Fetch Post Image URL
    func fetchPostImage(postId: String, completion: @escaping (String?) -> Void) {
        let postRef = Database.database().reference().child("posts").child(postId).child("imageUrl")
        postRef.observeSingleEvent(of: .value) { snapshot in
            if let imageUrl = snapshot.value as? String {
                completion(imageUrl)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Dismiss Report
    func dismissReport(report: Report) {
        databaseRef.child(report.id).child("status").setValue("reviewed") { error, _ in
            if let error = error {
                self.errorMessage = "Failed to dismiss report: \(error.localizedDescription)"
                self.showErrorAlert = true
            } else {
                if let index = self.reports.firstIndex(where: { $0.id == report.id }) {
                    self.reports[index].status = "reviewed"
                }
            }
        }
    }
    
    // MARK: - Delete Post
    // Warning Model
    struct Warning {
        var warningId: String
        var userId: String
        var reason: String
        var timestamp: TimeInterval
    }

    // MARK: - Issue Warning Function
    func issueWarning(for report: Report) {
        let alertController = UIAlertController(title: "Issue Warning", message: "Please provide a reason for issuing this warning.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter reason for warning"
        }
        
        // Add "Submit" action
        alertController.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
            if let reason = alertController.textFields?.first?.text, !reason.isEmpty {
                saveWarning(for: report, reason: reason)
            } else {
                self.errorMessage = "Warning reason cannot be empty."
                self.showErrorAlert = true
            }
        })
        
        // Add "Cancel" action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Save Warning and Remove Post and Report
    func saveWarning(for report: Report, reason: String) {
        let userId = report.reportedBy // Assuming reportedBy is the userId of the post owner
        let timestamp = Date().timeIntervalSince1970
        let warningId = UUID().uuidString // Generate a unique warning ID
        
        // Create warning data
        let warningData: [String: Any] = [
            "userId": userId,
            "reason": reason,
            "timestamp": timestamp
        ]
        
        let warningsRef = Database.database().reference().child("warnings").child(userId).child(warningId)
        let postRef = Database.database().reference().child("posts").child(report.postId)
        let reportsRef = Database.database().reference().child("reports").child(report.id)
        
        // Save the warning
        warningsRef.setValue(warningData) { error, _ in
            if let error = error {
                self.errorMessage = "Failed to save warning: \(error.localizedDescription)"
                self.showErrorAlert = true
            } else {
                // Remove the post and report
                postRef.removeValue { postError, _ in
                    if let postError = postError {
                        self.errorMessage = "Failed to delete post: \(postError.localizedDescription)"
                        self.showErrorAlert = true
                    } else {
                        reportsRef.removeValue { reportError, _ in
                            if let reportError = reportError {
                                self.errorMessage = "Failed to delete report: \(reportError.localizedDescription)"
                                self.showErrorAlert = true
                            } else {
                                // Update local list
                                if let index = self.reports.firstIndex(where: { $0.id == report.id }) {
                                    self.reports.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper to Get Color for Status
    private func reportStatusColor(for status: String) -> Color {
        switch status {
        case "pending":
            return Color.yellow.opacity(0.3)
        case "reviewed":
            return Color.green.opacity(0.3)
        default:
            return Color.red.opacity(0.3)
        }
    }
    
    // Date Formatter
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
