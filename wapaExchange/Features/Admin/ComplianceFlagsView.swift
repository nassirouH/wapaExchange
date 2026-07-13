import SwiftUI

struct ComplianceFlagsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ComplianceFlagsViewModel()
    @State private var reviewing: ComplianceFlag?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                content
            }
            .navigationTitle("Compliance flags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .sheet(item: $reviewing) { flag in
                ReviewSheet(flag: flag) { decision, note in
                    Task { _ = await vm.review(flag, decision: decision, note: note) }
                }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: AppSpacing.sm) {
            filterChip("Open", value: .open)
            filterChip("In review", value: .reviewing)
            filterChip("Cleared", value: .cleared)
            filterChip("All", value: nil)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    private func filterChip(_ title: String, value: ComplianceFlagStatus?) -> some View {
        Button {
            vm.filter = value
            Task { await vm.load() }
        } label: {
            Text(title)
                .font(AppTypography.caption())
                .foregroundStyle(vm.filter == value ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule().fill(vm.filter == value ? AppColors.brand : AppColors.secondaryBackground)
                )
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.flags.isEmpty {
            ProgressView().padding(.top, AppSpacing.xl)
            Spacer()
        } else if vm.sortedFlags.isEmpty {
            ContentUnavailableView(
                "No flags",
                systemImage: "checkmark.shield",
                description: Text("Nothing to review right now.")
            )
        } else {
            List {
                ForEach(vm.sortedFlags) { flag in
                    Button {
                        if flag.status == .open { reviewing = flag }
                    } label: {
                        FlagRow(flag: flag)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct FlagRow: View {
    let flag: ComplianceFlag

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            severityBadge
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayRule)
                        .font(AppTypography.bodyBold())
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text(flag.createdAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }
                Text(flag.reason)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                if flag.status != .open {
                    Text(flag.status.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(AppColors.tertiaryBackground))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var severityBadge: some View {
        Text(flag.severity.label.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4).fill(flag.severity.color))
            .padding(.top, 2)
    }

    private var displayRule: String {
        flag.ruleId.replacingOccurrences(of: "rule.", with: "").replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct ReviewSheet: View {
    let flag: ComplianceFlag
    let onSubmit: (ComplianceDecision, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var note: String = ""
    @State private var decision: ComplianceDecision = .cleared

    var body: some View {
        NavigationStack {
            Form {
                Section("Flag") {
                    LabeledContent("Rule", value: flag.ruleId)
                    LabeledContent("Severity", value: flag.severity.label)
                    Text(flag.reason)
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.textSecondary)
                }
                Section("Decision") {
                    Picker("Outcome", selection: $decision) {
                        Text("Clear (false positive)").tag(ComplianceDecision.cleared)
                        Text("Escalate (file STR)").tag(ComplianceDecision.escalated)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Reviewer note") {
                    TextField("Add context for audit trail", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Review flag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        onSubmit(decision, note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                }
            }
        }
    }
}

#Preview { ComplianceFlagsView() }
