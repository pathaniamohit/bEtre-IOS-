//
//  InboxAdmin.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-07.
//

import SwiftUI

struct InboxAdminView: View {
    var body: some View {
        VStack {
            Text("Admin Inbox")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            Spacer()

            List {
                Text("Message from User1")
                Text("Message from User2")
                Text("Message from User3")
                Text("Message from User4")
            }

            Spacer()
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InboxAdminView_Previews: PreviewProvider {
    static var previews: some View {
        InboxAdminView()
    }
}
