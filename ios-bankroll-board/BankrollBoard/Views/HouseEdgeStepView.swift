//
//  HouseEdgeStepView.swift
//  BankrollBoard
//

import SwiftUI

/// Practice round 2 of 2 — see how the house edge adds up across a session.
struct HouseEdgeStepView: View {
    let items: [HouseEdgeItem]
    let selectedID: String
    let betSize: Double
    let bets: Double
    let totalWagered: Double
    let expectedCost: Double
    let onSelect: (String) -> Void
    let onBetSizeChange: (Double) -> Void
    let onBetsChange: (Double) -> Void
    let onFinish: () -> Void

    private var selectedItem: HouseEdgeItem {
        items.first { $0.id == selectedID } ?? items[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    BBHeadlineBlock(
                        eyebrow: "Practice round · 2 of 2",
                        title: "See how the house edge adds up.",
                        prompt: "House edge is the casino's average advantage on each bet. Pick a game and adjust the session to see the effect."
                    )

                    VStack(alignment: .leading, spacing: 18) {
                        BBDisclaimerBadge(text: "Illustrative example · not a real offer or forecast")

                        resultCard

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Explore a game or bet")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(BBTheme.ink)

                            VStack(spacing: 10) {
                                ForEach(items) { item in
                                    HouseEdgeRow(
                                        item: item,
                                        isSelected: item.id == selectedID
                                    ) {
                                        onSelect(item.id)
                                    }
                                }
                            }
                        }

                        BBFootnote(
                            text: "Averages describe many bets over time, not any single session. Results vary widely."
                        )
                    }
                    .padding(.horizontal, BBTheme.screenMargin)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            footer
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedItem.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BBTheme.gold)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(expectedCost, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(BBTheme.headline(42))
                        .foregroundStyle(BBTheme.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("average expected cost")
                        .font(.system(size: 13))
                        .foregroundStyle(BBTheme.inkMuted)
                }

                Text("On \(Int(bets)) bets totalling \(totalWagered, format: .currency(code: "USD").precision(.fractionLength(0))) wagered at ≈\(selectedItem.edge, specifier: "%.2f")% house edge.")
                    .font(BBTheme.caption)
                    .foregroundStyle(BBTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                SliderRow(
                    label: "Bet size",
                    value: betSize.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                    binding: Binding(get: { betSize }, set: onBetSizeChange),
                    range: 1...100,
                    step: 1
                )

                SliderRow(
                    label: "Bets this session",
                    value: "\(Int(bets))",
                    binding: Binding(get: { bets }, set: onBetsChange),
                    range: 20...500,
                    step: 10
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                .fill(BBTheme.surfaceRaised)
                .overlay {
                    RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                        .fill(BBTheme.goldSoft)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                        .stroke(BBTheme.gold.opacity(0.55), lineWidth: 1.2)
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: expectedCost)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.5))
                .frame(height: 1)

            BBPrimaryButton(title: "Open my board", isEnabled: true, action: onFinish)
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.top, 14)
                .padding(.bottom, 6)
        }
        .background(BBTheme.canvasDeep.opacity(0.92))
    }
}

/// Labeled slider used to tune the practice session.
private struct SliderRow: View {
    let label: String
    let value: String
    let binding: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(BBTheme.inkMuted)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(BBTheme.ink)
            }

            Slider(value: binding, in: range, step: step)
                .tint(BBTheme.gold)
                .sensoryFeedback(.selection, trigger: binding.wrappedValue)
                .accessibilityLabel(label)
        }
    }
}

/// Selectable game/bet row with its house edge.
private struct HouseEdgeRow: View {
    let item: HouseEdgeItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BBTheme.ink)
                    Text(item.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(BBTheme.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("≈\(item.edge, specifier: "%.2f")%")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(BBTheme.gold)

                BBSelectionIndicator(isSelected: isSelected, isSquare: false)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? BBTheme.surfaceRaised : BBTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? BBTheme.gold : BBTheme.hairline.opacity(0.55),
                                lineWidth: isSelected ? 1.6 : 1
                            )
                    }
            }
        }
        .buttonStyle(BBPressStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    HouseEdgeStepView(
        items: OnboardingContent.houseEdgeItems,
        selectedID: "blackjack",
        betSize: 10,
        bets: 100,
        totalWagered: 1000,
        expectedCost: 2.8,
        onSelect: { _ in },
        onBetSizeChange: { _ in },
        onBetsChange: { _ in },
        onFinish: {}
    )
    .bbCanvasBackground()
}
