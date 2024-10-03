//
//  ForgotPasswordView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//



import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var isPasswordReset = false
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemGray6).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Title
                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                // Email TextField
                TextField("Enter your email", text: $userViewModel.forgotEmail)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)

                // Reset Button
                Button(action: {
                    userViewModel.resetPassword()
                    if userViewModel.isPasswordReset {
                        isPasswordReset = true
                    }
                }) {
                    Text("Reset Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.top, 20)

                // Display error message if any
                if let errorMessage = userViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }

                // Success message after password reset
                if userViewModel.isPasswordReset {
                    Text("Password reset email sent!")
                        .foregroundColor(.green)
                        .padding(.top, 10)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
