import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    var viewModel: AuthViewModel

    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && confirmPassword != password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.amberSoft, Color.amberSoft.opacity(0)],
                    center: .init(x: 0.5, y: 0),
                    startRadius: 0,
                    endRadius: 240
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Create account")
                                .font(.serif(34))
                                .foregroundStyle(Color.espresso)
                            Text("Join Macchiato & Co loyalty rewards.")
                                .font(.sans(14))
                                .foregroundStyle(Color.bark)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                        .padding(.bottom, 36)

                        VStack(spacing: 14) {
                            regField("Full Name", text: $displayName, icon: "person", content: .name)
                            regField("Email", text: $email, icon: "envelope", content: .emailAddress, keyboard: .emailAddress)
                            regField("Password", text: $password, icon: "lock", content: .newPassword, secure: true)
                            regField("Confirm Password", text: $confirmPassword, icon: "lock", content: .newPassword, secure: true)

                            if passwordMismatch {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle")
                                    Text("Passwords do not match.")
                                }
                                .font(.sans(13))
                                .foregroundStyle(Color.cafeRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            }

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.sans(13))
                                    .foregroundStyle(Color.cafeRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }

                            Button {
                                Task {
                                    await viewModel.signUp(email: email, password: password, displayName: displayName)
                                    if viewModel.currentUser != nil { dismiss() }
                                }
                            } label: {
                                Group {
                                    if viewModel.isLoading { ProgressView().tint(Color.cream) }
                                    else { Text("Create account") }
                                }
                            }
                            .buttonStyle(CTAButtonStyle())
                            .disabled(
                                displayName.isEmpty || email.isEmpty ||
                                password.count < 6 || passwordMismatch || viewModel.isLoading
                            )
                            .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.terra)
                }
            }
        }
    }

    @ViewBuilder
    private func regField(
        _ label: String,
        text: Binding<String>,
        icon: String,
        content: TextContentType,
        keyboard: UIKeyboardType = .default,
        secure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.mono(10, weight: .regular))
                .foregroundStyle(Color.bark)
                .tracking(1.4)
                .textCase(.uppercase)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color.inkMuted)
                if secure {
                    SecureField("", text: text)
                        .font(.sans(16))
                        .foregroundStyle(Color.espresso)
                        .textContentType(content)
                } else {
                    TextField("", text: text)
                        .font(.sans(16))
                        .foregroundStyle(Color.espresso)
                        .textContentType(content)
                        .keyboardType(keyboard)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(content == .emailAddress ? .never : .words)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
    }
}

private typealias TextContentType = UITextContentType
