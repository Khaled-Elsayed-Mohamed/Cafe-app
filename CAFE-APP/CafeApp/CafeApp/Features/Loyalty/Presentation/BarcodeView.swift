import SwiftUI
import CoreImage.CIFilterBuiltins

struct BarcodeView: View {
    let membershipBarcode: String

    var body: some View {
        VStack(spacing: 24) {
            if let image = generateQRCode(from: membershipBarcode) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 4)
            }

            VStack(spacing: 4) {
                Text("Membership Card")
                    .font(.headline)
                Text("Show this code at the counter to earn points in-store")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .navigationTitle("Membership Card")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return UIImage(ciImage: scaled)
    }
}
