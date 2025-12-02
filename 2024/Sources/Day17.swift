import Collections

struct Day17: AdventDay {
    var data: String

    private let example: String = """
        Register A: 729
        Register B: 0
        Register C: 0

        Program: 0,1,5,4,3,0
        """

    init(data: String) {
        self.data = data
    }

    private func parse(_ data: String) -> (register: [String: Int], program: [Int]) {
        let splitted = data.split(separator: "\n\n")
        let registers = splitted[0].matches(of: /Register (\w+): (\d+)/)
        var register: [String: Int] = [:]
        for output in registers.map(\.output) {
            let (_, key, value) = output
            register[String(key)] = Int(value)!
        }
        print(register)

        let program = splitted[1]
            .dropFirst("Program: ".count)
            .split(separator: ",")
            .compactMap { Int($0) }

        print(program)

        return (register, program)
    }

    private func execute(
        program: [Int],
        register: inout [String: UInt64],
        pointer: inout Int,
        output: (UInt64) -> Void = { _ in }
    ) -> [UInt64] {
        var outputs: [UInt64] = []

        func r(_ key: String) -> UInt64 {
            register[key]!
        }

        func literal(_ value: Int) -> UInt64 {
            return UInt64(value)
        }

        func combo(_ value: Int) -> UInt64 {
            switch value {
            case 0...3: UInt64(value)
            case 4: register["A"]!
            case 5: register["B"]!
            case 6: register["C"]!
            case 7: fatalError("Reserved")
            default: fatalError("Unexpected operand: \(value)")
            }
        }

        while pointer < program.count {
            let opcode = program[pointer]
            // print("Executing opcode \(opcode) at pointer \(pointer)")
            switch opcode {
            case 0:  // adv
                let combo = combo(program[pointer + 1])
                register["A"] = r("A") >> combo
                pointer += 2
            case 1:  // bxl
                let literal = literal(program[pointer + 1])
                register["B"] = r("B") ^ literal
                pointer += 2
            case 2:  // bst
                let combo = combo(program[pointer + 1])
                register["B"] = combo & 7  // combo % 8 == combo % (2^3)
                pointer += 2
            case 3:  // jnz
                if r("A") == 0 {
                    pointer += 2
                } else {
                    let literal = literal(program[pointer + 1])
                    pointer = Int(literal)
                }
            case 4:  // bxc
                register["B"] = r("B") ^ r("C")
                pointer += 2
            case 5:  // out
                let combo = combo(program[pointer + 1])
                outputs.append(combo & 7)
                output(combo & 7)  // output(combo % 8)
                pointer += 2
            case 6:  // bdv
                let combo = combo(program[pointer + 1])
                register["B"] = r("A") >> combo
                pointer += 2
            case 7:  // cdv
                let combo = combo(program[pointer + 1])
                register["C"] = r("A") >> combo
                pointer += 2
            default:
                fatalError("Unrecognised opcode: \(opcode)")
            }
            print(
                ["A", "B", "C"].map {
                    String(r($0), radix: 8)
                }, (opcode, pointer), outputs, opcode == 5 ? "!" : "")
        }
        return outputs
    }

    private func test() {
        let tests: [([String: UInt64], [Int])] = [
            (register: ["A": 0, "B": 0, "C": 9], program: [2, 6]),
            (register: ["A": 10, "B": 0, "C": 0], program: [5, 0, 5, 1, 5, 4]),
            (register: ["A": 2024, "B": 0, "C": 0], program: [0, 1, 5, 4, 3, 0]),
            (register: ["A": 0, "B": 29, "C": 0], program: [1, 7]),
            (register: ["A": 0, "B": 2024, "C": 43690], program: [4, 0]),
            (register: ["A": 117440, "B": 0, "C": 0], program: [0, 3, 5, 4, 3, 0]),
        ]
        for test in tests {
            var (register, program) = test
            var pointer = 0
            var outputs: [UInt64] = []
            self.execute(
                program: program,
                register: &register,
                pointer: &pointer,
                output: { outputs.append($0) }
            )
            print(register)
            print(outputs)
        }
    }

    func part1() -> String {
        return ""
        // var register: [String: UInt64] = ["A": 41_644_071, "B": 0, "C": 0]
        // let program = [
        //     2, 4,  // bst A  (B = A % 8)   B = A & 0111
        //     1, 2,  // bxl 2  (B = B ^ 2)   B ^ 0010
        //     7, 5,  // cdv B  (C = A >> B)
        //     1, 7,  // bxl 7  (B = B ^ 7)   B ^ 1110
        //     4, 4,  // bxc    (B = B ^ C)
        //     0, 3,  // adv 3  (A = A >> 3)
        //     5, 5,  // out B  (outputs B % 8)  output last 3 bits
        //     3, 0,  // jnz 0  (goto A == 0 ? end : start)
        // ]
        // var pointer = 0
        // var outputs: [UInt64] = []
        // print("REGISTER:", register)
        // print("PROGRAM:", program.map { String($0) }.joined(separator: ","))
        // self.execute(
        //     program: program,
        //     register: &register,
        //     pointer: &pointer,
        //     output: { outputs.append($0) }
        // )
        // let result = outputs.map { String($0) }.joined(separator: ",")
        // return result
    }

    // REQUIREMENTS
    // - Always outputs last 3 bits of B
    // - A's 3 least-significant bits are truncated every '0' (adv)
    // - Need to output 16 numbers, therefore we need at least 2^44 bits in A
    // - First, B needs to be ____010 == 2
    func part2() -> String {
        var register: [String: UInt64] = ["A": 41_644_071, "B": 0, "C": 0]
        let program = [
            2, 4,  // bst A  (B = A % 8)   B = A & 0111
            1, 2,  // bxl 2  (B = B ^ 2)   B ^ 0010
            7, 5,  // cdv B  (C = A >> B)
            1, 7,  // bxl 7  (B = B ^ 7)   B ^ 1110
            4, 4,  // bxc    (B = B ^ C)
            0, 3,  // adv 3  (A = A >> 3)
            5, 5,  // out B  (outputs B % 8)  output last 3 bits
            3, 0,  // jnz 0  (goto A == 0 ? end : start)
        ]
        print("REGISTER:", register)
        print("PROGRAM:", program.map { String($0) }.joined(separator: ","))

        let x = UInt64(2 << 10 + 312)  // UInt64(2 << 46)  // 2 << 44
        for i in x..<(x + 1) {
            if i % 10_000_000 == 0 { print("Testing \(i)") }
            register["A"] = i
            var pointer = 0
            // var outputs: [UInt64] = []
            let outputs = self.execute(
                program: program,
                register: &register,
                pointer: &pointer
                    // output: { outputs.append($0) }
            )
            print(outputs)
            print(outputs.count)
            print(program.count)
        }
        return ""
    }
}
