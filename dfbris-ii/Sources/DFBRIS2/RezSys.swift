//
//  RezSys.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//

import SwiftUI
import SkipFuse

struct RezSys: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("RezSysColor", bundle: .module).opacity(0.25),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .trailing
            )
            .edgesIgnoringSafeArea(.all)
            VStack {
                Text("RezSys")
                    .font(.title)
                    .bold()
                    .fontWeight(.heavy)
                    .padding(.top)
                
                Image(systemName: "wallet.bifold.fill")
                    .padding()
                    .font(.system(size: 120, weight: .regular, design: .default))
                
                
                    VStack {
                        let loginHandler = LoginHandler.shared
                        if loginHandler.isLogedIn {
                            VButtonStack(name: L("Reservations"), symbol: "tram.card.fill", destination: Reservations(), tintColorName: "RezSysColor", tintFallback: .orange)
                        }
                        
                        if loginHandler.isOrganizator, loginHandler.isLogedIn {
                            VButtonStack(name: L("Reservations Admin"), symbol: "list.clipboard.fill", destination: AdminReservations(), tintColorName: "RezSysColor", tintFallback: .orange)
                        }
                        
                        if loginHandler.isLogedIn {
                            VButtonStack(name: L("My account"), symbol: "person.crop.square.filled.and.at.rectangle.fill", destination: Account(), tintColorName: "RezSysColor", tintFallback: .orange)
                        }
                        
                        if !loginHandler.isLogedIn {
                            VButtonStack(name: L("Login"), symbol: "key.2.on.ring.fill", destination: LoginPage(), tintColorName: "RezSysColor", tintFallback: .orange)
                        }
                        
                        if loginHandler.isOrganizator, loginHandler.isLogedIn {
                            VButtonStack(name: L("Ticket check"), symbol: "ticket.fill", destination: AdminReservations(), tintColorName: "RezSysColor", tintFallback: .orange)
                        }
                        
                        if loginHandler.isLogedIn {
                            VButtonStack(name: L("Logout"), symbol: "key.slash.fill", destination: Logout(), tintColorName: "RezSysColor", tintFallback: .orange)
                        }
                        }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            .tint(AppColor("RezSysColor", fallback: .orange))
        }
    }
