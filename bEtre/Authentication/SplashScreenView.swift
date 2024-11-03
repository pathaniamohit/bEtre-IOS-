import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SplashScreenView: View {
    @State private var isActive: Bool = false
    @State private var shouldNavigateToAdmin: Bool = false
    @State private var shouldNavigateToLogin: Bool = false
    @State private var shouldNavigateToMaison: Bool = false
    private var databaseRef: DatabaseReference = Database.database().reference()

    var body: some View {
        if shouldNavigateToLogin {
            LoginView()
        } else if shouldNavigateToAdmin {
            AdminView()
        } else if shouldNavigateToMaison {
            MaisonView()
        } else {
            ZStack {
                Image("Splash_logo")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    Text("bEtre")
                        .font(.custom("amarante", size: 70))
                        .foregroundColor(Color.mint)
                        .fontWeight(.bold)
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 2, y: 2)
                        .padding(.leading, -110)

                    Text("Be Real, Be You, bEtre")
                        .font(.custom("roboto_serif_regular", size: 30))                        
                        .foregroundColor(Color.mint)
                        .fontWeight(.bold)
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 2, y: 2)
                        .padding(.trailing, 9)
                    
                }
                .padding(.top, -100)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        checkAuthentication()
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func checkAuthentication() {
        if let currentUser = Auth.auth().currentUser {
            setUserOnlineStatus(userId: currentUser.uid) 
            checkUserRole(userId: currentUser.uid)
        } else {
            self.shouldNavigateToLogin = true
        }
    }
    
    private func checkUserRole(userId: String) {
        databaseRef.child("users").child(userId).child("role").observeSingleEvent(of: .value) { snapshot in
            if let role = snapshot.value as? String {
                if role == "admin" || role == "moderator" {
                    self.shouldNavigateToAdmin = true
                } else {
                    self.shouldNavigateToMaison = true
                }
            } else {
                self.shouldNavigateToMaison = true
            }
        } withCancel: { error in
            print("Error fetching user role: \(error.localizedDescription)")
            self.shouldNavigateToLogin = true
        }
    }
    
    private func setUserOnlineStatus(userId: String) {
            let userRef = databaseRef.child("users").child(userId)

            // Set the user as online
            userRef.child("isOnline").setValue(true)
            userRef.child("lastActive").setValue(ServerValue.timestamp())

            // Set up the disconnect handler to mark the user offline on disconnect
            userRef.child("isOnline").onDisconnectSetValue(false)
            userRef.child("lastActive").onDisconnectSetValue(ServerValue.timestamp())
        }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
