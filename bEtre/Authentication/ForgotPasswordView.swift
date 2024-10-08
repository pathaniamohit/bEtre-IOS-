import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var userViewModel = UserViewModel()
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
                            
                            TextField("Enter your email", text: $userViewModel.forgotEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .frame(width: 340)
                        .padding(.top, 15)

                        Button(action: {
                            userViewModel.resetPassword()
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
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
