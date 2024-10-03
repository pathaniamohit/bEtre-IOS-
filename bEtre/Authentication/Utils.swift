//
//  Utils.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-09-24.
//

//import Foundation
//
//struct Utils {
//    
//    static func calculateAge(from dateOfBirth: Date) -> Int {
//            let calendar = Calendar.current
//            let currentDate = Date()
//            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: currentDate)
//            return ageComponents.year ?? 0
//        }
//    
//    static func isValidEmail(_ email: String) -> Bool {
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
//        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//        return emailTest.evaluate(with: email)
//    }
//
//    static func isPasswordValid(_ password: String) -> Bool {
//        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,}$"
//        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
//        return passwordTest.evaluate(with: password)
//    }
//}

import Foundation

struct Utils {
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }

    static func isPasswordValid(_ password: String) -> Bool {
        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordTest.evaluate(with: password)
    }
}
