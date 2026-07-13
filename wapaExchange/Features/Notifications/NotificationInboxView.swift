import SwiftUI

struct NotificationInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = NotificationInboxViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.items) { notification in
                    Button {
                        Task { await vm.markRead(notification) }
                    } label: {
                        NotificationRow(notification: notification)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .overlay {
                if vm.items.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "Nothing yet",
                        systemImage: "bell.slash",
                        description: Text("Updates about your transfers will show up here.")
                    )
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.brand.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(AppColors.brand)
                }
                if notification.isUnread {
                    Circle()
                        .fill(AppColors.brand)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(notification.isUnread ? AppTypography.bodyBold() : AppTypography.body())
                    .foregroundStyle(AppColors.textPrimary)
                Text(notification.body)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                Text(notification.createdAt.formatted(.relative(presentation: .named)))
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, 2)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch notification.template {
        case "payout_complete": "checkmark.seal.fill"
        case "forwarded": "paperplane.fill"
        case "kyc_approved": "person.crop.circle.badge.checkmark"
        default: "bell.fill"
        }
    }
}
