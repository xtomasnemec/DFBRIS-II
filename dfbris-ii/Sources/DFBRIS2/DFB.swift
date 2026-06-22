//
//  DFB.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//


import SwiftUI
import SkipFuse
import Foundation

struct DFB: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("DFBColor", bundle: .module).opacity(0.25),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .trailing
            )
            .edgesIgnoringSafeArea(.all)
            VStack {
                Text("DFB_")
                    .font(.title)
                    .bold()
                    .fontWeight(.heavy)
                    .padding(.top)
                
                Image(systemName: "camera.fill")
                    .padding()
                    .font(.system(size: 120, weight: .regular, design: .default))
                

                VStack {
                    let loginHandler = LoginHandler.shared
                    VButtonStack(name: L("Contact"), symbol: "phone.fill", destination: Contact(), tintColorName: "DFBColor", tintFallback: .green)
                    if loginHandler.isLogedIn && (loginHandler.OrganizatorRole || loginHandler.lastUsername == Optional("tomasnemec") || loginHandler.lastUsername == Optional("tomashrebicek")) {VButtonStack(name: L("Services"), symbol: "calendar.and.person", destination: Services(), tintColorName: "DFBColor", tintFallback: .green)}
                    if loginHandler.isLogedIn && (loginHandler.OrganizatorRole || loginHandler.lastUsername == Optional("tomasnemec") || loginHandler.lastUsername == Optional("tomashrebicek")) {VButtonStack(name: L("Timetable"), symbol: "command", destination: Timetable(), tintColorName: "DFBColor", tintFallback: .green)}
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .tint(AppColor("DFBColor", fallback: .green))
        }
    }
}
