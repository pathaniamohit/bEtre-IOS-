//
//  SignUpView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//


import SwiftUI

struct SignUpView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var isSignedUp = false
    @State private var navigateToLoginView: Bool = false
    @State private var navigateToContentView: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background Color
                Color(.systemGray6).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // App Title
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
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
                        
                        SecureField("Password", text: $userViewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        
                        SecureField("Confirm Password", text: $userViewModel.confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }

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
                    
                    // Sign Up Button
                    Button(action: {
                        userViewModel.signUp()
                        if userViewModel.isSignedUp {
                            navigateToContentView = true
                        }
                    }) {
                        Text("Sign Up")
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

                    // Navigate to Login Button
                    Button(action: {
                        navigateToLoginView = true
                    }) {
                        Text("Already have an account? Log In")
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .padding(.top, 30)
                    
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
            .fullScreenCover(isPresented: $navigateToLoginView) {
                LoginView()
                    .onDisappear {
                        navigateToLoginView = false
                    }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
