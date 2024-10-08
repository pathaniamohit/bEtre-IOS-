//
//  Admin.swift
//  bEtre
//
//  Created by Mohit Pathania on 2024-10-07.
//

import SwiftUI

struct AdminView: View {
    var body: some View {
        Text("Welcome to the Admin Panel")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
            .navigationTitle("Admin Dashboard")
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
    }
}
