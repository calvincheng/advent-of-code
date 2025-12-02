import Foundation

struct Day03: AdventDay {
    var data: String

    private let example: String =
        "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

    init(data: String) {
        self.data = data
    }

    func part1() -> Int {
        return
            data
            .matches(of: /mul\((\d+),(\d+)\)/)
            .map { ($0.output.1, $0.output.2) }
            .map { x, y in Int(x)! * Int(y)! }
            .reduce(0, +)
    }

    func part2() -> Int {
        let matches = data.matches(of: /mul\((\d+),(\d+)\)|do\(\)|don't\(\)/)
        var shouldMul = true
        var total: Int = 0
        for match in matches {
            switch String(match.output.0) {
            case "don't()":
                shouldMul = false
            case "do()":
                shouldMul = true
            default:  // mul
                if shouldMul {
                    let operands = (match.output.1, match.output.2)
                    total += Int(operands.0!)! * Int(operands.1!)!
                }
            }
        }
        return total
    }
}
