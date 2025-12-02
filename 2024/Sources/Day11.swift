import Foundation

struct Day11: AdventDay {
    var data: String

    private let example: String = "0 1 10 99 999"
    private let input: String = "5 89749 6061 43 867 1965860 0 206250"

    init(data: String) {
        self.data = input
    }

    private func parse(_ data: String) -> [Int] {
        data
            .split(separator: " ")
            .filter { !$0.isEmpty }
            .compactMap { Int($0) }
    }

    private func blink(_ x: Int) -> [Int] {
        if x == 0 {
            return [1]
        } else {
            let digits = String(x)
            if digits.count % 2 == 0 {
                return [
                    Int(digits.dropLast(digits.count / 2))!,
                    Int(digits.dropFirst(digits.count / 2))!,
                ]
            } else {
                return [x * 2024]
            }
        }
    }

    func part1() -> Int {
        var stones = self.parse(data)
        let numSteps = 25
        for _ in 0..<numSteps {
            stones = stones.flatMap { self.blink($0) }
            // print("step \(step) - \(stones.count)")
        }
        return stones.count
    }

    func part2() -> Int {
        let numSteps = 75
        // Stones: [Value: Count]
        var stones: [Int: Int] = self.parse(data)
            .reduce(into: [Int: Int]()) { result, stone in
                result[stone] = result[stone, default: 0] + 1
            }
        for _ in 0..<numSteps {
            stones = stones.reduce(into: [Int: Int]()) { result, kv in
                let (stone, count) = kv
                let newStones = self.blink(stone)
                for newStone in newStones {
                    result[newStone] = result[newStone, default: 0] + count
                }
            }
            // print("step \(step) - \(stones.values.reduce(0, +))")
        }
        return stones.values.reduce(0, +)
    }
}
