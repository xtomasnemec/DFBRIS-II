//
//  Transport.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//

import SwiftUI

struct Transport: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("TransportColor", bundle: .module).opacity(0.25),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .trailing
            )
            .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Transport")
                    .font(.title)
                    .bold()
                    .fontWeight(.heavy)
                    .padding(.top)
                
                Image(systemName: "lightrail.fill")
                    .padding()
                    .font(.system(size: 120, weight: .regular, design: .default))
                
                
                VStack {
                    VButtonStack(name: String(localized: "Events"), symbol: "calendar", destination: EventList())
                    VButtonStack(name: String(localized: "Connection search"), symbol: "magnifyingglass", destination: RouteEngine())
                    VButtonStack(name: String(localized: "Dynamic map"), symbol: "globe", destination: OSMMap())
                    VButtonStack(name: String(localized: "Vehicles"), symbol: "bus.fill", destination: VehicleList())
                    VButtonStack(name: String(localized: "Extraordinary events"), symbol: "exclamationmark.triangle", destination: Mimoradnosti())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .tint(Color("TransportColor"))
        }
    }
}
