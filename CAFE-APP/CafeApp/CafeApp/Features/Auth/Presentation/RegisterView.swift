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
            Form {
                Section("Account Details") {
                    TextField("Full Name", text: $displayName)
                        .textContentType(.name)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Password") {
                    SecureField("Password (6+ characters)", text: $password)
                        .textContentType(.newPassword)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)

                    if passwordMismatch {
                        Text("Passwords do not match.")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button(action: {
                        Task {
                            await viewModel.signUp(
                                email: email,
                                password: password,
                                displayName: displayName
                            )
                            if viewModel.currentUser != nil { dismiss() }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(
                        displayName.isEmpty || email.isEmpty ||
                        password.count < 6 || passwordMismatch || viewModel.isLoading
                    )
                }
            }
            .navigationTitle("Create Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
