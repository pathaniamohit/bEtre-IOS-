//
//  SuspendedUsersListView.swift
//  bEtre
//
//  Created by Nabeel Shajahan on 2024-11-05.
//

struct SuspendedUsersListView: View {
    var suspendedUsers: [SuspendedUser]

    var body: some View {
        VStack {
            Text("Suspended Users")
                .font(.title)
                .padding()

            List(suspendedUsers) { user in
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                    Text("Email: \(user.email)")
                    Text("Phone: \(user.phone)")
                }
                .padding(.vertical, 5)
            }
        }
    }
}
