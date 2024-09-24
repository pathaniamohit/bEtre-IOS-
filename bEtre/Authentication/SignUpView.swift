//
//  SignUpView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var dateOfBirth = Date()
    @State private var isPasswordVisible: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToContentView: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
               
                
                Text("Create Your Account")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .bold()
                    .padding(.bottom, 20)
                
                VStack(spacing: 15) {
                    TextField("Email Address", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .padding()
                        } else {
                            SecureField("Password", text: $password)
                                .padding()
                        }
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .padding(10)
                        }
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Button(action: {
                    signUpUser()
                }) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cyan)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                }
                .padding(.vertical, 20)
                
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.black)
                    
                    NavigationLink(destination: LoginView()) {
                        Text("Sign in here")
                            .foregroundColor(.black)
                            
                    }
                }
                .padding(.bottom, 200)
            }
            .background(Color.white)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Sign Up Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fullScreenCover(isPresented: $navigateToContentView, content: {
                ContentView()
                    .onDisappear() {
                        navigateToContentView = false
                    }
            })
        }
    }
    
    private func signUpUser() {
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        if password != confirmPassword {
            showAlert(message: "Passwords do not match.")
            return
        }
        
        if !Utils.isValidEmail(email) {
            showAlert(message: "Please enter a valid Email Address.")
            return
        }
        
        if !Utils.isPasswordValid(password) {
            showAlert(message: "Password must contain at least one letter and one digit.")
            return
        }
        
        let age = Utils.calculateAge(from: dateOfBirth)
        if age < 18 {
            showAlert(message: "You must be at least 18 years old to sign up.")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
            } else if let authResult = authResult {
                let userID = authResult.user.uid
                
                print("User ID: \(userID), Age: \(age)")
                SessionManager.shared.loginUser(userid: userID) { success in
                    if success {
                        self.navigateToContentView = true
                    } else {
                        self.showAlert(message: "Failed to sign up. Please try again later.")
                    }
                }
            } else {
                self.showAlert(message: "Sign up failed. Please try again later.")
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
