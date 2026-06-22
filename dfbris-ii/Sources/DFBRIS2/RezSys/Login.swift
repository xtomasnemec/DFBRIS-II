import SwiftUI
import SkipFuse

struct LoginPage: View {

    @State var username = ""
    @State var password = ""
    @State var rememberMe = false
    @State var showPassword = false
    @State var showMessage = false
    @State var message = ""
    @State var isLoading = false

    var body: some View {
        let loginHandler = LoginHandler.shared

        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColor("RezSysColor", fallback: .blue).opacity(0.24),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    hero(loginHandler: loginHandler)

                    if loginHandler.isLogedIn {
                        loggedInView
                    } else {
                        loginForm
                    }

                    if showMessage {
                        MessageBox(text: message, isVisible: $showMessage)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(L("Login"))
        .task {
            loadSavedCredentials()
        }
    }

    private func hero(loginHandler: LoginHandler) -> some View {
        VStack(spacing: 12) {
            Image(systemName: loginHandler.isLogedIn ? "person.crop.circle.badge.checkmark" : "key.2.on.ring.fill")
                .font(.system(size: 78, weight: .regular))
                .foregroundStyle(AppColor("RezSysColor", fallback: .blue))

            Text(L("RezSys access"))
                .font(.title)
                .bold()

            Text(loginHandler.isLogedIn ? L("You are already signed in") : L("Sign in to access reservations and account tools"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var loginForm: some View {
        VStack(spacing: 16) {
            TextField(L("Username"), text: $username)
                .autocorrectionDisabled()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)

            HStack(spacing: 8) {
                if showPassword {
                    TextField(L("Password"), text: $password)
                        .autocorrectionDisabled()
                } else {
                    SecureField(L("Password"), text: $password)
                }

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disabled(isLoading)

            Toggle(L("Remember me"), isOn: $rememberMe)
                .disabled(isLoading)

            Button(action: submitLogin) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(L("Log in"))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || username.isEmpty || password.isEmpty)
        }
        .padding()
        .background(.background.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor("RezSysColor", fallback: .orange).opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var loggedInView: some View {
        VStack(spacing: 16) {
            Text(LoginHandler.shared.displayName ?? username)
                .font(.title2)
                .bold()

            Text(L("You are logged in"))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.green.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func loadSavedCredentials() {
        let defaults = UserDefaults.standard
        let savedUsername = defaults.string(forKey: "username") ?? ""
        let savedPassword = defaults.string(forKey: "password") ?? ""

        username = savedUsername
        if defaults.bool(forKey: "remember_me") {
            password = savedPassword
            rememberMe = true
        }
    }

    private func submitLogin() {
        isLoading = true
        Task {
            let error = await LoginHandler.shared.login(
                username: username,
                password: password,
                rememberCredentials: rememberMe
            )

            await MainActor.run {
                isLoading = false
                if let error {
                    message = error
                    showMessage = true
                } else {
                    AppState.requestTabSwitch(to: .home)
                }
            }
        }
    }

}
