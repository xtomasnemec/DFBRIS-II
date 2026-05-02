//
//  HomeScreen.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//

import SwiftUI


struct HomeScreen: View {
    
    @State var apkmessage: String = ""
    
    //light mode check
    @Environment(\.colorScheme) var colorScheme
 
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.25), Color.clear]), startPoint: .top, endPoint: .trailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Text("DFBRIS II")
                    .font(.title)
                    .bold()
                    .fontWeight(.heavy)
                    .padding(.top)
                
#if TARGET_OS_ANDROID
                Image(systemName: "tram.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
#else
                Image(colorScheme == .dark ? "DFBLogo" : "DFBLogoLight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
#endif
                
                Spacer()
                
                Text(apkmessage)
                    .multilineTextAlignment(.center)
                    .padding()
                    .bold()
                
                Spacer()
                
                HStack {
                    SocialLink(name: "Discord", link: "https://discord.gg/DF2bPa67g7", image: "discord")
                    SocialLink(name: "DFB website", link: "https://www.dopravnifotoakce.cz/", image: colorScheme == .dark ? "DFBLogo" : "DFBLogoLight")
                    SocialLink(name: "Facebook", link: "https://www.facebook.com/dfotoakcebrno", image: "facebook")
                    SocialLink(name: "Instagram", link: "https://www.instagram.com/dfotoakcebrno.cz", image: "instagram")
                }
                .tint(.primary)
            }
            .padding()
            .task {
                apkmessage = await ApkMessageParser()
            }
        }
    }
}
