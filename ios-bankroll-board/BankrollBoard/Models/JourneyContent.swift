//
//  JourneyContent.swift
//  BankrollBoard
//

import Foundation

/// Illustrative journey catalog. Swap these seeds for the live verified catalog;
/// every view reads through `JourneyContent` so the UI does not change shape.
nonisolated enum JourneyContent {
    static let regions: [JourneyRegion] = [
        JourneyRegion(id: "MI", name: "Michigan", helpURL: "https://www.michigan.gov/mgcb/detroit-casinos/responsible-gaming"),
        JourneyRegion(id: "NJ", name: "New Jersey", helpURL: "https://www.nj.gov/oag/ge/responsiblegaming.html"),
        JourneyRegion(id: "PA", name: "Pennsylvania", helpURL: "https://gamingcontrolboard.pa.gov/responsible-gaming"),
        JourneyRegion(id: "WV", name: "West Virginia", helpURL: "https://wvlottery.com/responsible-gaming/")
    ]

    static func region(_ code: String) -> JourneyRegion {
        regions.first { $0.id == code } ?? regions[0]
    }

    /// Ordered offers for a region: ranked offers first, unranked mapped offers last.
    static func offers(for regionCode: String) -> [JourneyOffer] {
        let available = seeds.filter { $0.regions.contains(regionCode) }
        let ranked = available.filter { $0.rank != nil }.sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
        let unranked = available.filter { $0.rank == nil }
        return (ranked + unranked).map(\.offer)
    }

    static func money(for regionCode: String) -> JourneyMoney {
        let offers = seeds.filter { $0.regions.contains(regionCode) }
        let completed = offers.filter { $0.state == .completed }.count
        let remaining = offers
            .filter { $0.verified && $0.state != .completed }
            .reduce(0) { $0 + $1.estimatedValue }
        return JourneyMoney(
            verifiedNetProfit: 0,
            remainingOpportunity: remaining,
            completedInRegion: completed,
            totalInRegion: offers.count,
            completedAllRegions: 0
        )
    }

    /// Earned stamps plus the next one to chase.
    static func stamps(completedOffers: Int, netProfit: Int) -> [JourneyStamp] {
        var result: [JourneyStamp] = []
        for milestone in [1, 3, 5, 10] where completedOffers >= milestone {
            result.append(
                JourneyStamp(
                    id: "offers-\(milestone)",
                    symbol: "\(milestone)",
                    title: milestone == 1 ? "First offer cleared" : "\(milestone) offers cleared",
                    family: "Offers completed",
                    earned: true
                )
            )
        }
        for milestone in [100, 250, 500] where netProfit >= milestone {
            result.append(
                JourneyStamp(
                    id: "profit-\(milestone)",
                    symbol: "$\(milestone)",
                    title: "$\(milestone) verified profit",
                    family: "Verified net profit",
                    earned: true
                )
            )
        }

        let upcoming: [JourneyStamp] = [
            JourneyStamp(id: "up-offers", symbol: "1", title: "Clear your first offer", family: "Offers completed", earned: false),
            JourneyStamp(id: "up-profit", symbol: "$100", title: "$100 verified profit", family: "Verified net profit", earned: false),
            JourneyStamp(id: "up-roi", symbol: "10%", title: "10% portfolio ROI", family: "Portfolio ROI", earned: false)
        ]
        return result + upcoming.filter { stamp in !result.contains { $0.family == stamp.family } }
    }

    // MARK: - Seeds

    private struct Seed: Sendable {
        let id: String
        let name: String
        let shortName: String
        let mark: JourneyBrandMark
        let rank: Int?
        let state: JourneyOfferState
        let headline: String
        let youPutIn: String
        let youMayReceive: String
        let mainCatch: String
        let estimatedValue: Int
        let verified: Bool
        let regions: Set<String>
        let url: String

        var offer: JourneyOffer {
            JourneyOffer(
                id: id,
                name: name,
                shortName: shortName,
                mark: mark,
                rank: rank,
                state: state,
                headline: headline,
                youPutIn: youPutIn,
                youMayReceive: youMayReceive,
                mainCatch: mainCatch,
                verified: verified,
                officialURL: url
            )
        }
    }

    private static let seeds: [Seed] = [
        Seed(
            id: "fanduel",
            name: "FanDuel Casino",
            shortName: "FanDuel",
            mark: JourneyBrandMark(top: 0x1F7BE0, bottom: 0x0B3F86, ink: 0xFFFFFF, monogram: "FD"),
            rank: 1,
            state: .ready,
            headline: "Play $1, get 350 spins",
            youPutIn: "$1 minimum",
            youMayReceive: "$88–$104 estimated cashable value",
            mainCatch: "Spins expire 7 days after they are credited",
            estimatedValue: 96,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://casino.fanduel.com"
        ),
        Seed(
            id: "betmgm",
            name: "BetMGM",
            shortName: "BetMGM",
            mark: JourneyBrandMark(top: 0x1B2436, bottom: 0x0A1020, ink: 0xD9B356, monogram: "MGM"),
            rank: 2,
            state: .current,
            headline: "Up to $1,025",
            youPutIn: "$10 minimum",
            youMayReceive: "$103–$120 estimated cashable value",
            mainCatch: "1× deposit-match freeplay + 1× $25 freeplay",
            estimatedValue: 112,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://casino.betmgm.com"
        ),
        Seed(
            id: "draftkings",
            name: "DraftKings Casino",
            shortName: "DraftKings",
            mark: JourneyBrandMark(top: 0x64C244, bottom: 0x1D6B2B, ink: 0x0B1A0F, monogram: "DK"),
            rank: 3,
            state: .next,
            headline: "$35 on the house + 100% match",
            youPutIn: "$5 minimum for the no-deposit credit",
            youMayReceive: "$96–$118 estimated cashable value",
            mainCatch: "Match portion clears at 1× over 7 days",
            estimatedValue: 108,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://casino.draftkings.com"
        ),
        Seed(
            id: "golden-nugget",
            name: "Golden Nugget",
            shortName: "Golden Nugget",
            mark: JourneyBrandMark(top: 0xE0C34E, bottom: 0x9A7519, ink: 0x1A1405, monogram: "GN"),
            rank: 4,
            state: .ready,
            headline: "200 spins + 100% match up to $1,000",
            youPutIn: "$5 minimum",
            youMayReceive: "$74–$92 estimated cashable value",
            mainCatch: "Spins land on one featured slot only",
            estimatedValue: 84,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://www.goldennuggetcasino.com"
        ),
        Seed(
            id: "betrivers",
            name: "BetRivers Casino",
            shortName: "BetRivers",
            mark: JourneyBrandMark(top: 0x2E6FC7, bottom: 0x123C78, ink: 0xFFFFFF, monogram: "BR"),
            rank: 5,
            state: .ready,
            headline: "100% deposit match up to $500",
            youPutIn: "$10 minimum",
            youMayReceive: "$68–$85 estimated cashable value",
            mainCatch: "1× playthrough on slots, 5× on tables",
            estimatedValue: 77,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://www.betrivers.com"
        ),
        Seed(
            id: "bally",
            name: "Bally Casino",
            shortName: "Bally",
            mark: JourneyBrandMark(top: 0x1C7A4B, bottom: 0x0B3D26, ink: 0xF4EFDC, monogram: "BC"),
            rank: 6,
            state: .ready,
            headline: "$25 no-deposit + 100% match",
            youPutIn: "No deposit for the $25 credit",
            youMayReceive: "$61–$78 estimated cashable value",
            mainCatch: "No-deposit winnings cap at $250",
            estimatedValue: 70,
            verified: true,
            regions: ["MI", "NJ", "PA"],
            url: "https://www.ballycasino.com"
        ),
        Seed(
            id: "caesars",
            name: "Caesars Palace",
            shortName: "Caesars Palace",
            mark: JourneyBrandMark(top: 0xC4122E, bottom: 0x7E0A1E, ink: 0xFFF3D6, monogram: "CP"),
            rank: 7,
            state: .ready,
            headline: "100% match up to $1,000",
            youPutIn: "$10 minimum for the deposit-match component; the separate $10 signup bonus is no-deposit",
            youMayReceive: "$89–$106 estimated cashable value",
            mainCatch: "1× deposit-match bonus + 1× $10 no-deposit bonus",
            estimatedValue: 98,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://www.caesars.com/casino"
        ),
        Seed(
            id: "horseshoe",
            name: "Horseshoe Online Casino",
            shortName: "Horseshoe",
            mark: JourneyBrandMark(top: 0x2A55C8, bottom: 0x0F2168, ink: 0xE8C878, monogram: "HS"),
            rank: 8,
            state: .ready,
            headline: "500 spins total · $0.20 each",
            youPutIn: "No deposit is required for the first 125 spins. A cash deposit is required before bonus winnings can be withdrawn.",
            youMayReceive: "500 spins total · $0.20 each",
            mainCatch: "Winnings: 1× slots, 2× video poker, 5× other eligible games; craps excluded",
            estimatedValue: 64,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://www.horseshoeonlinecasino.com"
        ),
        Seed(
            id: "fanatics",
            name: "Fanatics Casino",
            shortName: "Fanatics",
            mark: JourneyBrandMark(top: 0x2B2B2B, bottom: 0x0D0D0D, ink: 0xFFFFFF, monogram: "FA"),
            rank: 9,
            state: .ready,
            headline: "Up to $100 in casino credit",
            youPutIn: "$10 minimum",
            youMayReceive: "$52–$66 estimated cashable value",
            mainCatch: "Credit arrives in daily increments over 10 days",
            estimatedValue: 59,
            verified: true,
            regions: ["MI", "NJ", "PA", "WV"],
            url: "https://casino.fanatics.com"
        ),
        Seed(
            id: "betway",
            name: "Betway Casino",
            shortName: "Betway",
            mark: JourneyBrandMark(top: 0x0F8A3C, bottom: 0x064B20, ink: 0xFFFFFF, monogram: "BW"),
            rank: 10,
            state: .ready,
            headline: "100% match up to $1,000",
            youPutIn: "$10 minimum",
            youMayReceive: "$44–$58 estimated cashable value",
            mainCatch: "Bonus clears at 50× on slots",
            estimatedValue: 51,
            verified: true,
            regions: ["MI", "NJ", "PA"],
            url: "https://betway.com/casino"
        ),
        Seed(
            id: "wynnbet",
            name: "Wynn Casino",
            shortName: "Wynn",
            mark: JourneyBrandMark(top: 0xB79343, bottom: 0x6E5416, ink: 0x1A1405, monogram: "WY"),
            rank: 11,
            state: .ready,
            headline: "$50 in casino credit",
            youPutIn: "$20 minimum",
            youMayReceive: "$38–$47 estimated cashable value",
            mainCatch: "Credit expires 14 days after signup",
            estimatedValue: 43,
            verified: true,
            regions: ["MI", "NJ"],
            url: "https://www.wynnbet.com"
        ),
        Seed(
            id: "eagle",
            name: "Eagle Casino",
            shortName: "Eagle",
            mark: JourneyBrandMark(top: 0x365F9B, bottom: 0x152B4E, ink: 0xF3E8C6, monogram: "EC"),
            rank: 12,
            state: .ready,
            headline: "Up to 250 bonus spins",
            youPutIn: "$10 minimum",
            youMayReceive: "$31–$40 estimated cashable value",
            mainCatch: "Spins release 25 per day for 10 days",
            estimatedValue: 36,
            verified: true,
            regions: ["MI"],
            url: "https://www.eaglecasinoandsports.com"
        ),
        Seed(
            id: "four-winds",
            name: "Four Winds",
            shortName: "Four Winds",
            mark: JourneyBrandMark(top: 0xF6EBCD, bottom: 0xD9C08A, ink: 0x8E1A1A, monogram: "FW"),
            rank: nil,
            state: .future,
            headline: "Up to 500 bonus spins",
            youPutIn: "Check in Four Winds app",
            youMayReceive: "Up to 500 bonus spins",
            mainCatch: "Some requirements are available only in the casino app.",
            estimatedValue: 0,
            verified: true,
            regions: ["MI"],
            url: "https://www.fourwindscasino.com"
        ),
        Seed(
            id: "hard-rock",
            name: "Hard Rock Bet",
            shortName: "Hard Rock",
            mark: JourneyBrandMark(top: 0xE0348B, bottom: 0x8E0F52, ink: 0xFFFFFF, monogram: "HR"),
            rank: nil,
            state: .future,
            headline: "Up to $1,000 conditional lossback",
            youPutIn: "$10 minimum",
            youMayReceive: "Lossback credit, not cash",
            mainCatch: "Lossback is paid as bonus credit over 30 days",
            estimatedValue: 0,
            verified: true,
            regions: ["MI", "NJ"],
            url: "https://www.hardrock.bet"
        ),
        Seed(
            id: "hollywood",
            name: "Hollywood Casino",
            shortName: "Hollywood",
            mark: JourneyBrandMark(top: 0x22331F, bottom: 0x0F1A0E, ink: 0xD9C27A, monogram: "HW"),
            rank: nil,
            state: .future,
            headline: "Up to $1,000 in bonus play",
            youPutIn: "$10 minimum",
            youMayReceive: "Bonus play, not cash",
            mainCatch: "Bonus play must be wagered before withdrawal",
            estimatedValue: 0,
            verified: false,
            regions: ["MI", "PA", "WV"],
            url: "https://www.hollywoodcasino.com"
        )
    ]
}
