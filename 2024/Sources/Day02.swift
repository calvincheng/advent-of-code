import Foundation

struct Day02: AdventDay {
    var data: String

    init(data: String) {
        self.data = data
    }

    private func isSafe(report: [Int]) -> Bool {
        guard report.count > 1 else { return true }
        let isAscending = report[1] > report[0]
        for i in 1..<report.count {
            if isAscending, report[i] < report[i - 1] { return false }
            if !isAscending, report[i] > report[i - 1] { return false }
            let diff = abs(report[i] - report[i - 1])
            if diff < 1 || diff > 3 { return false }
        }
        return true
    }

    func part1() -> Int {
        let reports = self.data
            .components(separatedBy: .newlines)
            .map { $0.components(separatedBy: .whitespaces).compactMap { Int($0) } }
        let safeReports = reports.filter { self.isSafe(report: $0) }
        return safeReports.count
    }

    func part2() -> Int {
        let reports = self.data
            .components(separatedBy: .newlines)
            .map { $0.components(separatedBy: .whitespaces).compactMap { Int($0) } }

        let safeReports = reports.filter { report in
            for i in 0..<report.count {
                var copy = report
                copy.remove(at: i)
                if isSafe(report: copy) {
                    return true
                }
            }
            return false
        }
        return safeReports.count
    }
}
