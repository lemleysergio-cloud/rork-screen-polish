//
//  JourneyView.swift
//  BankrollBoard
//

import SwiftUI
import UIKit

/// The Journey screen: spatial orbit selector with a tumbling die on top,
/// money board, stamp collection, and the offer trail below.
struct JourneyView: View {
    @State private var model = JourneyViewModel()
    @State private var selectedTab: BBTab = .journey

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    JourneyHeaderView(
                        completed: model.money.completedInRegion,
                        total: model.money.totalInRegion,
                        regionName: model.region.name,
                        onChooseRegion: { model.isRegionPickerPresented = true }
                    )
                    // Clears the status bar clock, Dynamic Island, and battery icons.
                    .padding(.top, 38)

                    JourneyRingOrbitView(
                        offers: model.offers,
                        phase: model.orbitPhase,
                        focusIndex: model.focusIndex,
                        rollToken: model.rollToken,
                        rankCaption: model.focusRankCaption,
                        onDragChange: { model.dragProgress = model.clampedDrag($0) },
                        onDragEnd: {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                model.commitDrag()
                            }
                        },
                        onNodeTap: { model.focus(on: $0) },
                        onRoll: {
                            Haptics.tap()
                            model.rollDie()
                        },
                        onDieLand: { face in
                            Haptics.selection()
                            model.dieLanded(on: face)
                        }
                    )
                    .padding(.top, 6)

                    JourneyMoneyBoard(money: model.money, regionName: model.region.name)
                        .padding(.top, 34)

                    JourneyStampsView(stamps: model.stamps, earnedCount: model.earnedStampCount)
                        .padding(.top, 34)

                    Divider()
                        .overlay(BBTheme.hairline.opacity(0.6))
                        .padding(.horizontal, BBTheme.screenMargin)
                        .padding(.top, 34)

                    JourneyTrailView(
                        offers: model.trailOffers,
                        filter: model.filter,
                        caption: model.trailCaption,
                        onSelectFilter: { model.select(filter: $0) },
                        onOpenOffer: { model.selectedOfferID = $0 }
                    )
                    .padding(.top, 28)

                    responsibleGaming
                        .padding(.top, 26)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            BBTabBar(selection: $selectedTab)
                .padding(.bottom, 6)
        }
        .bbCanvasBackground()
        .preferredColorScheme(.dark)
        .sheet(isPresented: Binding(
            get: { model.isRegionPickerPresented },
            set: { model.isRegionPickerPresented = $0 }
        )) {
            JourneyRegionPicker(
                regions: JourneyContent.regions,
                selectedID: model.regionCode,
                onSelect: { code in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        model.selectRegion(code)
                    }
                },
                onCancel: { model.isRegionPickerPresented = false }
            )
        }
        .sheet(item: Binding(
            get: { model.selectedOffer },
            set: { if $0 == nil { model.selectedOfferID = nil } }
        )) { offer in
            JourneyOfferSheet(offer: offer, onOpenOfficial: open)
        }
    }

    /// Responsible-gaming block, wording preserved from the web build.
    private var responsibleGaming: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play within your means.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(rgb: 0xD6DDD1))

            Text("Must be 21+ and physically in \(model.region.name). If gambling stops being fun, pause your Journey and call 1-800-GAMBLER.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                secondaryLink(title: "Help resources", url: model.region.helpURL)
                secondaryLink(title: "Call 1-800-GAMBLER", url: "tel:18004262537")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 22)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.55))
                .frame(height: 1)
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    private func secondaryLink(title: String, url: String) -> some View {
        Button(action: {
            Haptics.tap()
            open(url)
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BBTheme.gold)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                }
        }
        .buttonStyle(BBPressStyle())
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Item-driven sheet helper so an optional value can present a sheet.
private extension View {
    func sheet<Item: Identifiable & Equatable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(isPresented: Binding(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )) {
            if let value = item.wrappedValue {
                content(value)
            }
        }
    }
}

#Preview {
    JourneyView()
}
