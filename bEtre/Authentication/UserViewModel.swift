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
    @Published var followers: Int = 0
    @Published var following: Int = 0
    @Published var bio: String = "" 
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
<<<<<<< HEAD
//            self?.saveAdditionalUserInfo() // Save username, phoneNumber, gender to Firestore if needed
=======
            self?.userId = result?.user.uid ?? ""
            self?.saveAdditionalUserInfo()
>>>>>>> 0eb0c5f212305abebbb298d81c6fa4e555116b9c
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
    
<<<<<<< HEAD
    // Optional: Save additional info like username, phone number, gender to Firestore
//    private func saveAdditionalUserInfo() {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//        let db = Firestore.firestore()
//        
//        db.collection("users").document(userId).setData([
//            "username": username,
//            "phoneNumber": phoneNumber,
//            "gender": gender
//        ]) { error in
//            if let error = error {
//                print("Error saving user info: \(error.localizedDescription)")
//            } else {
//                print("User info saved successfully")
//            }
//        }
//    }
   
    func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        
        // Update the user's information in Firestore
        db.collection("users").document(userId).updateData([
            "username": username,
            "phoneNumber": phoneNumber,
            "gender": gender
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
                self.errorMessage = "Failed to update profile"
            } else {
                print("User info updated successfully")
            }
        }
    }
}
=======
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
>>>>>>> 0eb0c5f212305abebbb298d81c6fa4e555116b9c
