import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct LoginView: View {
    @State private var loginEmail: String = ""
    @State private var loginPassword: String = ""
    @State private var navigateToMaisonView: Bool = false
    @State private var navigateToAdminView: Bool = false
    @State private var navigateToSignUpView: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    private var databaseRef: DatabaseReference = Database.database().reference()

    var body: some View {
        NavigationView {
            ZStack {
                Image("login_image")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer(minLength: 50)
                    
                    Text("bEtre")
                        .font(.custom("amarante", size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 20)

                    Text("Sign In")
                        .font(.custom("roboto_serif_regular", size: 30))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 5)
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.black)
                        TextField("Email", text: $loginEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .frame(width: 340)
                    .padding(.top, 15)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.black)
                        
                        if isPasswordVisible {
                            TextField("Password", text: $loginPassword)
                        } else {
                            SecureField("Password", text: $loginPassword)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .frame(width: 340)
                    .padding(.top, 10)

                    Button(action: {
                        loginUser()
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 340, height: 50)
                            .background(Color.black)
                            .cornerRadius(10)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)

                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forget Password?")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 10)

                    Spacer()

                    Button(action: {
                        navigateToSignUpView = true
                    }) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 120)
                    
                    Spacer(minLength: 30)
                }
                .font(.custom("roboto_serif_regular", size: 16))
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Login Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
                }
            }
            .fullScreenCover(isPresented: $navigateToMaisonView) {
                MaisonView()
                    .onDisappear {
                        navigateToMaisonView = false
                    }
            }
            .fullScreenCover(isPresented: $navigateToAdminView) {
                AdminView() // Implement AdminView to handle admin-specific logic
                    .onDisappear {
                        navigateToAdminView = false
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
    
    private func loginUser() {
        let email = loginEmail
        let password = loginPassword
        
        if email.isEmpty || !isValidEmail(email) {
            errorMessage = "Valid email is required"
            showAlert = true
            return
        }
        
        if password.isEmpty {
            errorMessage = "Password is required"
            showAlert = true
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                handleLoginError(error: error)
                return
            }
            
            if let userId = Auth.auth().currentUser?.uid {
                checkUserRole(userId: userId)
            }
        }
    }

    private func checkUserRole(userId: String) {
        databaseRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists(), let userData = snapshot.value as? [String: Any], let role = userData["role"] as? String {
                navigateBasedOnRole(role: role)
            } else {
                errorMessage = "User role not found or user doesn't exist"
                showAlert = true
            }
        } withCancel: { error in
            errorMessage = "Error checking user role: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func navigateBasedOnRole(role: String) {
        if role == "admin" || role == "moderator"  {
            navigateToAdminView = true
        } else if role == "user" {
            navigateToMaisonView = true
        } else {
            errorMessage = "Unknown role."
            showAlert = true
        }
    }

    private func handleLoginError(error: Error) {
        errorMessage = "Authentication failed: \(error.localizedDescription)"
        showAlert = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
