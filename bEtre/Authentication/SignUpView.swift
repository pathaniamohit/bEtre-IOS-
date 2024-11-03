import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SignUpView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var gender: String = "Male" // Default value
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
                            TextField("Username", text: $username)
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
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)

                        // Phone Number Field
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.black)
                            TextField("Enter your Phone number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .frame(width: 340)
                        .padding(.horizontal, 25)
                    }

                    // Gender Picker
                    HStack(spacing: 40) {
                        Picker("", selection: $gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    .padding(.horizontal, 25)

                    VStack(spacing: 16) {
                        // Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black)
                            if isPasswordVisible {
                                TextField("Create your Password", text: $password)
                            } else {
                                SecureField("Create your Password", text: $password)
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

                        // Confirm Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black)
                            if isConfirmPasswordVisible {
                                TextField("Confirm your Password", text: $confirmPassword)
                            } else {
                                SecureField("Confirm your Password", text: $confirmPassword)
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

                    // Sign Up Button
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

                    // Navigation to Login View
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
        if username.count < 8 {
            errorMessage = "Username must be at least 8 characters"
            showAlert = true
            return
        }

        if !isValidEmail(email) {
            errorMessage = "Enter a valid email"
            showAlert = true
            return
        }

        if phoneNumber.count != 10 || !isValidPhone(phoneNumber) {
            errorMessage = "Enter a valid 10-digit phone number"
            showAlert = true
            return
        }

        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters"
            showAlert = true
            return
        }

        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showAlert = true
            return
        }

        createUserWithFirebase()
    }

    private func createUserWithFirebase() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showAlert = true
                return
            }

            guard let uid = authResult?.user.uid else { return }
            
            let userData: [String: Any] = [
                "username": username,
                "email": email,
                "phoneNumber": phoneNumber,
                "gender": gender,
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
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
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
