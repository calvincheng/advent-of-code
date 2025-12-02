import Foundation

struct Day21: AdventDay {
    var data: String

    private let example: String = """
        029A
        980A
        179A
        456A
        379A
        """

    /// +---+---+---+
    /// | 7 | 8 | 9 |
    /// +---+---+---+
    /// | 4 | 5 | 6 |
    /// +---+---+---+
    /// | 1 | 2 | 3 |
    /// +---+---+---+
    ///     | 0 | A |
    ///     +---+---+
    private let numPad: [[Character]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        ["X", "0", "A"],
    ]

    private let numPadMapping: [[Character]: [Command]] = {
        let nums: [Character: (Int, Int)] = [
            "A": (2, 3),
            "0": (1, 3),
            "1": (0, 2),
            "2": (1, 2),
            "3": (2, 2),
            "4": (0, 1),
            "5": (1, 1),
            "6": (2, 1),
            "7": (0, 0),
            "8": (1, 0),
            "9": (2, 0),
        ]
        var mapping: [[Character]: [Command]] = [:]
        let combos = nums.keys.permutations(ofCount: 2)
        for combo in combos {
            let keyA = combo[0]
            let keyB = combo[1]
            let (aX, aY) = nums[keyA]!
            let (bX, bY) = nums[keyB]!
            let dx = bX - aX
            let dy = bY - aY
            // Prefer up and right first, before down and left to prevent going into "X"
            var commands: [Command] = []
            if dy < 0 { commands += (0..<abs(dy)).map { _ in .up } }  // up
            if dx > 0 { commands += (0..<abs(dx)).map { _ in .right } }  // right
            if dy > 0 { commands += (0..<abs(dy)).map { _ in .down } }  // down
            if dx < 0 { commands += (0..<abs(dx)).map { _ in .left } }  // left
            mapping[[keyA, keyB]] = commands
        }
        for num in nums.keys {
            mapping[[num, num]] = []
        }
        return mapping
    }()

    ///     +---+---+
    ///     | ^ | A |
    /// +---+---+---+
    /// | < | v | > |
    /// +---+---+---+
    private let dPad: [[Character]] = [
        ["X", "^", "A"],
        ["<", "v", ">"],
    ]

    private let dPadMapping: [[Character]: [Command]] = {
        let dirs: [Character: (Int, Int)] = [
            "^": (1, 0),
            "A": (2, 0),
            "<": (0, 1),
            "v": (1, 1),
            ">": (2, 1),
        ]
        var mapping: [[Character]: [Command]] = [:]
        let combos = dirs.keys.permutations(ofCount: 2)
        for combo in combos {
            let keyA = combo[0]
            let keyB = combo[1]
            let (aX, aY) = dirs[keyA]!
            let (bX, bY) = dirs[keyB]!
            let dx = bX - aX
            let dy = bY - aY
            // Prefer down and right first, before up and left to prevent going into "X"
            var commands: [Command] = []
            if dy > 0 { commands += (0..<abs(dy)).map { _ in .down } }  // down
            if dx > 0 { commands += (0..<abs(dx)).map { _ in .right } }  // right
            if dx < 0 { commands += (0..<abs(dx)).map { _ in .left } }  // left
            if dy < 0 { commands += (0..<abs(dy)).map { _ in .up } }  // up
            mapping[[keyA, keyB]] = commands
        }
        for d in dirs.keys {
            mapping[[d, d]] = []
        }
        return mapping
    }()

    private enum Command: CustomDebugStringConvertible {
        case up, down, left, right
        case submit

        var debugDescription: String {
            switch self {
            case .up: "^"
            case .down: "v"
            case .left: "<"
            case .right: ">"
            case .submit: "A"
            }
        }
    }

    private func solveNumPad(code: String) -> [Command] {
        let sequences = Array(code).windows(ofCount: 2).map { Array($0) }
        let commands =
            sequences
            .map { return self.numPadMapping[$0]! + [.submit] }
            .flatMap { $0 }
        return commands
    }

    private func solveDPad(code: String) -> [Command] {
        let sequences = Array(code).windows(ofCount: 2).map { Array($0) }
        let commands =
            sequences
            .map { return self.dPadMapping[$0]! + [.submit] }
            .flatMap { $0 }
        return commands
    }

    private func solve(code: String) -> String {
        print(code)

        let numPadCommands = self.solveNumPad(code: "A" + code)
            .map(\.debugDescription)
            .joined()
        print(numPadCommands, numPadCommands.count)

        let dPadCommands = self.solveDPad(code: "A" + numPadCommands)
            .map(\.debugDescription)
            .joined()
        print(dPadCommands, dPadCommands.count)

        let dPadCommands2 = self.solveDPad(code: "A" + dPadCommands)
            .map(\.debugDescription)
            .joined()
        print(dPadCommands2, dPadCommands2.count)

        return dPadCommands2
    }

    private func parse(_ data: String) -> [String] {
        data.split(separator: "\n").map { String($0) }
    }

    init(data: String) {
        self.data = self.example  // data
    }

    func part1() -> Int {
        let codes = self.parse(self.data)
        var result: Int = 0
        for code in codes {
            let finalSequence = self.solve(code: code)
            let codeNumeral = Int(code.dropLast())!
            print("\(finalSequence.count) * \(codeNumeral)")
            let complexity = finalSequence.count * codeNumeral
            result += complexity
        }
        return result
    }

    func part2() -> Int {
        0
    }
}
