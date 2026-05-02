//
//  Contact.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 24.04.2026.
//
import SwiftUI

struct Contact: View {
    @State var contacts: [ContactItem] = []
    @State var isLoading = true

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColor("DFBColor", fallback: .red).opacity(0.24),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(contacts) { contact in
                        ContactRow(contact: contact)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(L("Contacts"))
        .task {
            contacts = await ContactParser(isOrganizator: LoginHandler.shared.isOrganizator)
            isLoading = false
        }
    }
}

struct ContactRow: View {
    let contact: ContactItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                if !contact.phone.isEmpty, let phoneUrl = URL(string: "tel:\(contact.phone.replacingOccurrences(of: " ", with: ""))") {
                    Link(destination: phoneUrl) {
                        Label(contact.phone, systemImage: "phone.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary) // Text bude bílý/černý
                            .tint(AppColor("DFBColor", fallback: .red)) // Ikona bude mít barvu DFB
                    }
                    .buttonStyle(.borderless)
                }
                ForEach(contact.emails, id: \.self) { email in
                    Group {
                        if let emailUrl = URL(string: "mailto:\(email)") {
                            Link(destination: emailUrl) {
                                Label(email, systemImage: "envelope.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .tint(AppColor("DFBColor", fallback: .red))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.8)) // Standardní "normální" pozadí karty
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColor("DFBColor", fallback: .red).opacity(0.3), lineWidth: 1) // Jemný barevný okraj
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 2)
    }
}
