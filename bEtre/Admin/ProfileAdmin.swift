import SwiftUI

struct AdminProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("My Profile")
                    .font(.custom("RobotoSerif-Bold", size: 30))
                    .padding(.top, 40)
                
                VStack(spacing: 10) {
                    Image("profile_placeholder")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    
                    Text("Kathrine Mils")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("kathrine@gmail.com")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, -10)
                
                Divider()
                
            
                VStack(alignment: .leading, spacing: 16) {
                    ProfileActionRow(icon: "person.crop.circle", title: "Edit Profile")
                    Divider()
                    
                    ProfileActionRow(icon: "lock.circle", title: "Account and Privacy")
                    Divider()
                    
                    ProfileActionRow(icon: "info.circle", title: "About")
                    Divider()
                    
                    ProfileActionRow(icon: "arrowshape.turn.up.left.circle", title: "Logout")
                    Divider()
                }
                .padding()
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("My Profile")
    }
}

struct ProfileActionRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.custom("RobotoSerif-Regular", size: 16))
            
            Spacer()
        }
        .padding(.vertical, 8)
        .onTapGesture {
        }
    }
}

struct AdminProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AdminProfileView()
    }
}
