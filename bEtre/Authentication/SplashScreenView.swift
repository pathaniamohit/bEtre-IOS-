//
//  SplashScreenView.swift
//  bEtre
//
//  Created by Amritpal Gill on 2024-10-03.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive: Bool = false
    
    var body: some View {
        if isActive {
            
            LoginView()
        } else {
            
            ZStack {
                
                Image("Splash_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                
                
                VStack {
                    Text("bEtre")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.mint)
                        .shadow(radius: 5)
                        .padding(.top, -300)
                }
                .onAppear {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
                
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
    
    
struct SplashScreenView_Previews: PreviewProvider {
        static var previews: some View {
            SplashScreenView()
        }
    }

