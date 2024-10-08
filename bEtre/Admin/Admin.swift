//
//  Admin.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-07.
//

import SwiftUI

struct AdminView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2")
                    Text("Dashboard")
                }

            ActivityView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Activity")
                }

            InboxAdminView()
                .tabItem {
                    Image(systemName: "envelope")
                    Text("Inbox")
                }

            AdminProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
    }
}
