import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var forgotEmail: String = ""
    @State private var isPasswordReset: Bool = false
    @State private var errorMessage: String?
    @State private var navigateToLoginView: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("forgot_password_image")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()

                    VStack {
                        Text("bEtre")
                            .font(.custom("amarante", size: 48))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, -30)

                        Text("Reset Account Password")
                            .font(.custom("roboto_serif_regular", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 5)

                        HStack(spacing: 10) {
                            Image(systemName: "envelope")
                                .foregroundColor(.black)
                            
                            TextField("Enter your email", text: $forgotEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .frame(width: 340)
                        .padding(.top, 15)

                        Button(action: {
                            resetPassword()
                        }) {
                            Text("Reset Password")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 340, height: 50)
                                .background(Color.black)
                                .cornerRadius(10)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 10)
                        }

                        if isPasswordReset {
                            Text("Password reset email sent!")
                                .foregroundColor(.green)
                                .padding(.top, 10)
                        }
                    }
                    .multilineTextAlignment(.center)

                    Spacer()
                }
                .font(.custom("roboto_serif_regular", size: 16))
                .padding(.top, -60)
            }
            .navigationDestination(isPresented: $navigateToLoginView) {
                LoginView()
            }
        }
    }

    // Password reset function moved to the view
    private func resetPassword() {
        guard forgotEmail.isValidEmail() else {
            errorMessage = "Invalid email for password reset"
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: forgotEmail) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.isPasswordReset = true
        }
    }
}

extension String {
    func isValidEmail() -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
