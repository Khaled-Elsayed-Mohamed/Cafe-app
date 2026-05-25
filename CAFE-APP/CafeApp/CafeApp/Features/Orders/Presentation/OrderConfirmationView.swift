import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @State var orderViewModel: OrderViewModel
    @State private var showTracking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Order Placed!")
                        .font(.title.bold())
                    Text("Order #\(order.id.prefix(8).uppercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready by")
                        .font(.headline)
                    Text(order.requestedReadyTime, style: .time)
                        .font(.title3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Items").font(.headline)
                    ForEach(Array(order.items.enumerated()), id: \.offset) { _, item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.subheadline)
                                if let size = item.size {
                                    Text(size).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.price, format: .currency(code: "USD"))
                                .font(.subheadline)
                        }
                    }
                    Divider()
                    HStack {
                        Text("Total").fontWeight(.semibold)
                        Spacer()
                        Text(order.totalAmount, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Image(systemName: "star.circle.fill").foregroundStyle(.yellow)
                    Text("+\(order.totalPointsEarned) points earned")
                        .font(.subheadline)
                }

                Button(action: { showTracking = true }) {
                    Label("Track Order", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $showTracking) {
            OrderTrackingView(order: order, orderViewModel: orderViewModel)
        }
    }
}
