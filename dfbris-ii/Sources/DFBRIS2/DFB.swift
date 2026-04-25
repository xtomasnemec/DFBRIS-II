//
//  DFB.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//


import SwiftUI

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
                    VButtonStack(name: String(localized: "Contact"), symbol: "phone.fill", destination: Contact())
                    VButtonStack(name: String(localized: "Services"), symbol: "calendar.and.person", destination: Services())
                    VButtonStack(name: String(localized: "Timetable"), symbol: "command", destination: Timetable())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .tint(Color("DFBColor"))
        }
    }
}
