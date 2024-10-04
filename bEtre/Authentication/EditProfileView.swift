//
//  EditProfileView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-10-03.
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss // To dismiss the view when done

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                // Input Fields
                VStack(spacing: 16) {
                    TextField("Username", text: $userViewModel.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    TextField("Phone Number", text: $userViewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    TextField("Email", text: $userViewModel.email)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)

                    // Gender Picker
                    Picker("Gender", selection: $userViewModel.gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }

                // Save Changes Button
                Button(action: {
                    userViewModel.saveProfile() // Save changes
                    dismiss() // Dismiss the edit view
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline) // Keep title inline
        }
    }
}


struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample UserViewModel for preview purposes
        let userViewModel = UserViewModel()

        EditProfileView(userViewModel: userViewModel)
    }
}
