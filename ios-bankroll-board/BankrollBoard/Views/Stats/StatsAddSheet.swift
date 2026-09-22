//
//  StatsAddSheet.swift
//  BankrollBoard
//
//  Sheet for logging a transaction by hand: direction toggle, platform picker,
//  amount, date, and an optional note. Saving goes through StatsDataSource so
//  manual entries mix cleanly with bank transfers.
//

import SwiftUI

struct StatsAddSheet: View {
    let model: StatsViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var direction: TransferDirection = .deposit
    @State private var casinoId: String = HomeCasino.all[0].id
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""

    private var amountCents: Int? {
        let cleaned = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value > 0, value < 10_000_000 else { return nil }
        return Int((value * 100).rounded())
    }

    private var canSave: Bool { amountCents != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    directionToggle

                    fieldLabel("Platform")
                        .padding(.top, 22)
                    platformPicker
                        .padding(.top, 9)

                    fieldLabel("Amount")
                        .padding(.top, 20)
                    amountField
                        .padding(.top, 9)

                    fieldLabel("Date")
                        .padding(.top, 20)
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BBTheme.surface.opacity(0.7))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(BBTheme.hairline.opacity(0.7), lineWidth: 1)
                                }
                        }
                        .padding(.top, 9)

                    fieldLabel("Note (optional)")
                        .padding(.top, 20)
                    noteField
                        .padding(.top, 9)

                    saveButton
                        .padding(.top, 28)

                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(BBTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(BBPressStyle())
                    .accessibilityLabel("Cancel adding transaction")
                    .padding(.top, 6)
                }
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Add transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("stats.addSheet")
    }

    // MARK: - Fields

    private var directionToggle: some View {
        HStack(spacing: 10) {
            directionButton(
                title: "Deposit",
                subtitle: "Money out of the bank",
                symbol: "arrow.up.right",
                value: .deposit
            )
            directionButton(
                title: "Withdrawal",
                subtitle: "Money back to the bank",
                symbol: "arrow.down.left",
                value: .withdrawal
            )
        }
    }

    private func directionButton(
        title: String,
        subtitle: String,
        symbol: String,
        value: TransferDirection
    ) -> some View {
        let isSelected = direction == value
        return Button {
            Haptics.selection()
            direction = value
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? BBTheme.gold : BBTheme.inkMuted)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BBTheme.ink)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(BBTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? BBTheme.goldSoft : BBTheme.surface.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? BBTheme.gold : BBTheme.hairline.opacity(0.7),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    }
            }
        }
        .buttonStyle(BBPressStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var platformPicker: some View {
        Menu {
            ForEach(HomeCasino.all) { casino in
                Button {
                    Haptics.selection()
                    casinoId = casino.id
                } label: {
                    if casino.id == casinoId {
                        Label(casino.name, systemImage: "checkmark")
                    } else {
                        Text(casino.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                HomeCasinoMark(casinoId: casinoId, size: 34)

                Text(HomeCasino.name(for: casinoId))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BBTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBTheme.inkMuted)
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BBTheme.surface.opacity(0.7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BBTheme.hairline.opacity(0.7), lineWidth: 1)
                    }
            }
        }
        .accessibilityLabel("Platform, \(HomeCasino.name(for: casinoId))")
    }

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("$")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(BBTheme.inkMuted)

            TextField("0.00", text: $amountText)
                .font(.system(size: 22, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(BBTheme.ink)
                .keyboardType(.decimalPad)
                .accessibilityLabel("Amount in dollars")
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BBTheme.surface.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            amountText.isEmpty ? BBTheme.hairline.opacity(0.7) : BBTheme.gold.opacity(0.4),
                            lineWidth: 1
                        )
                }
        }
    }

    private var noteField: some View {
        TextField("e.g. Blackjack session, slots, parlay", text: $note)
            .font(.system(size: 14))
            .foregroundStyle(BBTheme.ink)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BBTheme.surface.opacity(0.7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BBTheme.hairline.opacity(0.7), lineWidth: 1)
                    }
            }
    }

    private var saveButton: some View {
        Button {
            guard let amountCents else { return }
            let draft = StatsDraft(
                direction: direction,
                casinoId: casinoId,
                amountCents: amountCents,
                date: date,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            Task {
                await model.add(draft)
                dismiss()
            }
        } label: {
            Text("Save transaction")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(canSave ? BBTheme.canvasDeep : BBTheme.inkMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(canSave ? BBTheme.gold : BBTheme.surfaceRaised)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(canSave ? Color.clear : BBTheme.hairline, lineWidth: 1)
                        }
                }
        }
        .buttonStyle(BBPressStyle())
        .disabled(!canSave)
        .animation(.easeOut(duration: 0.2), value: canSave)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .kerning(1.1)
            .foregroundStyle(BBTheme.inkMuted)
    }
}
