import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SignUpView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var isSignedUp = false
    @State private var navigateToLoginView: Bool = false
    @State private var navigateToContentView: Bool = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    private var databaseRef: DatabaseReference = Database.database().reference()

    var body: some View {
        NavigationView {
            ZStack {
                Image("sign1")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // App Title
                    Text("bEtre")
                        .font(.custom("amarante", size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 40)

                    Text("Sign Up")
                        .font(.custom("RobotoSerif-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 10)

                    // Input Fields
                    VStack(spacing: 16) {
                        // Username Field
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.black)
                            TextField("Username", text: $userViewModel.username)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)

                        // Email Field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.black)
                            TextField("Email", text: $userViewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)

                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.black)
                            TextField("Enter your Phone number", text: $userViewModel.phoneNumber)
                                .keyboardType(.phonePad)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)
                    }

                    HStack(spacing: 40) {
                        Picker("", selection: $userViewModel.gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    .padding(.horizontal, 25)

                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black)
                            if isPasswordVisible {
                                TextField("Create your Password", text: $userViewModel.password)
                            } else {
                                SecureField("Create your Password", text: $userViewModel.password)
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black)
                            if isConfirmPasswordVisible {
                                TextField("Confirm your Password", text: $userViewModel.confirmPassword)
                            } else {
                                SecureField("Confirm your Password", text: $userViewModel.confirmPassword)
                            }
                            Button(action: {
                                isConfirmPasswordVisible.toggle()
                            }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)
                    }

                    Button(action: {
                        validateAndSignUp()
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 340, height: 50)
                            .background(Color.black)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 20)

                    Button(action: {
                        navigateToLoginView = true
                    }) {
                        Text("Already have an account? Sign In")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .font(.custom("RobotoSerif-Regular", size: 16))
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $navigateToLoginView) {
                LoginView()
                    .onDisappear {
                        navigateToLoginView = false
                    }
            }
        }
    }

    private func validateAndSignUp() {
        // Validate inputs
        if userViewModel.username.count < 8 {
            errorMessage = "Username must be at least 8 characters"
            showAlert = true
            return
        }

        if !isValidEmail(userViewModel.email) {
            errorMessage = "Enter a valid email"
            showAlert = true
            return
        }

        if userViewModel.phoneNumber.count != 10 || !isValidPhone(userViewModel.phoneNumber) {
            errorMessage = "Enter a valid 10-digit phone number"
            showAlert = true
            return
        }

        if userViewModel.password.count < 8 {
            errorMessage = "Password must be at least 8 characters"
            showAlert = true
            return
        }

        if userViewModel.password != userViewModel.confirmPassword {
            errorMessage = "Passwords do not match"
            showAlert = true
            return
        }

        createUserWithFirebase()
    }

    private func createUserWithFirebase() {
        Auth.auth().createUser(withEmail: userViewModel.email, password: userViewModel.password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showAlert = true
                return
            }

            guard let uid = authResult?.user.uid else { return }
            
            let userData: [String: Any] = [
                "username": userViewModel.username,
                "email": userViewModel.email,
                "phoneNumber": userViewModel.phoneNumber,
                "gender": userViewModel.gender,
                "role": "user"
            ]
            
            databaseRef.child("users").child(uid).setValue(userData) { error, _ in
                if let error = error {
                    errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    // Success, navigate to LoginView
                    errorMessage = "Registration successful. Please log in."
                    navigateToLoginView = true
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        // Validate email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        // Validate phone number format (10 digits)
        let phoneRegex = "^[0-9]{10}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePred.evaluate(with: phone)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
