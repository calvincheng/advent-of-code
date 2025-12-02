import Foundation

struct Day22: AdventDay {
    var data: String

    private let example: String = """
        1
        10
        100
        2024
        """

    init(data: String) {
        self.data = data
    }

    private func parse(_ data: String) -> [Int] {
        data.split(separator: "\n").map { Int($0)! }
    }

    private func next(_ x: Int) -> Int {
        var x = x
        x = prune(mix(x, x * 64))
        x = prune(mix(x, x / 32))
        x = prune(mix(x, x * 2048))
        return x
    }

    private func prune(_ x: Int) -> Int {
        x % 16_777_216
    }

    private func mix(_ x: Int, _ y: Int) -> Int {
        x ^ y
    }

    func part1() -> Int {
        let ints = self.parse(self.data)
        let result =
            ints
            .map { int in
                var x = int
                for _ in 0..<2000 { x = next(x) }
                return x
            }
            .reduce(0, +)
        return result
    }

    func part2() -> Int {
        func getMagicNumbers(from n: Int, count: Int = 2000) -> [Int] {
            (0..<count).reduce(into: [n]) { nums, _ in
                nums.append(self.next(nums.last!))
            }
        }

        func getPrices(from ns: [Int]) -> [Int] {
            ns.map { $0 % 10 }
        }

        func getChanges(from ns: [Int]) -> [Int] {
            let diffs = ns.windows(ofCount: 2).map { window in
                // idk why i can't do window[1] - window[0]
                return window.last! - window.first!
            }
            return diffs
        }

        let ints = self.parse(self.data)
        let magicNums = ints.map { getMagicNumbers(from: $0, count: 2000) }
        let allPrices = magicNums.map { getPrices(from: $0) }
        let allDiffs = allPrices.map { getChanges(from: $0) }

        var profitBySequence: [[Int]: Int] = [:]
        for (di, diffs) in allDiffs.enumerated() {
            print("Compiling diff \(di+1)/\(allDiffs.count)")
            var seen: Set<[Int]> = []
            for i in 0..<diffs.count - 3 {
                let seq = Array(diffs[i..<i + 4])
                let price = allPrices[di][i + 4]
                if !seen.contains(seq) {
                    seen.insert(seq)
                    profitBySequence[seq] = (profitBySequence[seq] ?? 0) + price
                }
            }
        }

        let toTry = allDiffs.flatMap { $0.windows(ofCount: 4) }
        var best: Int = 0
        for (idx, seq) in toTry.enumerated() {
            print("Trying sequence \(idx+1)/\(toTry.count)")
            let profit = profitBySequence[Array(seq)] ?? 0
            best = max(best, profit)
        }

        return best
    }
}
