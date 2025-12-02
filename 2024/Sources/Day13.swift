import Foundation

struct Day13: AdventDay {
    var data: String

    private let example: String = """
        Button A: X+94, Y+34
        Button B: X+22, Y+67
        Prize: X=8400, Y=5400

        Button A: X+26, Y+66
        Button B: X+67, Y+21
        Prize: X=12748, Y=12176

        Button A: X+17, Y+86
        Button B: X+84, Y+37
        Prize: X=7870, Y=6450

        Button A: X+69, Y+23
        Button B: X+27, Y+71
        Prize: X=18641, Y=10279
        """

    private let epsilon: Double = 1e-3

    init(data: String) {
        self.data = data
    }

    private func assert2by2(_ mat: [[Double]]) {
        let W = mat[0].count
        let H = mat.count
        assert(W == 2 && H == 2, "only supports 2 by 2 matrices")
    }

    private func det(_ mat: [[Double]]) -> Double {
        self.assert2by2(mat)
        let (a, b, c, d) = (mat[0][0], mat[0][1], mat[1][0], mat[1][1])
        return (a * d) - (b * c)
    }

    private func inv(_ mat: [[Double]]) -> [[Double]]? {
        self.assert2by2(mat)
        let det = self.det(mat)
        if det == 0 { return nil }
        let (a, b, c, d) = (mat[0][0], mat[0][1], mat[1][0], mat[1][1])
        return [
            [d / det, -b / det],
            [-c / det, a / det],
        ]
    }

    private func mul(_ mat: [[Double]], _ vec: [Double]) -> [Double] {
        let (a, b, c, d) = (mat[0][0], mat[0][1], mat[1][0], mat[1][1])
        let (x, y) = (vec[0], vec[1])
        return [
            a * x + b * y,
            c * x + d * y,
        ]
    }

    // Solves the matrix equation Ax = B, returning x
    private func solve(A: [[Double]], B: [Double]) -> [Double]? {
        guard let invA = self.inv(A) else { return nil }
        return self.mul(invA, B)
    }

    func parse(_ data: String) -> [(A: [[Double]], B: [Double])] {
        let chunks = data.split(separator: "\n\n")
        let results = chunks.map { chunk in
            let rows = chunk.split(separator: "\n")
            let matchesA = rows[0]
                .matches(of: /\+(\d+)/)
                .map { Double($0.output.1)! }
            let matchesB = rows[1]
                .matches(of: /\+(\d+)/)
                .map { Double($0.output.1)! }
            let matchesP = rows[2]
                .matches(of: /=(\d+)/)
                .map { Double($0.output.1)! }
            let (Ax, Ay) = (matchesA[0], matchesA[1])
            let (Bx, By) = (matchesB[0], matchesB[1])
            let (Px, Py) = (matchesP[0], matchesP[1])
            let A = [[Ax, Bx], [Ay, By]]
            let B = [Px, Py]
            return (A, B)
        }
        return results
    }

    func part1() -> Int {
        let machines = self.parse(self.data)
        var result: Double = 0
        for machine in machines {
            let (A, B) = machine
            if let solution = self.solve(A: A, B: B) {
                let (countA, countB) = (solution[0], solution[1])
                if abs(countA - round(countA)) <= epsilon
                    && abs(countB - round(countB)) <= epsilon
                {
                    result += (3 * countA + 1 * countB)
                }
            }
        }
        return Int(result)
    }

    // Had to play around (loosen) the tolerances a bit but we got there
    func part2() -> Int {
        let machines = self.parse(self.data)
        var result: Double = 0
        for machine in machines {
            let (A, B) = machine
            if let solution = self.solve(A: A, B: B.map { $0 + 10_000_000_000_000 }) {
                let (countA, countB) = (solution[0], solution[1])
                if abs(countA - round(countA)) <= epsilon
                    && abs(countB - round(countB)) <= epsilon
                {
                    result += (3 * countA + 1 * countB)
                }
            }
        }
        return Int(result)
    }
}

// 94 * Na + 22 * Nb = 8400
// 34 * Na + 67 * Nb = 5400

// 94 22 Na = 8400
// 34 67 Nb   5400

// Na = inv(94 22 * 8400
// Nb       34 67)  5400

// notes
// - look up cramer's rule
// - methods matter! solving for x in Ax + B as A^-1 * B is correct, but has
// precision issues since i need to cast as a double when dividing by the
// inverse. if i calculate the solution directly without casting, i wouldn't
// have needed to juggle the epsilon value (i.e. the tolerance) to get the
// correct answer...
