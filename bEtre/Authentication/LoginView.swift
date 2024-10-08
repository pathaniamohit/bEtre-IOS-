import SwiftUI

struct LoginView: View {
    @ObservedObject var userViewModel = UserViewModel()
    @State private var navigateToContentView: Bool = false
    @State private var navigateToSignUpView: Bool = false
    @State private var isPasswordVisible: Bool = false
    
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
                        TextField("Email", text: $userViewModel.loginEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .padding(.horizontal, 25)
                    .padding(.top, 15)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.black)
                        
                        if isPasswordVisible {
                            TextField("Password", text: $userViewModel.loginPassword)
                        } else {
                            SecureField("Password", text: $userViewModel.loginPassword)
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
                    .padding(.horizontal, 25)
                    .padding(.top, 10)

                    Button(action: {
                        userViewModel.login()
                        if userViewModel.isLoggedIn {
                            navigateToContentView = true
                        }
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 25)
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
            }
            .fullScreenCover(isPresented: $navigateToContentView) {
                ContentView()
                    .onDisappear {
                        navigateToContentView = false
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
