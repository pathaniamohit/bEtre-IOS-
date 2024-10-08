//
//  Dashboard.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-07.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            Spacer()

            // Placeholder for dashboard statistics and data
            VStack(spacing: 20) {
                Text("Total Users: 500")
                    .font(.title2)
                    .padding()

                Text("Active Sessions: 120")
                    .font(.title2)
                    .padding()

                Text("Posts Today: 45")
                    .font(.title2)
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
