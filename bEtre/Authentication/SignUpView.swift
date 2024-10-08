import SwiftUI

struct SignUpView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var isSignedUp = false
    @State private var navigateToLoginView: Bool = false
    @State private var navigateToContentView: Bool = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("sign1")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text("bEtre")
                        .font(.custom("Amarante-Regular", size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 40)

                    Text("Sign Up")
                        .font(.custom("RobotoSerif-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 10)

                    VStack(spacing: 16) {
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

                    // Password Fields
                    VStack(spacing: 16) {
                        // Password Field with Visibility Toggle
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
                        .frame(width: 340) // Reduced width
                        .padding(.horizontal, 25)

                        // Confirm Password Field with Visibility Toggle
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
                        .frame(width: 340) // Reduced width
                        .padding(.horizontal, 25)
                    }

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
                            .frame(width: 340, height: 50)
                            .background(Color.black)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 20)

                    // Navigate to Login Button
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
                .font(.custom("RobotoSerif-Regular", size: 16)) // Apply Roboto Serif font to the entire view
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
