import Foundation

struct Day01: AdventDay {
    var data: String

    init(data: String) {
        self.data = data
    }

    func part1() -> Int {
        let digits =
            data
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let (leftCol, rightCol) =
            digits
            .enumerated()
            .reduce(into: ([Int](), [Int]())) { result, indexAndDigit in
                let (index, digit) = indexAndDigit
                guard let number = Int(digit) else { return }
                if index % 2 == 0 {
                    result.0.append(number)
                } else {
                    result.1.append(number)
                }
            }
        let result = zip(leftCol.sorted(), rightCol.sorted())
            .reduce(0) { acc, pair in
                acc + abs(pair.0 - pair.1)
            }
        return result
    }

    func part2() -> Int {
        let digits =
            data
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let (leftCol, rightCol) =
            digits
            .enumerated()
            .reduce(into: ([Int](), [Int]())) { result, indexAndDigit in
                let (index, digit) = indexAndDigit
                guard let number = Int(digit) else { return }
                if index % 2 == 0 {
                    result.0.append(number)
                } else {
                    result.1.append(number)
                }
            }
        let counts = rightCol.reduce(into: [Int: Int]()) { result, number in
            result[number] = (result[number] ?? 0) + 1
        }
        let result = leftCol.reduce(0) { acc, number in
            acc + number * (counts[number] ?? 0)
        }
        return result
    }
}
