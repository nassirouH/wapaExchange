import SwiftUI

struct StatusPill: View {
    let status: TransferStatus

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
    }
}
