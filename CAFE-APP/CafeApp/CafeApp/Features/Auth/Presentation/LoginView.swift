import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Sign In") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
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
                        Task { await viewModel.signIn(email: email, password: password) }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)

                    Button("Create Account") {
                        showRegister = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Café App")
            .sheet(isPresented: $showRegister) {
                RegisterView(viewModel: viewModel)
            }
        }
    }
}
