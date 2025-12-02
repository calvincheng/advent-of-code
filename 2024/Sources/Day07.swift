import Foundation

struct Day07: AdventDay {
    var data: String

    private let example: String = """
        190: 10 19
        3267: 81 40 27
        83: 17 5
        156: 15 6
        7290: 6 8 6 15
        161011: 16 10 13
        192: 17 8 14
        21037: 9 7 18 13
        292: 11 6 16 20
        """

    init(data: String) {
        self.data = data
    }

    private struct Equation {
        let operands: [Int]
        let expected: Int
    }

    private func parse(data: String) -> [Equation] {
        data
            .split(separator: "\n")
            .map { row in
                let splitted = row.split(separator: ": ")
                let expected = Int(splitted[0])!
                let operands = splitted[1]
                    .trimmingCharacters(in: .whitespaces)
                    .split(separator: " ")
                    .map { Int($0)! }
                return Equation(operands: operands, expected: expected)
            }
    }

    enum Operator {
        case add
        case mul
        case concat  // part2
    }

    private func isValid(equation: Equation, operatorCount: Int = 2) -> Bool {
        let numOperators = equation.operands.count - 1
        if numOperators == 0 { return true }
        let numCombinations = Int(pow(Double(operatorCount), Double(numOperators)))
        for i in 0..<numCombinations {
            let binary = String(i, radix: operatorCount)
            let string = String(repeating: "0", count: numOperators - binary.count) + binary
            let operators: [Operator] =
                [.add]
                + string.map { char in
                    switch char {
                    case "0": .add
                    case "1": .mul
                    case "2": .concat
                    default: fatalError("Unexpected value \(char) in binary string")
                    }
                }
            let result = equation.operands.enumerated().reduce(0) { answer, o in
                let (index, operand) = o
                let operation = operators[index]
                return switch operation {
                case .add: answer + operand
                case .mul: answer * operand
                case .concat: Int(String(answer) + String(operand))!
                }
            }
            if result == equation.expected { return true }
        }
        return false
    }

    func part1() -> Int {
        let equations = self.parse(data: self.data)
        let result = equations.reduce(0) { partial, equation in
            isValid(equation: equation) ? partial + equation.expected : partial
        }
        return result
    }

    func part2() -> Int {
        let equations = self.parse(data: self.data)
        let result = equations.reduce(0) { partial, equation in
            isValid(equation: equation, operatorCount: 3)
                ? partial + equation.expected
                : partial
        }
        return result
    }
}
