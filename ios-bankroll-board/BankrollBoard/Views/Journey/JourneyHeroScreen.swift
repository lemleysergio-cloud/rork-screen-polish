//
//  JourneyHeroScreen.swift
//  BankrollBoard
//
//  Journey hero: completion counter, serif title, state picker, five-slot orbit,
//  and the money summary row.
//

import SwiftUI

struct JourneyHeroScreen: View {
    @StateObject private var viewModel = JourneyOrbitViewModel(
        selectedState: .MI,
        progressByOperator: [:]
    )
    @State private var showingStatePicker = false
    @State private var selectedCasino: JourneyCasino?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas, Color(rgb: 0x132F20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                    JourneyOrbitView(viewModel: viewModel) { casino in
                        selectedCasino = casino
                    }
                    .padding(.top, 8)

                    Divider()
                        .overlay(Color.white.opacity(0.18))
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    summary
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                }
            }
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
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(JourneyPalette.gold.opacity(0.35), lineWidth: 1.5)
                    .background(Circle().fill(Color(rgb: 0x193424)))
                    .shadow(color: JourneyPalette.gold.opacity(0.12), radius: 12)
                VStack(spacing: 2) {
                    Text("\(viewModel.completedCount)")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundColor(Color(rgb: 0xF4E8B2))
                    Text("/\(viewModel.casinos.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(JourneyPalette.muted)
                }
            }
            .frame(width: 72, height: 72)
            .accessibilityLabel("\(viewModel.completedCount) of \(viewModel.casinos.count) offers complete in \(viewModel.selectedState.displayName)")

            VStack(alignment: .leading, spacing: 1) {
                Text("OFFER MAP")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(JourneyPalette.gold)
                Text("Journey")
                    .font(.system(size: 48, weight: .regular, design: .serif))
                    .foregroundColor(JourneyPalette.ink)
                Text("Compare the money before you start")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(JourneyPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            Spacer(minLength: 5)

            Button {
                showingStatePicker = true
            } label: {
                HStack(spacing: 10) {
                    Text(viewModel.selectedState.displayName)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(JourneyPalette.ink)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(rgb: 0x191D23)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(JourneyPalette.gold.opacity(0.42), lineWidth: 1.2))
            }
            .accessibilityLabel("Choose bonus state, currently \(viewModel.selectedState.displayName)")
        }
    }

    private var summary: some View {
        HStack(spacing: 0) {
            summaryColumn("VERIFIED NET\nPROFIT", value: "$0", note: "Matched deposit and payout", valueColor: JourneyPalette.success)
            divider
            summaryColumn("REMAINING\nOPPORTUNITY", value: "$194", note: "Estimate, not guaranteed", valueColor: JourneyPalette.ink)
            divider
            summaryColumn("\(viewModel.selectedState.displayName.uppercased()) OFFERS\nCOMPLETE", value: "\(viewModel.completedCount)/\(viewModel.casinos.count)", note: "Completed across all states", valueColor: JourneyPalette.ink)
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
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundColor(valueColor)
            Text(note)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(JourneyPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func offerPreview(_ casino: JourneyCasino) -> some View {
        NavigationView {
            ZStack {
                JourneyPalette.panel.ignoresSafeArea()
                VStack(spacing: 16) {
                    JourneyCasinoPreviewLogo(casino: casino)
                        .frame(width: 82, height: 82)
                    Text(casino.name)
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundColor(JourneyPalette.ink)
                    Text("Connect this preview to your real Journey offer detail model and actions.")
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

struct JourneyHeroScreen_Previews: PreviewProvider {
    static var previews: some View {
        JourneyHeroScreen()
            .previewDevice("iPhone 15 Pro")
    }
}
