//
//  UILib.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//
import SwiftUI


// submenu

struct VButtonStack<Destination: View>: View {

    var name: String
    var symbol: String
    var destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(name)
                    .font(.system(size: 22))
                Spacer()
                Image(systemName: symbol)
            }
            .padding()
            .frame(width: 370)
            .background(.gray.opacity(0.1))
            .cornerRadius(14)
        }
    }
}

// tlacitka na socialni site
@MainActor //nevim bez tyhle kokotiny to nejede
struct SocialLink: View {

    var name: String
    var link: String
    var image: String

    var body: some View {
        Link(destination: URL(string: link)!) {
            VStack {
                Image(image)
                    .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                Text(name)
                    .font(.system(size: 10, weight: .regular, design: .default))
            }
            .frame(width: 60, height: 60)
            .safeAreaPadding()
            .background(.gray.opacity(0.1))
            .cornerRadius(14)
        }
    }
}
