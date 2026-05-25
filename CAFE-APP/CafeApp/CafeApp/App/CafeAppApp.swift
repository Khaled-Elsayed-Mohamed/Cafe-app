import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct CafeAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var container: DependencyContainer
    @State private var currentUser: AuthUser?

    init() {
        FirebaseApp.configure()
        let useEmulator = ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1"
        _container = State(initialValue: DependencyContainer.live(useEmulator: useEmulator))
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container, currentUser: $currentUser)
                .task {
                    for await user in container.authRepository.observeAuthState() {
                        currentUser = user
                        if let user, user.role == .customer,
                           let notifRepo = container.notificationRepository {
                            _ = try? await notifRepo.requestPermission()
                        }
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .orderReadyDeepLink)
                ) { note in
                    appDelegate.pendingOrderId = note.userInfo?["orderId"] as? String
                }
        }
    }
}

// MARK: - App Delegate (APNs token + notification deep-link)

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var pendingOrderId: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationCenter.default.post(
            name: .apnsTokenReceived,
            object: nil,
            userInfo: ["token": deviceToken]
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let orderId = userInfo["orderId"] as? String {
            NotificationCenter.default.post(
                name: .orderReadyDeepLink,
                object: nil,
                userInfo: ["orderId": orderId]
            )
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

extension Notification.Name {
    static let apnsTokenReceived = Notification.Name("apnsTokenReceived")
    static let orderReadyDeepLink = Notification.Name("orderReadyDeepLink")
}

// MARK: - Root View

struct RootView: View {
    let container: DependencyContainer
    @Binding var currentUser: AuthUser?
    @State private var ownerCustomerMode = false

    var body: some View {
        Group {
            if let user = currentUser {
                switch user.role {
                case .customer:
                    CustomerTabView(container: container, user: user)
                case .worker:
                    WorkerDashboardView(
                        viewModel: WorkerOrderViewModel(
                            fulfillOrderUseCase: FulfillOrderUseCase(
                                repository: container.workerOrderRepository
                            ),
                            repository: container.workerOrderRepository
                        )
                    )
                case .owner:
                    if ownerCustomerMode {
                        CustomerTabView(container: container, user: user)
                            .overlay(alignment: .bottom) {
                                Button(action: { ownerCustomerMode = false }) {
                                    Label("Back to Owner View", systemImage: "arrow.uturn.backward")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                        .shadow(radius: 4)
                                }
                                .padding(.bottom, 90)
                            }
                    } else {
                        OwnerDashboardView(
                            workerOrderViewModel: WorkerOrderViewModel(
                                fulfillOrderUseCase: FulfillOrderUseCase(
                                    repository: container.workerOrderRepository
                                ),
                                repository: container.workerOrderRepository
                            ),
                            menuRepository: container.menuRepository,
                            onSignOut: { try? await container.authRepository.signOut() },
                            onSwitchToCustomer: { ownerCustomerMode = true }
                        )
                    }
                }
            } else {
                LoginView(
                    viewModel: AuthViewModel(repository: container.authRepository)
                )
            }
        }
    }
}

// MARK: - Customer Tab View

struct CustomerTabView: View {
    let container: DependencyContainer
    let user: AuthUser

    @State private var orderViewModel: OrderViewModel?
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if let orderVM = orderViewModel {
                TabView(selection: $selectedTab) {
                    MenuView(
                        viewModel: MenuViewModel(
                            menuRepository: container.menuRepository,
                            networkMonitor: container.networkMonitorRepository,
                            cafeConfigRepository: container.cafeConfigRepository
                        ),
                        orderViewModel: orderVM,
                        selectedTab: $selectedTab
                    )
                    .tabItem { Label("Menu", systemImage: "cup.and.saucer") }
                    .tag(0)

                    CartView(orderViewModel: orderVM)
                        .tabItem { Label("Cart", systemImage: "cart") }
                        .tag(1)

                    if let loyaltyRepo = container.loyaltyRepository {
                        ProfileView(
                            viewModel: LoyaltyViewModel(repository: loyaltyRepo),
                            currentUser: user,
                            onSignOut: { try? await container.authRepository.signOut() }
                        )
                        .tabItem { Label("Profile", systemImage: "person.circle") }
                        .tag(2)
                    }
                }
            } else {
                ProgressView()
                    .onAppear { buildOrderViewModel() }
            }
        }
        .task {
            if orderViewModel == nil { buildOrderViewModel() }
            await registerNotifications()
        }
    }

    private func buildOrderViewModel() {
        orderViewModel = OrderViewModel(
            placeOrderUseCase: PlaceOrderUseCase(
                paymentRepository: container.paymentRepository,
                orderRepository: container.orderRepository,
                cafeConfigRepository: container.cafeConfigRepository
            ),
            orderRepository: container.orderRepository,
            cafeConfigRepository: container.cafeConfigRepository,
            currentUser: user
        )
    }

    private func registerNotifications() async {
        guard let notifRepo = container.notificationRepository else { return }
        let useCase = RegisterNotificationUseCase(repository: notifRepo)
        _ = try? await notifRepo.requestPermission()

        // Listen for APNs token and register with FCM
        for await note in NotificationCenter.default.notifications(named: .apnsTokenReceived) {
            if let token = note.userInfo?["token"] as? Data {
                await useCase.execute(token: token, userId: user.id)
                break
            }
        }
    }
}
