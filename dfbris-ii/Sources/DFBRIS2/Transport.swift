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
                    VButtonStack(name: L("Events"), symbol: "calendar.badge.clock", destination: EventList(), tintColorName: "TransportColor", tintFallback: .blue)
                    VButtonStack(name: L("Connection search"), symbol: "magnifyingglass", destination: RouteEngine(), tintColorName: "TransportColor", tintFallback: .blue)
                    VButtonStack(name: L("Dynamic map"), symbol: "globe", destination: OSMMap(), tintColorName: "TransportColor", tintFallback: .blue)
                    VButtonStack(name: L("Vehicles"), symbol: "bus.fill", destination: VehicleList(), tintColorName: "TransportColor", tintFallback: .blue)
                    VButtonStack(name: L("Extraordinary events"), symbol: "exclamationmark.triangle", destination: Mimoradnosti(), tintColorName: "TransportColor", tintFallback: .blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .tint(AppColor("TransportColor", fallback: .blue))
        }
    }
}
