//
//  Logout.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 27.04.2026.
//

import SwiftUI
import SkipFuse

struct Logout: View {
    var body: some View {
        let loginHandler = LoginHandler.shared
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColor("RezSysColor", fallback: .orange).opacity(0.24),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 78, weight: .regular))
                        .foregroundStyle(.red)

                    Text(L("Logout"))
                        .font(.title)
                        .bold()

                    Text(loginHandler.isLogedIn ? L("Confirm logout") : L("You are already logged out"))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                VStack(spacing: 16) {
                    if let displayName = LoginHandler.shared.displayName {
                        Text(displayName)
                            .font(.title2)
                            .bold()

                        Text(loginHandler.isLogedIn ? L("You are signed in right now") : L("No active session found"))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(role: .destructive, action: performLogout) {
                        Text(L("Logout"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!loginHandler.isLogedIn)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.background.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.red.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle(L("Logout"))
    }

    private func performLogout() {
        LoginHandler.shared.logout()
        AppState.requestTabSwitch(to: .home)
    }
}
