//
//  ActivityAdmin.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-07.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        VStack {
            Text("Admin Activity")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            Spacer()

            List {
                Text("User 'JohnDoe' posted a new comment.")
                Text("User 'JaneSmith' liked a post.")
                Text("User 'Admin' deleted a post.")
                Text("User 'Alex' updated their profile.")
            }

            Spacer()
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
