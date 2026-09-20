//
//  HomeModels.swift
//  BankrollBoard
//
//  Home data model: bankroll timeframes, chart series, and transfer activity.
//

import Foundation

// MARK: - Timeframe

/// Windows offered by the bankroll chart's segmented bar.
nonisolated enum HomeTimeframe: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case ytd
    case year
    case all

    var id: String { rawValue }

    var short: String {
        switch self {
        case .day: "1D"
        case .week: "1W"
        case .month: "1M"
        case .ytd: "YTD"
        case .year: "1Y"
        case .all: "All"
        }
    }

    /// Used in the hero subtitle, e.g. "Net bankroll · Past month".
    var long: String {
        switch self {
        case .day: "Today"
        case .week: "Past week"
        case .month: "Past month"
        case .ytd: "Year to date"
        case .year: "Past year"
        case .all: "All time"
        }
    }

    /// Trails the change figure, e.g. "−$19.78 today".
    var deltaCaption: String {
        switch self {
        case .day: "today"
        case .week: "this week"
        case .month: "this month"
        case .ytd: "year to date"
        case .year: "this year"
        case .all: "all time"
        }
    }

    /// Number of samples plotted for this window.
    var pointCount: Int {
        switch self {
        case .day: 24
        case .week: 28
        case .month: 32
        case .ytd: 38
        case .year: 40
        case .all: 44
        }
    }

    /// Total duration covered by the window.
    var span: TimeInterval {
        switch self {
        case .day: 86_400
        case .week: 604_800
        case .month: 2_592_000
        case .ytd: 22_800_000
        case .year: 31_536_000
        case .all: 63_072_000
        }
    }

    /// Distinct seed so each window draws its own repeatable shape.
    var seed: UInt64 {
        switch self {
        case .day: 11
        case .week: 29
        case .month: 47
        case .ytd: 71
        case .year: 93
        case .all: 131
        }
    }
}

// MARK: - Chart

nonisolated struct BankrollPoint: Identifiable, Hashable, Sendable {
    let id: Int
    let date: Date
    let cents: Int
}

// MARK: - Activity

nonisolated enum TransferDirection: String, Sendable {
    case deposit
    case withdrawal

    /// Bank → Casino for deposits, the reverse for withdrawals.
    var flowLabel: String {
        switch self {
        case .deposit: "Bank → Casino"
        case .withdrawal: "Casino → Bank"
        }
    }

    var verb: String {
        switch self {
        case .deposit: "Deposit"
        case .withdrawal: "Withdrawal"
        }
    }
}

/// Settlement state reported by the linked bank account.
nonisolated enum TransferStatus: String, Sendable {
    /// The bank has authorized the transfer but has not settled it yet.
    case pending
    /// Fully settled and counted in the net bankroll.
    case settled

    var label: String {
        switch self {
        case .pending: "Pending"
        case .settled: "Settled"
        }
    }

    var symbol: String {
        switch self {
        case .pending: "clock"
        case .settled: "checkmark.circle"
        }
    }
}

nonisolated struct HomeTransfer: Identifiable, Hashable, Sendable {
    let id: String
    let casinoId: String
    let direction: TransferDirection
    /// Signed cents: negative moves money out of your bankroll into a casino.
    let cents: Int
    let date: Date
    let status: TransferStatus
    /// Bank's estimated settlement date, shown only while pending.
    let expectedDate: Date?

    init(
        id: String,
        casinoId: String,
        direction: TransferDirection,
        cents: Int,
        date: Date,
        status: TransferStatus = .settled,
        expectedDate: Date? = nil
    ) {
        self.id = id
        self.casinoId = casinoId
        self.direction = direction
        self.cents = cents
        self.date = date
        self.status = status
        self.expectedDate = expectedDate
    }

    var title: String {
        "\(HomeCasino.name(for: casinoId)) \(direction.verb)"
    }
}

/// One day's worth of transfers, with that day's net movement.
nonisolated struct HomeActivitySection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let transfers: [HomeTransfer]

    var netCents: Int {
        transfers.reduce(0) { $0 + $1.cents }
    }
}

/// Activity list filters.
nonisolated enum HomeActivityFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case pending
    case deposits
    case withdrawals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .pending: "Pending"
        case .deposits: "Deposits"
        case .withdrawals: "Withdrawals"
        }
    }
}

// MARK: - Casino brand table

/// Minimal brand lookup for activity rows: real logo when the image set exists,
/// otherwise an initials monogram on the operator's brand color.
nonisolated struct HomeCasino: Sendable {
    let id: String
    let name: String
    let assetName: String
    let brandColorHex: UInt32

    static let all: [HomeCasino] = [
        .init(id: "draftkings", name: "DraftKings", assetName: "draftkingscasino", brandColorHex: 0x53D337),
        .init(id: "hard-rock", name: "Hard Rock Digital", assetName: "hardrockcasino", brandColorHex: 0xE8C34A),
        .init(id: "golden-nugget", name: "Golden Nugget", assetName: "golden_nugget_casino", brandColorHex: 0xC5A13E),
        .init(id: "fanduel", name: "FanDuel", assetName: "fanduel", brandColorHex: 0x1493FF),
        .init(id: "betmgm", name: "BetMGM", assetName: "betmgm", brandColorHex: 0xC9A84C),
        .init(id: "bet365", name: "bet365", assetName: "bet365", brandColorHex: 0x087B5A),
        .init(id: "caesars", name: "Caesars Palace", assetName: "caesars", brandColorHex: 0xC70000)
    ]

    static func lookup(_ id: String) -> HomeCasino? {
        all.first { $0.id == id }
    }

    static func name(for id: String) -> String {
        lookup(id)?.name ?? "Casino"
    }

    /// Up to two letters taken from the operator name.
    var initials: String {
        let words = name.split(separator: " ")
        let letters = words.compactMap(\.first)
        return String(letters.prefix(2)).uppercased()
    }
}

// MARK: - Seed data

/// Illustrative Home content until the device is connected to the live ledger.
nonisolated enum HomeSeed {
    /// Settled net bankroll in cents.
    static let settledCents = 168_962

    static func transfers(now: Date = Date()) -> [HomeTransfer] {
        let day: TimeInterval = 86_400
        return [
            .init(
                id: "t1",
                casinoId: "draftkings",
                direction: .deposit,
                cents: -5_000,
                date: now.addingTimeInterval(-3 * 3_600),
                status: .pending,
                expectedDate: now.addingTimeInterval(2 * day)
            ),
            .init(
                id: "t2",
                casinoId: "hard-rock",
                direction: .withdrawal,
                cents: 500,
                date: now.addingTimeInterval(-5 * 3_600),
                status: .pending,
                expectedDate: now.addingTimeInterval(3 * day)
            ),
            .init(
                id: "t3",
                casinoId: "hard-rock",
                direction: .withdrawal,
                cents: 82,
                date: now.addingTimeInterval(-7 * 3_600),
                status: .pending,
                expectedDate: now.addingTimeInterval(3 * day)
            ),
            .init(
                id: "t4",
                casinoId: "draftkings",
                direction: .withdrawal,
                cents: 2_440,
                date: now.addingTimeInterval(-9 * 3_600),
                status: .pending,
                expectedDate: now.addingTimeInterval(2 * day)
            ),
            .init(
                id: "t5",
                casinoId: "golden-nugget",
                direction: .withdrawal,
                cents: 25_000,
                date: now.addingTimeInterval(-37 * day)
            ),
            .init(
                id: "t6",
                casinoId: "golden-nugget",
                direction: .withdrawal,
                cents: 7_284,
                date: now.addingTimeInterval(-37 * day)
            ),
            .init(
                id: "t7",
                casinoId: "golden-nugget",
                direction: .deposit,
                cents: -25_000,
                date: now.addingTimeInterval(-37 * day)
            ),
            .init(
                id: "t8",
                casinoId: "fanduel",
                direction: .withdrawal,
                cents: 4_024,
                date: now.addingTimeInterval(-48 * day)
            ),
            .init(
                id: "t9",
                casinoId: "golden-nugget",
                direction: .withdrawal,
                cents: 6_603,
                date: now.addingTimeInterval(-48 * day)
            ),
            .init(
                id: "t10",
                casinoId: "fanduel",
                direction: .withdrawal,
                cents: 6_206,
                date: now.addingTimeInterval(-61 * day)
            ),
            .init(
                id: "t11",
                casinoId: "betmgm",
                direction: .deposit,
                cents: -10_000,
                date: now.addingTimeInterval(-74 * day)
            ),
            .init(
                id: "t12",
                casinoId: "betmgm",
                direction: .withdrawal,
                cents: 31_500,
                date: now.addingTimeInterval(-70 * day)
            )
        ]
    }

    /// Net movement across the window, in cents.
    static func periodDeltaCents(for timeframe: HomeTimeframe) -> Int {
        switch timeframe {
        case .day: 1_240
        case .week: 4_862
        case .month: 12_618
        case .ytd: 74_235
        case .year: 98_810
        case .all: settledCents
        }
    }

    /// Repeatable curve for a window, ending exactly on the settled balance.
    static func series(
        for timeframe: HomeTimeframe,
        endingAt endCents: Int = settledCents,
        now: Date = Date()
    ) -> [BankrollPoint] {
        let count = timeframe.pointCount
        guard count > 1 else { return [] }

        let delta = periodDeltaCents(for: timeframe)
        let startCents = endCents - delta

        var state = timeframe.seed
        func nextUnit() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((state >> 33) & 0xFF_FFFF) / Double(0xFF_FFFF)
        }

        // Weighted increments produce an uneven climb rather than a straight line.
        var weights: [Double] = []
        for index in 0..<(count - 1) {
            let progress = Double(index) / Double(count - 1)
            // Late-window acceleration mirrors a finishing offer paying out.
            let bias = 0.35 + pow(progress, 2.4) * 2.1
            weights.append(bias * (0.55 + nextUnit() * 0.9))
        }
        let total = weights.reduce(0, +)

        var fractions: [Double] = [0]
        var running: Double = 0
        for weight in weights {
            running += weight
            fractions.append(total > 0 ? running / total : 0)
        }

        let wiggle = Double(abs(delta)) * 0.05
        let step = timeframe.span / Double(count - 1)

        return (0..<count).map { index in
            let fraction = fractions[index]
            // Endpoints stay exact so the delta always matches the plotted line.
            let isEdge = index == 0 || index == count - 1
            let noise = isEdge ? 0 : (nextUnit() - 0.5) * wiggle
            let value = Double(startCents) + Double(delta) * fraction + noise
            let date = now.addingTimeInterval(-timeframe.span + step * Double(index))
            return BankrollPoint(id: index, date: date, cents: Int(value.rounded()))
        }
    }
}

// MARK: - Formatting

/// Formats signed cents as currency, e.g. `+$1,689.62` or `−$50.00`.
nonisolated func homeMoney(cents: Int, showsPlus: Bool = true) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    let magnitude = abs(Double(cents)) / 100
    let digits = formatter.string(from: NSNumber(value: magnitude)) ?? String(format: "%.2f", magnitude)
    let sign = cents < 0 ? "−" : (showsPlus && cents > 0 ? "+" : "")
    return "\(sign)$\(digits)"
}

/// Splits a balance into whole dollars and cents so the hero can scale them apart.
nonisolated func homeBalanceParts(cents: Int) -> (dollars: String, cents: String) {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    let magnitude = abs(cents)
    let whole = magnitude / 100
    let remainder = magnitude % 100
    let digits = formatter.string(from: NSNumber(value: whole)) ?? String(whole)
    let sign = cents < 0 ? "−" : ""
    return ("\(sign)$\(digits)", String(format: ".%02d", remainder))
}

/// Percentage change against the window's opening value.
nonisolated func homePercent(delta: Int, from start: Int) -> String? {
    guard start != 0 else { return nil }
    let percent = Double(delta) / Double(abs(start)) * 100
    guard percent.isFinite else { return nil }
    return String(format: "%@%.1f%%", percent < 0 ? "−" : "+", abs(percent))
}

/// "Today" / "Yesterday" / "Aug 14" heading for a day of activity.
nonisolated func homeDayTitle(_ date: Date, now: Date = Date()) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) { return "Today" }
    if calendar.isDateInYesterday(date) { return "Yesterday" }
    let formatter = DateFormatter()
    formatter.dateFormat = calendar.isDate(date, equalTo: now, toGranularity: .year) ? "MMM d" : "MMM d, yyyy"
    return formatter.string(from: date)
}

/// Compact date used on activity rows and pending estimates.
nonisolated func homeShortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

// MARK: - Axis helpers

/// Rounds a range outward to human-friendly tick values.
///
/// The web build divided every value by 1000 and printed one decimal, so a
/// hundred-dollar range collapsed into four identical `+$1.7K` labels. Here the
/// step is derived from the real range, so adjacent labels are always distinct.
nonisolated func homeNiceTicks(min lower: Double, max upper: Double, count: Int = 5) -> [Double] {
    guard upper > lower, count > 1 else {
        return [lower]
    }
    let rawStep = (upper - lower) / Double(count - 1)
    let magnitude = pow(10, floor(log10(rawStep)))
    let normalized = rawStep / magnitude
    let niceNormalized: Double
    switch normalized {
    case ..<1.5: niceNormalized = 1
    case ..<3: niceNormalized = 2
    case ..<7: niceNormalized = 5
    default: niceNormalized = 10
    }
    let step = niceNormalized * magnitude
    let start = (lower / step).rounded(.down) * step
    let end = (upper / step).rounded(.up) * step

    var ticks: [Double] = []
    var value = start
    while value <= end + step * 0.5 {
        ticks.append(value)
        value += step
    }
    return ticks
}

/// Formats an axis tick with only as much precision as the step requires.
nonisolated func homeAxisLabel(cents: Double, step: Double) -> String {
    let dollars = cents / 100
    let stepDollars = abs(step) / 100

    if stepDollars >= 1_000 {
        return String(format: "$%.1fK", dollars / 1_000)
    }
    if stepDollars >= 1 {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let digits = formatter.string(from: NSNumber(value: abs(dollars))) ?? String(Int(abs(dollars)))
        return "\(dollars < 0 ? "−" : "")$\(digits)"
    }
    return String(format: "%@$%.2f", dollars < 0 ? "−" : "", abs(dollars))
}

/// X-axis tick label appropriate to the window's duration.
nonisolated func homeAxisDateLabel(_ date: Date, timeframe: HomeTimeframe) -> String {
    let formatter = DateFormatter()
    switch timeframe {
    case .day:
        formatter.dateFormat = "h a"
    case .week:
        formatter.dateFormat = "EEE"
    case .month:
        formatter.dateFormat = "MMM d"
    case .ytd, .year, .all:
        formatter.dateFormat = "MMM"
    }
    return formatter.string(from: date)
}

/// Full stamp used by the scrub readout.
nonisolated func homeScrubDateLabel(_ date: Date, timeframe: HomeTimeframe) -> String {
    let formatter = DateFormatter()
    switch timeframe {
    case .day:
        formatter.dateFormat = "h:mm a"
    case .week, .month:
        formatter.dateFormat = "EEE, MMM d"
    case .ytd, .year, .all:
        formatter.dateFormat = "MMM d, yyyy"
    }
    return formatter.string(from: date)
}
