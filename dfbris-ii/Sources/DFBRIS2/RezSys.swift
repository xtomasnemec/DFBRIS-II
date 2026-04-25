//
//  RezSys.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//

import SwiftUI

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
                        VButtonStack(name: String(localized: "Reservations"), symbol: "tram.card.fill", destination: Reservations())
                        if isOrganizator { VButtonStack(name: String(localized: "Reservations Admin"), symbol: "list.clipboard.fill", destination: AdminReservations())}
                        VButtonStack(name: String(localized: "My account"), symbol: "person.crop.square.filled.and.at.rectangle.fill", destination: Account())
                        VButtonStack(name: String(localized: "Login"), symbol: "key.2.on.ring.fill", destination: LoginPage())
                        if isOrganizator { VButtonStack(name: String(localized: "Ticket check"), symbol: "ticket.fill", destination: AdminReservations())}
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            .tint(Color("RezSysColor"))
        }
    }
}
