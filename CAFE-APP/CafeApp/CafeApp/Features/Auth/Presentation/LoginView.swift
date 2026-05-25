import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showPassword = false
    var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Warm background gradient
            Color.cream.ignoresSafeArea()
            RadialGradient(
                colors: [Color.amberSoft, Color.amberSoft.opacity(0)],
                center: .init(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            // Steam decoration
            SteamDecoration()
                .frame(width: 100, height: 100)
                .position(x: UIScreen.main.bounds.width - 50, y: 120)
                .opacity(0.22)

            ScrollView {
                VStack(spacing: 0) {
                    // Logo + wordmark
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .stroke(Color.espresso.opacity(0.18), lineWidth: 0.5)
                                .frame(width: 84, height: 84)
                            Circle()
                                .fill(Color.espresso)
                                .frame(width: 72, height: 72)
                                .shadow(color: Color.espresso.opacity(0.25), radius: 15, y: 14)
                            Text("M&C")
                                .font(.serif(24))
                                .foregroundStyle(Color.cream)
                        }
                        VStack(spacing: 8) {
                            Text("Welcome back.")
                                .font(.serif(36))
                                .foregroundStyle(Color.espresso)
                            Text("Sign in to pre-order, skip the line,\nand earn points on every cup.")
                                .font(.sans(14))
                                .foregroundStyle(Color.bark)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.top, 120)
                    .padding(.bottom, 64)

                    // Fields + actions
                    VStack(spacing: 14) {
                        // Email
                        FloatingLabelField(label: "Email") {
                            TextField("", text: $email)
                                .font(.sans(16))
                                .foregroundStyle(Color.espresso)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } icon: {
                            Image(systemName: "envelope")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(Color.inkMuted)
                        }

                        // Password
                        FloatingLabelField(label: "Password") {
                            Group {
                                if showPassword {
                                    TextField("", text: $password)
                                } else {
                                    SecureField("", text: $password)
                                }
                            }
                            .font(.sans(16))
                            .foregroundStyle(Color.espresso)
                            .textContentType(.password)
                        } icon: {
                            Image(systemName: "lock")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(Color.inkMuted)
                        } trailing: {
                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundStyle(Color.inkMuted)
                            }
                        }

                        HStack {
                            Spacer()
                            Button("Forgot password?") {}
                                .font(.sans(12.5, weight: .semibold))
                                .foregroundStyle(Color.terra)
                        }
                        .padding(.top, -4)

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.sans(13))
                                .foregroundStyle(Color.cafeRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        // Sign In CTA
                        Button {
                            Task { await viewModel.signIn(email: email, password: password) }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(Color.cream)
                                } else {
                                    Text("Sign in")
                                }
                            }
                        }
                        .buttonStyle(CTAButtonStyle())
                        .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                        .padding(.top, 18)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle().frame(height: 0.5).foregroundStyle(Color.cardBorder)
                            Text("OR")
                                .font(.mono(10.5))
                                .foregroundStyle(Color.inkMuted)
                                .tracking(1.4)
                            Rectangle().frame(height: 0.5).foregroundStyle(Color.cardBorder)
                        }
                        .padding(.vertical, 8)

                        // Create account
                        Button { showRegister = true } label: {
                            HStack(spacing: 6) {
                                Text("New here?").foregroundStyle(Color.bark)
                                Text("Create account").foregroundStyle(Color.terra).fontWeight(.bold)
                            }
                            .font(.sans(13.5))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(viewModel: viewModel)
        }
    }
}

// MARK: - FloatingLabelField

private struct FloatingLabelField<Content: View, Icon: View, Trailing: View>: View {
    let label: String
    @ViewBuilder let content: Content
    @ViewBuilder let icon: Icon
    @ViewBuilder var trailing: Trailing

    init(
        label: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.label = label
        self.content = content()
        self.icon = icon()
        self.trailing = trailing()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.mono(10, weight: .regular))
                .foregroundStyle(Color.bark)
                .tracking(1.4)
                .textCase(.uppercase)
            HStack(spacing: 10) {
                icon
                content
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
    }
}

// MARK: - Steam decoration

private struct SteamDecoration: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            for i in 0..<3 {
                let x = w * (0.2 + 0.3 * Double(i))
                var path = Path()
                path.move(to: CGPoint(x: x, y: h))
                path.addCurve(
                    to: CGPoint(x: x, y: 0),
                    control1: CGPoint(x: x - 12, y: h * 0.65),
                    control2: CGPoint(x: x + 12, y: h * 0.35)
                )
                ctx.stroke(path, with: .color(Color.bark), lineWidth: 1.4)
            }
        }
    }
}
