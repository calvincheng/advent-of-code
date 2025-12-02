import Foundation

struct Day04: AdventDay {
    var data: String

    private let example = """
        MMMSXXMASM
        MSAMXMSMSA
        AMXSXMAAMM
        MSAMASMSMX
        XMASAMXAMM
        XXAMMXXAMA
        SMSMSASXSS
        SAXAMASAAA
        MAMMMXMMMM
        MXMXAXMASX
        """

    init(data: String) {
        self.data = data
    }

    private enum Direction {
        case up, down, left, right
        case upLeft, upRight, downLeft, downRight
    }

    private func gridify(data: String) -> [[String]] {
        return
            data
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { Array($0).map { String($0) }.filter { !$0.isEmpty } }
    }

    private func getIndices(
        for direction: Direction,
        at ij: (Int, Int)
    ) -> [(Int, Int)] {
        let (i, j) = ij
        return switch direction {
        case .up: (j - 3...j).reversed().map { (i, $0) }
        case .down: (j..<j + 4).map { (i, $0) }
        case .left: (i - 3...i).reversed().map { ($0, j) }
        case .right: (i..<i + 4).map { ($0, j) }
        case .upLeft: zip((i - 3...i).reversed(), (j - 3...j).reversed()).map { ($0, $1) }
        case .upRight: zip((i..<i + 4), (j - 3...j).reversed()).map { ($0, $1) }
        case .downLeft: zip((i - 3...i).reversed(), (j..<j + 4)).map { ($0, $1) }
        case .downRight: zip((i..<i + 4), (j..<j + 4)).map { ($0, $1) }
        }
    }

    func part1() -> Int {
        // Strategy – everytime you encounter an X, check all valid directions to
        // see if there's an XMAS there.
        // Valid directions:
        //   - orthogonals (up/down/left/right)
        //   - diagonals (NE/SE/SW/NW)

        let grid = self.gridify(data: self.data)
        let numRows = grid.count
        let numCols = grid[0].count
        var result: Int = 0

        for j in 0..<numRows {
            for i in 0..<numCols {
                guard grid[j][i] == "X" else { continue }
                let canUp = j - 3 >= 0
                let canDown = j + 3 < numRows
                let canRight = i + 3 < numCols
                let canLeft = i - 3 >= 0
                let tasks: [(Direction, Bool)] = [
                    (.right, canRight),
                    (.left, canLeft),
                    (.up, canUp),
                    (.down, canDown),
                    (.upLeft, canUp && canLeft),
                    (.upRight, canUp && canRight),
                    (.downLeft, canDown && canLeft),
                    (.downRight, canDown && canRight),
                ]
                for (direction, isPossible) in tasks {
                    guard isPossible else { continue }
                    let indices = self.getIndices(for: direction, at: (i, j))
                    let str = indices.map { i, j in grid[j][i] }.joined()
                    if str == "XMAS" { result += 1 }
                }
            }
        }

        return result
    }

    func part2() -> Int {
        let grid = self.gridify(data: self.data)
        let numRows = grid.count
        let numCols = grid[0].count
        var result: Int = 0
        for j in 1..<numRows - 1 {
            for i in 1..<numCols - 1 {
                guard grid[j][i] == "A" else { continue }
                let indices1 = zip((i - 1...i + 1), (j - 1...j + 1)).map { ($0, $1) }
                let indices2 = zip((i - 1...i + 1), (j - 1...j + 1).reversed()).map { ($0, $1) }
                let str1 = indices1.map { i, j in grid[j][i] }.joined()
                let str2 = indices2.map { i, j in grid[j][i] }.joined()
                if [str1, str2].allSatisfy({ $0 == "MAS" || $0 == "SAM" }) {
                    result += 1
                }
            }
        }
        return result
    }

}
