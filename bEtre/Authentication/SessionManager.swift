//
//  SessionManager.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//

import Foundation

class SessionManager {
    static let shared = SessionManager()

    private init() {}

    func loginUser(userid: String, completion: @escaping (Bool) -> Void) {
        // Here you can handle storing the user session, e.g., saving the user ID to UserDefaults
        UserDefaults.standard.set(userid, forKey: "userID")
        completion(true)
    }

    func logoutUser(completion: @escaping (Bool) -> Void) {
        // Here you can handle removing the user session, e.g., clearing the user ID from UserDefaults
        UserDefaults.standard.removeObject(forKey: "userID")
        completion(true)
    }

    func isLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "userID") != nil
    }
}
