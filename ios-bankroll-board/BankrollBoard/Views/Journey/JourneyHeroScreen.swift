//
//  JourneyHeroScreen.swift
//  BankrollBoard
//
//  Journey hero: completion counter, serif title, state picker, five-slot orbit,
//  money summary, stamp collection, offer trail, and responsible-gaming footer.
//

import SwiftUI
import UIKit

struct JourneyHeroScreen: View {
    @StateObject private var viewModel = JourneyOrbitViewModel(
        selectedState: .MI,
        progressByOperator: [:]
    )
    /// Drives the sections below the hero: stamps, offer trail, and help links.
    @State private var trail = JourneyViewModel()
    @State private var showingStatePicker = false
    @State private var selectedCasino: JourneyCasino?

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas, Color(rgb: 0x132F20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 10)

                    JourneyOrbitView(viewModel: viewModel) { casino in
                        selectedCasino = casino
                    }
                    .padding(.top, 4)

                    Divider()
                        .overlay(Color.white.opacity(0.18))
                        .padding(.horizontal, 18)

                    summary
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)

                    JourneyStampsView(stamps: trail.stamps, earnedCount: trail.earnedStampCount)
                        .padding(.top, 12)

                    Divider()
                        .overlay(Color.white.opacity(0.18))
                        .padding(.horizontal, 18)
                        .padding(.top, 34)

                    JourneyTrailView(
                        offers: trail.trailOffers,
                        filter: trail.filter,
                        caption: trail.trailCaption,
                        onSelectFilter: { trail.select(filter: $0) },
                        onOpenOffer: { trail.selectedOfferID = $0 }
                    )
                    .padding(.top, 28)

                    responsibleGaming
                        .padding(.top, 26)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("journey.page")
        }
        .onChange(of: viewModel.selectedState) { _, newValue in
            trail.selectRegion(newValue.rawValue)
        }
        .confirmationDialog(
            "Choose your state",
            isPresented: $showingStatePicker,
            titleVisibility: .visible
        ) {
            ForEach(JourneyStateCode.allCases) { state in
                Button(state.displayName) {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        viewModel.selectState(state)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Browse bonuses where you can play. This choice does not verify your location. One signup bonus per casino, across all states.")
        }
        .sheet(item: $selectedCasino) { casino in
            offerPreview(casino)
        }
        .sheet(item: Binding(
            get: { trail.selectedOffer },
            set: { if $0 == nil { trail.selectedOfferID = nil } }
        )) { offer in
            JourneyOfferSheet(offer: offer, onOpenOfficial: open)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    /// Two rows so the serif title always gets the full screen width.
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Text("OFFER MAP")
                    .font(.system(size: 11, weight: .black))
                    .kerning(1.4)
                    .foregroundColor(JourneyPalette.gold)

                Spacer(minLength: 8)

                stateButton
            }
            // Clears the status bar clock and Dynamic Island.
            .padding(.top, 34)

            HStack(alignment: .center, spacing: 16) {
                counter

                VStack(alignment: .leading, spacing: 1) {
                    Text("Journey")
                        .font(.system(size: 44, weight: .regular, design: .serif))
                        .foregroundColor(JourneyPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Compare the money before you start")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(JourneyPalette.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var counter: some View {
        ZStack {
            Circle()
                .stroke(JourneyPalette.gold.opacity(0.35), lineWidth: 1.5)
                .background(Circle().fill(Color(rgb: 0x193424)))
                .shadow(color: JourneyPalette.gold.opacity(0.12), radius: 12)
            VStack(spacing: 2) {
                Text("\(viewModel.completedCount)")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundColor(Color(rgb: 0xF4E8B2))
                Text("/\(viewModel.casinos.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(JourneyPalette.muted)
            }
        }
        .frame(width: 68, height: 68)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.completedCount) of \(viewModel.casinos.count) offers complete in \(viewModel.selectedState.displayName)")
    }

    private var stateButton: some View {
        Button {
            showingStatePicker = true
        } label: {
            HStack(spacing: 8) {
                Text(viewModel.selectedState.displayName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(JourneyPalette.ink)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(rgb: 0x191D23)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(JourneyPalette.gold.opacity(0.42), lineWidth: 1.2))
        }
        .accessibilityLabel("Choose bonus state, currently \(viewModel.selectedState.displayName)")
        .accessibilityIdentifier("journey.statePicker")
    }

    // MARK: - Summary

    private var summary: some View {
        HStack(spacing: 0) {
            summaryColumn(
                "VERIFIED NET\nPROFIT",
                value: "$\(trail.money.verifiedNetProfit)",
                note: "Matched deposit and payout",
                valueColor: JourneyPalette.success
            )
            divider
            summaryColumn(
                "REMAINING\nOPPORTUNITY",
                value: "$\(trail.money.remainingOpportunity)",
                note: "Estimate, not guaranteed",
                valueColor: JourneyPalette.ink
            )
            divider
            summaryColumn(
                "\(viewModel.selectedState.displayName.uppercased()) OFFERS\nCOMPLETE",
                value: "\(viewModel.completedCount)/\(viewModel.casinos.count)",
                note: "Completed across all states",
                valueColor: JourneyPalette.ink
            )
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.13))
            .frame(width: 1, height: 118)
            .padding(.horizontal, 12)
    }

    private func summaryColumn(_ title: String, value: String, note: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(JourneyPalette.muted)
            Text(value)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(note)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(JourneyPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var responsibleGaming: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play within your means.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(rgb: 0xD6DDD1))

            Text("Must be 21+ and physically in \(viewModel.selectedState.displayName). If gambling stops being fun, pause your Journey and call 1-800-GAMBLER.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                secondaryLink(title: "Help resources", url: trail.region.helpURL)
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
        Button {
            Haptics.tap()
            open(url)
        } label: {
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

    private func offerPreview(_ casino: JourneyCasino) -> some View {
        NavigationStack {
            ZStack {
                JourneyPalette.panel.ignoresSafeArea()
                VStack(spacing: 16) {
                    JourneyCasinoPreviewLogo(casino: casino)
                        .frame(width: 82, height: 82)
                    Text(casino.name)
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundColor(JourneyPalette.ink)
                        .multilineTextAlignment(.center)
                    Text("Full offer terms for this casino open from the offer trail below.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(JourneyPalette.muted)
                    Spacer()
                }
                .padding(28)
            }
            .navigationTitle("Offer Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
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

private struct JourneyCasinoPreviewLogo: View {
    let casino: JourneyCasino

    var body: some View {
        ZStack {
            Circle().fill(Color(rgb: 0xF5F3EB))
            if let name = casino.logoAssetName, let image = UIImage(named: name) {
                Image(uiImage: image).resizable().scaledToFit().padding(6)
            } else {
                Text(String(casino.name.prefix(2)).uppercased())
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color(rgb: casino.brandColorHex))
            }
        }
    }
}

#Preview {
    JourneyHeroScreen()
}
