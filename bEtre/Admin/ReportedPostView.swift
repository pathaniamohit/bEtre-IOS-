//
//  ReportedPostView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-11-04.
//

import SwiftUI
import FirebaseDatabase

import Foundation

struct Report: Identifiable {
    var id: String // Unique identifier for the report
    var postId: String
    var reportedBy: String
    var reason: String
    var timestamp: TimeInterval
    var status: String
    var content: String
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
                                    .background(report.status == "pending" ? Color.yellow.opacity(0.3) :
                                                report.status == "reviewed" ? Color.green.opacity(0.3) :
                                                Color.red.opacity(0.3))
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
                        .destructive(Text("Delete Post")) {
                            if let report = selectedReport {
                                deletePost(report: report)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .onAppear(perform: fetchReports)
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
                    
                    let report = Report(
                        id: childSnapshot.key,
                        postId: postId,
                        reportedBy: reportedBy,
                        reason: reason,
                        timestamp: timestamp,
                        status: status,
                        content: content
                    )
                    loadedReports.append(report)
                }
            }
            
            self.reports = loadedReports.sorted { $0.timestamp > $1.timestamp }
            self.isLoading = false
        } withCancel: { error in
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
            self.isLoading = false
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
    func deletePost(report: Report) {
        let postRef = Database.database().reference().child("posts").child(report.postId)
        let likesRef = Database.database().reference().child("likes").child(report.postId)
        let commentsRef = Database.database().reference().child("comments").child(report.postId)
        let reportsRef = Database.database().reference().child("reports").child(report.id)
        
        // Delete the post
        postRef.removeValue { error, _ in
            if let error = error {
                self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
                self.showErrorAlert = true
            } else {
                // Optionally, delete associated likes and comments
                likesRef.removeValue()
                commentsRef.removeValue()
                // Remove the report entry
                reportsRef.removeValue()
                
                // Remove the report from local list
                if let index = self.reports.firstIndex(where: { $0.id == report.id }) {
                    self.reports.remove(at: index)
                }
            }
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

