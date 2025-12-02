import Foundation

struct Day19: AdventDay {
    var data: String

    private let example: String = """
        r, wr, b, g, bwu, rb, gb, br

        brwrr
        bggr
        gbbr
        rrbgbr
        ubwu
        bwurrg
        brgr
        bbrgwb
        """

    init(data: String) {
        self.data = data
    }

    private func parse(_ data: String) -> (strs: [String], substrs: Set<String>) {
        let splitted = data.split(separator: "\n\n")
        let substrs = Set(splitted[0].split(separator: ", ").map { String($0) })
        let strs = splitted[1]
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return (strs, substrs)
    }

    private func getCombos(str: String, substrs: Set<String>) -> Int {
        var memo: [String: Int] = [:]
        func recur(_ s: String) -> Int {
            if let memoised = memo[s] { return memoised }
            if s.isEmpty { return 1 }
            var numCombos: Int = 0
            for pfx in substrs {
                guard s.starts(with: pfx) else { continue }
                let result = recur(String(s.dropFirst(pfx.count)))
                numCombos += result
            }
            memo[s] = numCombos
            return numCombos
        }
        return recur(str)
    }

    func part1() -> Int {
        let (strs, substrs) = self.parse(self.data)
        var numValid: Int = 0
        for str in strs {
            let validCombos = self.getCombos(str: str, substrs: substrs)
            if validCombos > 0 {
                numValid += 1
            }
        }
        return numValid
    }

    func part2() -> Int {
        let (strs, substrs) = self.parse(self.data)
        var comboCount: Int = 0
        for str in strs {
            let numCombos = self.getCombos(str: str, substrs: substrs)
            comboCount += numCombos
        }
        return comboCount
    }
}
