//
//  ViewModerator.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-31.
//

import SwiftUI
import FirebaseDatabase

struct ViewModerator: View {
    @State private var moderators: [ModeratorUser] = []
    @State private var showDeleteDialog: Bool = false
    @State private var selectedModerator: ModeratorUser? = nil

    private let databaseRef = Database.database().reference()

    var body: some View {
        VStack {
            Text("Moderators")
                .font(.largeTitle)
                .padding()
            
            List(moderators) { moderator in
                HStack {
                    VStack(alignment: .leading) {
                        Text(moderator.username)
                            .font(.headline)
                        Text(moderator.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: {
                        selectedModerator = moderator
                        showDeleteDialog = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(.trailing, 10)
                }
                .padding()
            }
            .listStyle(PlainListStyle())
            .onAppear(perform: fetchModerators)
            .alert(isPresented: $showDeleteDialog) {
                Alert(
                    title: Text("Remove Moderator"),
                    message: Text("Are you sure you want to remove this moderator?"),
                    primaryButton: .destructive(Text("Remove"), action: removeModerator),
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func fetchModerators() {
        databaseRef.child("users").observeSingleEvent(of: .value) { snapshot in
            var fetchedModerators: [ModeratorUser] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let userData = snapshot.value as? [String: Any],
                   let username = userData["username"] as? String,
                   let email = userData["email"] as? String,
                   let role = userData["role"] as? String,
                   role == "moderator" {
                    let moderator = ModeratorUser(id: snapshot.key, username: username, email: email)
                    fetchedModerators.append(moderator)
                }
            }
            self.moderators = fetchedModerators
        }
    }

    private func removeModerator() {
        guard let moderator = selectedModerator else { return }
        databaseRef.child("users").child(moderator.id).child("role").setValue("user") { error, _ in
            if error == nil {
                fetchModerators()
            }
        }
    }
}

struct ModeratorUser: Identifiable, Hashable {
    var id: String
    var username: String
    var email: String
}
