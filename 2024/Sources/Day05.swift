import Foundation

struct Day05: AdventDay {
    var data: String

    private let example: String = """
        47|53
        97|13
        97|61
        97|47
        75|29
        61|13
        75|53
        29|13
        97|29
        53|29
        61|53
        97|53
        61|29
        47|13
        75|47
        97|75
        47|61
        75|61
        47|29
        75|13
        53|13

        75,47,61,53,29
        97,61,53,29,13
        75,29,13
        75,97,47,61,53
        61,13,29
        97,13,75,29,47
        """

    init(data: String) {
        self.data = data
    }

    private typealias Rule = (Int, Int)
    private typealias Update = [Int]
    private func parse(data: String) -> ([Rule], [Update]) {
        let splitted = data.split(separator: "\n\n")
        let rules: [Rule] = splitted[0]
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { $0.components(separatedBy: "|") }
            .map { x in (Int(x[0])!, Int(x[1])!) }
        let updates = splitted[1]
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { $0.components(separatedBy: ",").map { Int($0)! } }
        return (rules, updates)
    }

    private func map(of rules: [Rule]) -> [Int: Set<Int>] {
        var map: [Int: Set<Int>] = [:]
        for rule in rules {
            let (lower, higher) = rule
            if map[lower] == nil {
                map[lower] = []
            }
            map[lower]!.insert(higher)
        }
        return map
    }

    private func isGood(_ update: Update, map: [Int: Set<Int>]) -> Bool {
        for (i, curr) in update.enumerated().dropLast() {
            guard let nextNums = map[curr] else { return false }
            if i + 1 < update.count {
                let next = update[i + 1]
                if !nextNums.contains(next) { return false }
            }
        }
        return true
    }

    func part1() -> Int {
        let (rules, updates) = parse(data: self.data)
        let map = map(of: rules)
        return
            updates
            .filter { isGood($0, map: map) }
            .map { $0[$0.count / 2] }
            .reduce(0, +)
    }

    func part2() -> Int {
        let (rules, updates) = parse(data: self.data)
        let map = map(of: rules)
        let badUpdates = updates.filter { !isGood($0, map: map) }
        var result: Int = 0
        for update in badUpdates {
            let fixed = update.sorted(by: { (map[$0] ?? []).contains($1) })
            result += fixed[fixed.count / 2]
        }
        return result
    }
}
