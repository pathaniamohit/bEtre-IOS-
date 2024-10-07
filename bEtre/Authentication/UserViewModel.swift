//
//  UserViewModel.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-27.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase


class UserViewModel: ObservableObject {
    @Published var username = ""
    @Published var phoneNumber = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var gender = "Male"
    
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    
    @Published var forgotEmail = ""
    
    @Published var isSignedUp = false
    @Published var isLoggedIn = false
    @Published var isPasswordReset = false
    @Published var errorMessage: String?
    @Published var profileImageUrl = ""
    @Published var userId: String = ""
    
    func signUp() {
        guard !username.isEmpty, Utils.isValidEmail(email),
              Utils.isPasswordValid(password), password == confirmPassword else {
            self.errorMessage = "Invalid signup details"
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("Signup error: \(error.localizedDescription)")
                return
            }
            self?.isSignedUp = true
            self?.userId = result?.user.uid ?? ""
            self?.saveAdditionalUserInfo()
            print("Sign-up successful")
        }
    }
    
    func login() {
        guard Utils.isValidEmail(loginEmail), !loginPassword.isEmpty else {
            self.errorMessage = "Invalid login details"
            return
        }
        
        Auth.auth().signIn(withEmail: loginEmail, password: loginPassword) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("Login error: \(error.localizedDescription)")
                return
            }
            self?.isLoggedIn = true
            self?.userId = result?.user.uid ?? "" 
            self?.loadUserProfile()
            print("Login successful")
        }
    }
    
    func resetPassword() {
        guard Utils.isValidEmail(forgotEmail) else {
            self.errorMessage = "Invalid email for password reset"
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: forgotEmail) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("Password reset error: \(error.localizedDescription)")
                return
            }
            self?.isPasswordReset = true
            print("Password reset email sent")
        }
    }
    
    private func saveAdditionalUserInfo() {
           guard let userId = Auth.auth().currentUser?.uid else { return }
           let ref = Database.database().reference().child("users/\(userId)")
           
           ref.setValue([
               "username": username,
               "phoneNumber": phoneNumber,
               "email": email,
               "gender": gender,
               "profileImageUrl": profileImageUrl
           ]) { error, _ in
               if let error = error {
                   print("Error saving user info: \(error.localizedDescription)")
               } else {
                   print("User info saved successfully")
               }
           }
       }

       func loadUserProfile() {
           guard let userId = Auth.auth().currentUser?.uid else { return }
           let ref = Database.database().reference().child("users/\(userId)")

           ref.observeSingleEvent(of: .value) { snapshot in
               if let data = snapshot.value as? [String: Any] {
                   self.username = data["username"] as? String ?? ""
                   self.phoneNumber = data["phoneNumber"] as? String ?? ""
                   self.email = data["email"] as? String ?? ""
                   self.gender = data["gender"] as? String ?? ""
                   self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
               }
           }
       }

       func saveProfile() {
           guard let userId = Auth.auth().currentUser?.uid else { return }
           let ref = Database.database().reference().child("users/\(userId)")
           
           ref.updateChildValues([
               "username": username,
               "phoneNumber": phoneNumber,
               "gender": gender,
               "profileImageUrl": profileImageUrl
           ]) { error, _ in
               if let error = error {
                   print("Error updating user info: \(error.localizedDescription)")
               } else {
                   print("User info updated successfully")
               }
           }
       }
   }
