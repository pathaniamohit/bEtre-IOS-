//
//  LoginView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//


import SwiftUI

struct LoginView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var navigateToContentView: Bool = false
    @State private var navigateToSignUpView: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemGray6).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // App Title
                    Text("bEtre")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.top, 60)
                    
                    Text("Sign In")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    // Email TextField
                    TextField("Email", text: $userViewModel.loginEmail)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    
                    // Password TextField
                    SecureField("Password", text: $userViewModel.loginPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    
                    // Login Button
                    Button(action: {
                        userViewModel.login()
                        if userViewModel.isLoggedIn {
                            navigateToContentView = true
                        }
                    }) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 280, height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 20)

                    // Error Message
                    if let errorMessage = userViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                    
                    // Navigate to Sign Up Button
                    Button(action: {
                        navigateToSignUpView = true
                    }) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .padding(.top, 20)
                    
                    // Forgot Password Link
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password? Reset Here.")
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .fullScreenCover(isPresented: $navigateToContentView) {
                ContentView()
                    .onDisappear {
                        navigateToContentView = false
                    }
            }
            .fullScreenCover(isPresented: $navigateToSignUpView) {
                SignUpView()
                    .onDisappear {
                        navigateToSignUpView = false
                    }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
