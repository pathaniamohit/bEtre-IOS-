//
//  ForgotPasswordView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

//import SwiftUI
//import Firebase
//import FirebaseAuth
//
//struct ForgotPasswordView: View {
//    @State private var email: String = ""
//    @State private var showAlert: Bool = false
//    @State private var alertMessage: String = ""
//
//    var body: some View {
//        VStack {
//            Text("Reset Your Password")
//                .font(.title)
//                .padding(.bottom, 20)
//
//            TextField("Enter your email", text: $email)
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(10)
//                .padding(.horizontal, 30)
//
//            Button(action: {
//                resetPassword()
//            }) {
//                Text("Reset Password")
//                    .foregroundColor(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.cyan)
//                    .cornerRadius(10)
//                    .padding(.horizontal, 30)
//            }
//            .padding(.top, 20)
//        }
//        .alert(isPresented: $showAlert) {
//            Alert(
//                title: Text("Password Reset"),
//                message: Text(alertMessage),
//                dismissButton: .default(Text("OK"))
//            )
//        }
//        .padding(.top, 50)
//    }
//
//    private func resetPassword() {
//        guard !email.isEmpty else {
//            showAlert(message: "Please enter your email address.")
//            return
//        }
//
//        Auth.auth().sendPasswordReset(withEmail: email) { error in
//            if let error = error {
//                showAlert(message: error.localizedDescription)
//            } else {
//                showAlert(message: "A password reset link has been sent to your email.")
//            }
//        }
//    }
//
//    private func showAlert(message: String) {
//        alertMessage = message
//        showAlert = true
//    }
//}
//
//struct ForgotPasswordView_Previews: PreviewProvider {
//    static var previews: some View {
//        ForgotPasswordView()
//    }
//}

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var isPasswordReset = false
    
    var body: some View {
        VStack {
            TextField("Email", text: $userViewModel.forgotEmail)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Reset Password") {
                userViewModel.resetPassword()
                if userViewModel.isPasswordReset {
                    isPasswordReset = true
                }
            }
            .padding()

            if let errorMessage = userViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            if userViewModel.isPasswordReset {
                Text("Password reset email sent!")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
